/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "RemoteIDManager.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "RemoteIDSettings.h"
#include "QGCQGeoCoordinate.h"
#include "PositionManager.h"

#include <QDebug>

QGC_LOGGING_CATEGORY(RemoteIDManagerLog, "RemoteIDManagerLog")

#define ID_OR_MAC_UNKNOWN 0
#define AREA_COUNT 1
#define AREA_RADIUS 0
#define SENDING_RATE_MSEC 1000
#define ALLOWED_GPS_DELAY 1000
#define HEARTBEAT_TIMEOUT 5000

RemoteIDManager::RemoteIDManager(Vehicle* vehicle)
    : QObject               (vehicle)
    , _mavlink              (nullptr)
    , _vehicle              (vehicle)
    , _settings             (nullptr)
    , _armStatusGood        (false)
    , _commsGood            (false)
    , _gcsGPSGood           (false)
    , _basicIDGood          (false)
    , _operatorIDGood       (false)
    , _emergencyDeclared    (false)
    , _targetSystem         (0) // By default 0 means broadcast
    , _targetComponent      (0) // By default 0 means broadcast
{
    _mavlink = qgcApp()->toolbox()->mavlinkProtocol();
    _settings = qgcApp()->toolbox()->settingsManager()->remoteIDSettings();
    _positionManager = qgcApp()->toolbox()->qgcPositionManager();

    // Timer to track a healthy RID device. When expired we let the operator know
    _heartbeatTimeoutTimer.setSingleShot(true);
    _heartbeatTimeoutTimer.setInterval(HEARTBEAT_TIMEOUT);
    connect(&_heartbeatTimeoutTimer, &QTimer::timeout, this, &RemoteIDManager::_heartbeatTimeout);

    // Timer to send messages at a constant rate
    _sendMessagesTimer.setInterval(SENDING_RATE_MSEC);
    connect(&_sendMessagesTimer, &QTimer::timeout, this, &RemoteIDManager::_sendMessages);

    // GCS GPS position updates to track the health of the GPS data
    connect(_positionManager, &QGCPositionManager::positionInfoUpdated, this, &RemoteIDManager::_updateLastGCSPositionInfo);

    // Set first position for the live gps
    _setInitialPosition();
}

void RemoteIDManager::mavlinkMessageReceived(mavlink_message_t& message )
{
    switch (message.msgid)
    {
    case MAVLINK_MSG_ID_HEARTBEAT:
        _handleHeartBeat(message);
        break;
    case MAVLINK_MSG_ID_OPEN_DRONE_ID_ARM_STATUS: 
        _handleArmStatus(message);
    default:
        break;
    }
}

void RemoteIDManager::_handleHeartBeat(mavlink_message_t& message)
{
    // We only care about heartbeat if its from our vehicle sysID and an ODID device:
    // MAV_COMP_ID_ODID_TXRX_1
    // MAV_COMP_ID_ODID_TXRX_2
    // MAV_COMP_ID_ODID_TXRX_3
    if (message.compid < MAV_COMP_ID_ODID_TXRX_1 || message.compid > MAV_COMP_ID_ODID_TXRX_3 || _vehicle->id() != message.sysid) {
        return;
    }

    // We set the targetsystem
    if (_targetSystem != message.sysid) {
        _targetSystem = message.sysid;
        qCDebug(RemoteIDManagerLog) << "We subscribe to the ODID coming from system " << _targetSystem;
    }

    if (!_commsGood) {
        _commsGood = true;
        _sendMessagesTimer.start(); // We start sending our own messages
        checkBasicID(); // We check if basicID is good to send 
        checkOperatorID(); // We check if OperatorID is good in case we want to send it from start because of the settings
        emit commsGoodChanged();
        qCDebug(RemoteIDManagerLog) << "We are receiving heartbeat from RID device.";
    }

    // We restart the timeout timer
    _heartbeatTimeoutTimer.start();

}

// This slot will be called if we stop receiving heartbeats for more than HEARTBEAT_TIMEOUT seconds
void RemoteIDManager::_heartbeatTimeout()
{
    _commsGood = false;
    _sendMessagesTimer.stop(); // We stop sending messages if the communication with the RID device is down
    emit commsGoodChanged();
    qCDebug(RemoteIDManagerLog) << "We stopped receiving heartbeat from RID device.";
}

