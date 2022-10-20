#include "RemoteIDManager.h"

#include <QDebug>

QGC_LOGGING_CATEGORY(RemoteIDManagerLog, "RemoteIDManagerLog")

RemoteIDManager::RemoteIDManager(Vehicle* vehicle)
    : QObject           (vehicle)
    , _uasIDInitialized (false)
    , _uasIDReceived    (false)
{

}

void RemoteIDManager::mavlinkMessageReceived(mavlink_message_t& message )
{
    switch (message.msgid)
    {
    case MAVLINK_MSG_ID_OPEN_DRONE_ID_BASIC_ID :
        _handleBasicID(message);
        break;
    default:
        break;
    }
}

void RemoteIDManager::_handleBasicID(mavlink_message_t& message)
{
    mavlink_open_drone_id_basic_id_t basicID;

    mavlink_msg_open_drone_id_basic_id_decode(&message, &basicID);

    if (!basicID.uas_id) {
        _uasIDReceived = false;
        qCDebug(RemoteIDManagerLog) << "Basic ID received from autopilot is empty we need to send it ourselfs.";
    } else {
        if (!_uasIDReceived) {
            _uasIDReceived = true;
        }
    }

    if (!_uasIDInitialized) {
        _uasIDInitialized = true;
    }
}