// Parsing of the ARM_STATUS message comming from the RID device
void RemoteIDManager::_handleArmStatus(mavlink_message_t& message)
{
    mavlink_open_drone_id_arm_status_t armStatus;

    mavlink_msg_open_drone_id_arm_status_decode(&message, &armStatus);

    if (armStatus.status == ArmStatus::GoodToArm && !_armStatusGood) {
        _armStatusGood = true;
        emit armStatusGoodChanged();
        qCDebug(RemoteIDManagerLog) << "Arm status GOOD TO ARM.";
    }

    if (armStatus.status == ArmStatus::ArmFailedGeneric) {
        _armStatusGood = false;
        _armStatusError = QString::fromLocal8Bit(armStatus.error);
        emit armStatusGoodChanged();
        emit armStatusErrorChanged();
        qCDebug(RemoteIDManagerLog) << "Arm status error:" << _armStatusError;
    }
}

// Function that sends messages periodically
void RemoteIDManager::_sendMessages()
{
    //We only send RemoteID messages if we have it enabled in the General settings
    if (!_settings->enable()->rawValue().toBool()) {
        return;
    }
    
    // We always try to send System
    _sendSystem();
    
    // We always send Basic ID, but only send them if the information is correct
    if (_basicIDGood) {
        _sendBasicID();
    }
    
    // We only send selfID if the pilot wants it or in case of a declared emergency
    if (_settings->sendSelfID()->rawValue().toBool() || _emergencyDeclared) {
        _sendSelfIDMsg();
    }

    // We only send the OperatorID if the pilot wants it or if the region we have set is europe. 
    // To be able to send it, it needs to be filled correclty
    if ((_settings->sendOperatorID()->rawValue().toBool() || (_settings->region()->rawValue().toInt() == Region::EU)) && _operatorIDGood) {
        _sendOperatorID();
    }

}

void RemoteIDManager::_sendSelfIDMsg()
{
    WeakLinkInterfacePtr weakLink = _vehicle->vehicleLinkManager()->primaryLink();

    if (!weakLink.expired()) {
        mavlink_message_t       msg;
        SharedLinkInterfacePtr  sharedLink = weakLink.lock();

        mavlink_msg_open_drone_id_self_id_pack_chan(_mavlink->getSystemId(),
                                                    _mavlink->getComponentId(),
                                                    sharedLink->mavlinkChannel(),
                                                    &msg,
                                                    _targetSystem,
                                                    _targetComponent,
                                                    ID_OR_MAC_UNKNOWN,
                                                    _emergencyDeclared ? 1 : _settings->selfIDType()->rawValue().toInt(), // If emergency is delcared we send directly a 1 (1 = EMERGENCY)
                                                    _getSelfIDDescription());// Depending on the type of SelfID we send a different description
        _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg);
    }
}

// We need to return the correct description for the self ID type we have selected
const char* RemoteIDManager::_getSelfIDDescription()
{
    QByteArray bytesFree = (_settings->selfIDFree()->rawValue().toString()).toLocal8Bit();
    QByteArray bytesEmergency = (_settings->selfIDEmergency()->rawValue().toString()).toLocal8Bit();
    QByteArray bytesExtended = (_settings->selfIDExtended()->rawValue().toString()).toLocal8Bit();

    const char* descriptionToSend;

    if (_emergencyDeclared) {
        // If emergency is declared we dont care about the settings and we send emergency directly
        descriptionToSend = bytesEmergency.data();
    } else {
        switch (_settings->selfIDType()->rawValue().toInt()) {
            case 0:
                descriptionToSend = bytesFree.data();
                break;
            case 1:
                descriptionToSend = bytesEmergency.data();
                break;
            case 2:
                descriptionToSend = bytesExtended.data();
                break;
            default:
                descriptionToSend = bytesEmergency.data();
        }
    }
    
    return descriptionToSend;
}

void RemoteIDManager::_sendOperatorID()
{
    WeakLinkInterfacePtr weakLink = _vehicle->vehicleLinkManager()->primaryLink();

    if (!weakLink.expired()) {
        mavlink_message_t       msg;
        SharedLinkInterfacePtr  sharedLink = weakLink.lock();

        mavlink_msg_open_drone_id_self_id_pack_chan(_mavlink->getSystemId(),
                                                    _mavlink->getComponentId(),
                                                    sharedLink->mavlinkChannel(),
                                                    &msg,
                                                    _targetSystem,
                                                    _targetComponent,
                                                    ID_OR_MAC_UNKNOWN,
                                                    _settings->operatorIDType()->rawValue().toInt(),
                                                    _getOperatorIDDescription());// Depending on the type of OperatorID we send a different description
        _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg);
    }
}

// We need to return the correct description for the OperatorID type we have selected
const char* RemoteIDManager::_getOperatorIDDescription()
{
    QByteArray bytesOperatorID = (_settings->operatorID()->rawValue().toString()).toLocal8Bit();

    const char* descriptionToSend = bytesOperatorID.data();

    return descriptionToSend;
}

void RemoteIDManager::_sendSystem()
{
    WeakLinkInterfacePtr weakLink = _vehicle->vehicleLinkManager()->primaryLink();

    QGeoCoordinate      gcsPosition;
    QGeoPositionInfo    geoPositionInfo;
    // Location types:
    // 0 -> TAKEOFF (not supported yet)
    // 1 -> LIVE GNNS 
    // 2 -> FIXED
    if (_settings->locationType()->rawValue().toUInt() == LocationTypes::FIXED) {
        // For FIXED location, we first check that the values are valid. Then we populate our position
        if (_settings->latitudeFixed()->rawValue().toFloat() >= -90 && _settings->latitudeFixed()->rawValue().toFloat() <= 90 && _settings->longitudeFixed()->rawValue().toFloat() >= -180 && _settings->longitudeFixed()->rawValue().toFloat() <= 180) {
            gcsPosition = QGeoCoordinate(_settings->latitudeFixed()->rawValue().toFloat(), _settings->longitudeFixed()->rawValue().toFloat(), _settings->altitudeFixed()->rawValue().toFloat());
            geoPositionInfo = QGeoPositionInfo(gcsPosition, QDateTime::currentDateTime().currentDateTimeUtc());
            if (!_gcsGPSGood) {
                _gcsGPSGood = true;
                emit gcsGPSGoodChanged();
            }
        } else {
            gcsPosition = QGeoCoordinate(0,0,0);
            geoPositionInfo = QGeoPositionInfo(gcsPosition, QDateTime::currentDateTime().currentDateTimeUtc());
            if (_gcsGPSGood) {
                _gcsGPSGood = false;
                emit gcsGPSGoodChanged();
                qCDebug(RemoteIDManagerLog) << "The provided coordinates for FIXED position are invalid.";
            }
        }
    } else {
        // For Live GNSS we take QGC GPS data
        gcsPosition = _positionManager->gcsPosition();
        geoPositionInfo = _positionManager->geoPositionInfo();

        // GPS position needs to be valid before checking other stuff
        if (geoPositionInfo.isValid()) {
            // If we dont have altitude for FAA then the GPS data is no good
            if ((_settings->region()->rawValue().toInt() == Region::FAA) && !(gcsPosition.altitude() >= 0) && _gcsGPSGood) {
                _gcsGPSGood = false;
                emit gcsGPSGoodChanged();
                qCDebug(RemoteIDManagerLog) << "GCS GPS data error (no altitude): Altitude data is mandatory for GCS GPS data in FAA regions.";
                return;
            }

            // If the GPS data is older than ALLOWED_GPS_DELAY we cannot use this data 
            if (_lastGeoPositionTimeStamp.msecsTo(QDateTime::currentDateTime().currentDateTimeUtc()) > ALLOWED_GPS_DELAY) {
                if (_gcsGPSGood) {
                    _gcsGPSGood = false;
                    emit gcsGPSGoodChanged();
                    qCDebug(RemoteIDManagerLog) << "GCS GPS data is too old.";
                }
            } else {
                if (!_gcsGPSGood) {
                    _gcsGPSGood = true;
                    emit gcsGPSGoodChanged();
                }
            }
        } else {
            _gcsGPSGood = false;
            emit gcsGPSGoodChanged();
            qCDebug(RemoteIDManagerLog) << "GCS GPS data is not valid.";
        }
        
    }

    if (!_gcsGPSGood) {
        return;
    }

    if (!weakLink.expired()) {
        mavlink_message_t       msg;
        SharedLinkInterfacePtr  sharedLink = weakLink.lock();

        mavlink_msg_open_drone_id_system_pack_chan(_mavlink->getSystemId(),
                                                    _mavlink->getComponentId(),
                                                    sharedLink->mavlinkChannel(),
                                                    &msg,
                                                    _targetSystem,
                                                    _targetComponent,
                                                    ID_OR_MAC_UNKNOWN,
                                                    _settings->locationType()->rawValue().toUInt(),
                                                    _settings->classificationType()->rawValue().toUInt(),
                                                    geoPositionInfo.isValid() ? gcsPosition.latitude() : 0, // If position not valid, send a 0
                                                    geoPositionInfo.isValid() ? gcsPosition.longitude() : 0, // If position not valid, send a 0
                                                    AREA_COUNT,
                                                    AREA_RADIUS,
                                                    -1000.0f,
                                                    -1000.0f,
                                                    _settings->categoryEU()->rawValue().toUInt(),
                                                    _settings->classEU()->rawValue().toUInt(),
                                                    geoPositionInfo.isValid() ? gcsPosition.altitude() : 0, // If position not valid, send a 0
                                                    _timestamp2019()),// Time stamp needs to be since 00:00:00 1/1/2019
        _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg);
    }
}

// Returns seconds elapsed since 00:00:00 1/1/2019
uint32_t RemoteIDManager::_timestamp2019()
{
    uint32_t secsSinceEpoch2019 = 1546300800;// Secs elapsed since epoch to 1-1-2019

    return ((QDateTime::currentDateTime().currentSecsSinceEpoch()) - secsSinceEpoch2019);
}

// Function to initialize first gcs position in case it exists
void RemoteIDManager::_setInitialPosition()
{
    QGeoCoordinate gcsPosition = _positionManager->gcsPosition();
    QGeoPositionInfo geoPositionInfo = _positionManager->geoPositionInfo();

    if (geoPositionInfo.isValid()) {
        _updateLastGCSPositionInfo(geoPositionInfo);
    }
}

void RemoteIDManager::_sendBasicID()
{
    WeakLinkInterfacePtr weakLink = _vehicle->vehicleLinkManager()->primaryLink();

    QString uasIDTemp = _settings->uasID()->rawValue().toString();
    QByteArray ba = uasIDTemp.toLocal8Bit();

    if (!weakLink.expired()) {
        mavlink_message_t       msg;
        SharedLinkInterfacePtr  sharedLink = weakLink.lock();

        mavlink_msg_open_drone_id_basic_id_pack_chan(_mavlink->getSystemId(),
                                                    _mavlink->getComponentId(),
                                                    sharedLink->mavlinkChannel(),
                                                    &msg,
                                                    _targetSystem,
                                                    _targetComponent,
                                                    ID_OR_MAC_UNKNOWN,
                                                    _settings->uasIDType()->rawValue().toUInt(),
                                                    _settings->uasType()->rawValue().toUInt(),
                                                    reinterpret_cast<const unsigned char*>(ba.constData())),

        _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg);
    }
}

void RemoteIDManager::checkBasicID()
{
    QString uasID = _settings->uasID()->rawValue().toString();

    if (!uasID.isEmpty() && (_settings->uasIDType()->rawValue().toInt() >= 0) && (_settings->uasType()->rawValue().toInt() >= 0)) {
        _basicIDGood = true;
    } else {
        _basicIDGood = false;
    }
    emit basicIDGoodChanged();
}

void RemoteIDManager::checkOperatorID()
{
    QString operatorID = _settings->operatorID()->rawValue().toString();

    if (!operatorID.isEmpty() && (_settings->operatorIDType()->rawValue().toInt() >= 0)) {
        _operatorIDGood = true;
    } else {
        _operatorIDGood = false;
    }
    emit operatorIDGoodChanged();
}

void RemoteIDManager::declareEmergency()
{
    if (!_emergencyDeclared) {
        _emergencyDeclared = true;
        emit emergencyDeclaredChanged();
        qCDebug(RemoteIDManagerLog) << "Emergency declared.";
    }
}

void RemoteIDManager::_updateLastGCSPositionInfo(QGeoPositionInfo update)
{
    if (update.isValid()) {
        _lastGeoPositionTimeStamp = update.timestamp().toUTC();
    }
}