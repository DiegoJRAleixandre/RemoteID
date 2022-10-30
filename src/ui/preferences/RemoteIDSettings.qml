/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtQuick.Layouts          1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0

Rectangle {
    id:             remoteIDRoot
    color:          qgcPal.window
    anchors.fill:   parent

    // Visual properties
    property real _margins:             ScreenTools.defaultFontPixelWidth
    property real _labelWidth:          ScreenTools.defaultFontPixelWidth * 28
    property real _valueWidth:          ScreenTools.defaultFontPixelWidth * 24
    property real _columnSpacing:       ScreenTools.defaultFontPixelHeight * 0.25
    property real _comboFieldWidth:     ScreenTools.defaultFontPixelWidth * 30
    property real _valueFieldWidth:     ScreenTools.defaultFontPixelWidth * 10
    property int  _borderWidth:         3
    // Flags visual properties
    property real   flagsWidth:         ScreenTools.defaultFontPixelWidth * 15
    property real   flagsHeight:        ScreenTools.defaultFontPixelWidth * 7
    property int    radiusFlags:        5

    // General properties
    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property int  _regionOperation:     QGroundControl.settingsManager.remoteIDSettings.region.value
    property int  _locationType:        QGroundControl.settingsManager.remoteIDSettings.locationType.value
    property int  _classificationType:  QGroundControl.settingsManager.remoteIDSettings.classificationType.value

    enum RegionOperation {
        FAA,
        EU
    }

    enum LocationType {
        TAKEOFF,
        LIVE,
        FIXED
    }

    enum ClassificationType {
        UNDEFINED,
        EU
    }

    // GPS properties
    property var    gcsPosition:        QGroundControl.qgcPositionManger.gcsPosition
    property real   gcsHeading:         QGroundControl.qgcPositionManger.gcsHeading
    property real   gcsHDOP:            QGroundControl.qgcPositionManger.gcsPositionHorizontalAccuracy
    property string gpsDisabled:        "Disabled"
    property string gpsUdpPort:         "UDP Port"

    QGCPalette { id: qgcPal }

    // Function to get the corresponding Self ID label depending on the Self ID Type selected
    function getSelfIdLabelText() {
        switch (selfIDComboBox.currentIndex) {
            case 0:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDFree.shortDescription
                break
            case 1:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDEmergency.shortDescription
                break
            case 2:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDExtended.shortDescription
                break
            default:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDFree.shortDescription
        }
    }

    // Function to get the corresponding Self ID fact depending on the Self ID Type selected
    function getSelfIDFact() {
        switch (selfIDComboBox.currentIndex) {
            case 0:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDFree
                break
            case 1:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDEmergency
                break
            case 2:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDExtended
                break
            default:
                return QGroundControl.settingsManager.remoteIDSettings.selfIDFree
        }
    }

    // Function to move flickable to desire position
    function getFlickableToPosition(y) {
        flicakbleRID.contentY = y
    }

    Item {
        id:                             flagsItem
        anchors.top:                    parent.top
        anchors.horizontalCenter:       parent.horizontalCenter
        anchors.horizontalCenterOffset: ScreenTools.defaultFontPixelWidth // Need this to account for the slight offset in the flickable
        width:                          flicakbleRID.innerWidth
        height:                         flagsColumn.height

        ColumnLayout {
            id:                         flagsColumn
            anchors.horizontalCenter:   parent.horizontalCenter
            spacing:                    _margins

            // ---------------------------------------- STATUS -----------------------------------------
            // Status flags. Visual representation for the state of all necesary information for remoteID
            // to work propely.
            QGCLabel {
                id:                 statusLabel
                text:               qsTr("Status")
                Layout.alignment:   Qt.AlignHCenter
                font.pointSize:     ScreenTools.mediumFontPointSize
                visible:            _activeVehicle
            }

            Rectangle {
                id:                     flagsRectangle
                Layout.preferredHeight: statusGrid.height + (_margins * 2)
                Layout.preferredWidth:  flagsItem.width
                color:                  qgcPal.windowShade
                visible:                _activeVehicle
                Layout.fillWidth:       true

                GridLayout {
                    id:                         statusGrid
                    anchors.margins:            _margins
                    anchors.top:                parent.top
                    anchors.horizontalCenter:   parent.horizontalCenter
                    columns:                    2
                    rowSpacing:                 _margins * 3
                    columnSpacing:              _margins * 2

                    Rectangle {
                        id:                     armFlag
                        Layout.preferredHeight: flagsHeight
                        Layout.preferredWidth:  flagsWidth
                        color:                  _activeVehicle ? (_activeVehicle.remoteIDManager.armStatusGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                        radius:                 radiusFlags

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("ARM STATUS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                        }
                    }

                    Rectangle {
                        id:                     commsFlag
                        Layout.preferredHeight: flagsHeight
                        Layout.preferredWidth:  flagsWidth
                        color:                  _activeVehicle ? (_activeVehicle.remoteIDManager.commsGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                        radius:                 radiusFlags

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("RID COMMS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                        }
                    }
                    
                    Rectangle {
                        id:                     gpsFlag
                        Layout.preferredHeight: flagsHeight
                        Layout.preferredWidth:  flagsWidth
                        color:                  _activeVehicle ? (_activeVehicle.remoteIDManager.gcsGPSGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                        radius:                 radiusFlags

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("GCS GPS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                        }

                        // On clikced we go to the corresponding settings
                        MouseArea {
                            anchors.fill:   parent
                            onClicked:      getFlickableToPosition(flicakbleRID.gpsY)
                        }
                    }

                    Rectangle {
                        id:                     uasIDFlag
                        Layout.preferredHeight: flagsHeight
                        Layout.preferredWidth:  flagsWidth
                        color:                  _activeVehicle ? (_activeVehicle.remoteIDManager.basicIDGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                        radius:                 radiusFlags

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("UAS ID")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                        }

                        // On clikced we go to the corresponding settings
                        MouseArea {
                            anchors.fill:   parent
                            onClicked:      getFlickableToPosition(flicakbleRID.uasIDY)
                        }
                    }

                    Rectangle {
                        id:                     operaotrIDFlag
                        Layout.preferredHeight: flagsHeight
                        Layout.preferredWidth:  flagsWidth
                        color:                  _activeVehicle ? (_activeVehicle.remoteIDManager.operatorIDGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                        radius:                 radiusFlags
                        visible:                _activeVehicle ? (QGroundControl.settingsManager.remoteIDSettings.sendOperatorID.value || _regionOperation == RemoteIDSettings.RegionOperation.EU) : false

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("OPERATOR ID")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                        }

                        // On clikced we go to the corresponding settings
                        MouseArea {
                            anchors.fill:   parent
                            onClicked:      getFlickableToPosition(flicakbleRID.operatorIDY)
                        }
                    }
                }
            }
        }
    }

    QGCFlickable {
        id:                 flicakbleRID
        clip:               true
        anchors.top:        flagsItem.visible ? flagsItem.bottom : parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.bottom:     parent.bottom
        anchors.margins:    ScreenTools.defaultFontPixelWidth
        contentHeight:      outerItem.height
        contentWidth:       outerItem.width
        flickableDirection: Flickable.VerticalFlick

        property var innerWidth:   settingsItem.width

        // Properties to position flickable
        property var gpsY:          gpsLabel.y
        property var uasIDY:        uasIDLabel.y
        property var operatorIDY:   operatorIDLabel.y

        Item {
            id:     outerItem
            width:  Math.max(remoteIDRoot.width, settingsItem.width)
            height: settingsItem.height

            ColumnLayout {
                id:                         settingsItem
                anchors.horizontalCenter:   parent.horizontalCenter
                spacing:                    _margins

                // ---------------------------------------- REGION -----------------------------------------
                // Region of operation to accomodate for different requirements
                QGCLabel {
                    id:                 regionLabel
                    text:               qsTr("Region")
                    Layout.alignment:   Qt.AlignHCenter
                    font.pointSize:     ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    id:                     regionRectangle
                    Layout.preferredHeight: regionGrid.height + (_margins * 2)
                    Layout.preferredWidth:  regionGrid.width + (_margins * 2)
                    color:                  qgcPal.windowShade
                    visible:                true
                    Layout.fillWidth:       true

                    GridLayout {
                        id:                         regionGrid
                        anchors.margins:            _margins
                        anchors.top:                parent.top
                        anchors.horizontalCenter:   parent.horizontalCenter
                        columns:                    2
                        rowSpacing:                 _margins * 3
                        columnSpacing:              _margins * 2

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.region.shortDescription
                            visible:            QGroundControl.settingsManager.remoteIDSettings.region.visible
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.region
                            visible:            QGroundControl.settingsManager.remoteIDSettings.region.visible
                            Layout.fillWidth:   true
                            sizeToContents:     true
                            // In case we change from EU to FAA having the location Type to FIXED, since its not supported in FAA
                            // we need to change it to Live GNSS
                            onActivated: {
                                if (currentIndex == RemoteIDSettings.RegionOperation.FAA && QGroundControl.settingsManager.remoteIDSettings.locationType.value != RemoteIDSettings.LocationType.LIVE)
                                QGroundControl.settingsManager.remoteIDSettings.locationType.value = RemoteIDSettings.LocationType.LIVE
                            }
                        }

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.classificationType.shortDescription
                            visible:            _regionOperation == RemoteIDSettings.RegionOperation.EU
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.classificationType
                            visible:            _regionOperation == RemoteIDSettings.RegionOperation.EU
                            Layout.fillWidth:   true
                            sizeToContents:     true
                        }

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.categoryEU.shortDescription
                            visible:            (_classificationType == RemoteIDSettings.ClassificationType.EU) && (_regionOperation == RemoteIDSettings.RegionOperation.EU)
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.categoryEU
                            visible:            (_classificationType == RemoteIDSettings.ClassificationType.EU) && (_regionOperation == RemoteIDSettings.RegionOperation.EU)
                            Layout.fillWidth:   true
                            sizeToContents:     true
                        }

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.classEU.shortDescription
                            visible:            (_classificationType == RemoteIDSettings.ClassificationType.EU) && (_regionOperation == RemoteIDSettings.RegionOperation.EU)
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.classEU
                            visible:            (_classificationType == RemoteIDSettings.ClassificationType.EU) && (_regionOperation == RemoteIDSettings.RegionOperation.EU)
                            Layout.fillWidth:   true
                            sizeToContents:     true
                        }
                    }
                }
                // -----------------------------------------------------------------------------------------

                // ----------------------------------------- GPS -------------------------------------------
                // Data representation and connection options for GCS GPS. 
                QGCLabel {
                    id:                 gpsLabel
                    text:               qsTr("GPS GCS")
                    Layout.alignment:   Qt.AlignHCenter
                    font.pointSize:     ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    id:                     gpsRectangle
                    Layout.preferredHeight: gpsGrid.height + gpsGridData.height + (_margins * 3)
                    Layout.preferredWidth:  gpsGrid.width + (_margins * 2)
                    color:                  qgcPal.windowShade
                    visible:                true
                    Layout.fillWidth:       true

                    border.width:   _borderWidth
                    border.color:   _activeVehicle ? (_activeVehicle.remoteIDManager.gcsGPSGood ? color : qgcPal.colorRed) : color

                    property var locationTypeValue: QGroundControl.settingsManager.remoteIDSettings.locationType.value

                    // In case we change from FAA to EU region, having selected Location Type FIXED,
                    // We have to change the currentindex to the locationType forced when we change region
                    onLocationTypeValueChanged: {
                        if (locationTypeComboBox.currentIndex != locationTypeValue) {
                            locationTypeComboBox.currentIndex = locationTypeValue
                        }
                    }

                    GridLayout {
                        id:                         gpsGridData
                        anchors.margins:            _margins
                        anchors.top:                parent.top
                        anchors.horizontalCenter:   parent.horizontalCenter
                        rowSpacing:                 _margins
                        columns:                    2
                        columnSpacing:              _margins * 2

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.locationType.shortDescription
                            visible:            QGroundControl.settingsManager.remoteIDSettings.locationType.visible
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            id:                 locationTypeComboBox
                            fact:               QGroundControl.settingsManager.remoteIDSettings.locationType
                            visible:            QGroundControl.settingsManager.remoteIDSettings.locationType.visible
                            Layout.fillWidth:   true
                            sizeToContents:     true

                            onActivated: {
                                // FAA doesnt allow to set a Fixed position. Is either Live GNSS or Takeoff
                                if (_regionOperation == RemoteIDSettings.RegionOperation.FAA) {
                                    if (currentIndex != 1) {
                                       QGroundControl.settingsManager.remoteIDSettings.locationType.value = 1
                                        currentIndex = 1 
                                    }
                                } else {
                                    // TODO: this lines below efectively disable TAKEOFF option. Uncoment when we add support for it
                                    if (currentIndex == 0) {
                                        QGroundControl.settingsManager.remoteIDSettings.locationType.value = 1
                                        currentIndex = 1
                                    } else {
                                        QGroundControl.settingsManager.remoteIDSettings.locationType.value = index
                                        currentIndex = index
                                    }
                                    // --------------------------------------------------------------------------------------------------
                                }
                            }
                        }

                        QGCLabel {
                            text:               qsTr("Latitude Fixed(-90 to 90)")
                            visible:            _locationType == RemoteIDSettings.LocationType.FIXED
                            Layout.fillWidth:   true
                        }
                        FactTextField {
                            visible:            _locationType == RemoteIDSettings.LocationType.FIXED
                            Layout.fillWidth:   true
                            fact:               QGroundControl.settingsManager.remoteIDSettings.latitudeFixed
                        }

                        QGCLabel {
                            text:               qsTr("Longitude Fixed(-180 to 180)")
                            visible:            _locationType == RemoteIDSettings.LocationType.FIXED
                            Layout.fillWidth:   true
                        }
                        FactTextField {
                            visible:            _locationType == RemoteIDSettings.LocationType.FIXED
                            Layout.fillWidth:   true
                            fact:               QGroundControl.settingsManager.remoteIDSettings.longitudeFixed
                        }

                        QGCLabel {
                            text:               qsTr("Altitude Fixed")
                            visible:            _locationType == RemoteIDSettings.LocationType.FIXED
                            Layout.fillWidth:   true
                        }
                        FactTextField {
                            visible:            _locationType == RemoteIDSettings.LocationType.FIXED
                            Layout.fillWidth:   true
                            fact:               QGroundControl.settingsManager.remoteIDSettings.altitudeFixed
                        }
                        
                        QGCLabel {
                            text:               qsTr("Latitude")
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }
                        QGCLabel {
                            text:               gcsPosition.isValid ? gcsPosition.latitude : "N/A"
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }

                        QGCLabel {
                            text:               qsTr("Longitude")
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }
                        QGCLabel {
                            text:               gcsPosition.isValid ? gcsPosition.longitude : "N/A"
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }

                        QGCLabel {
                            text:               _regionOperation == RemoteIDSettings.RegionOperation.FAA ? 
                                                qsTr("Altitude") + qsTr(" (Mandatory)") :
                                                qsTr("Altitude")
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }
                        QGCLabel {
                            text:               gcsPosition.isValid ? gcsPosition.altitude : "N/A"
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }

                        QGCLabel {
                            text:               qsTr("Heading")
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }
                        QGCLabel {
                            text:               gcsPosition.isValid && !isNaN(gcsHDOP) ? gcsHeading : "N/A"
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }

                        QGCLabel {
                            text:               qsTr("Hor. Accuracy")
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }
                        QGCLabel {
                            text:               gcsPosition.isValid && gcsHDOP ? gcsHeading : "N/A"
                            Layout.fillWidth:   true
                            visible:            _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        }
                    }

                    GridLayout {
                        id:                         gpsGrid
                        visible:                    !ScreenTools.isMobile
                                                    && QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.visible
                                                    && QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.visible
                                                    && _locationType != RemoteIDSettings.LocationType.TAKEOFF
                        anchors.margins:            _margins
                        anchors.top:                gpsGridData.bottom
                        anchors.horizontalCenter:   parent.horizontalCenter
                        rowSpacing:                 _margins * 3
                        columns:                    2
                        columnSpacing:              _margins * 2

                        QGCLabel {
                            text: qsTr("NMEA External GPS Device")
                        }
                        QGCComboBox {
                            id:                     nmeaPortCombo
                            Layout.preferredWidth:  _comboFieldWidth

                            model:  ListModel {
                            }

                            onActivated: {
                                if (index != -1) {
                                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = textAt(index);
                                }
                            }
                            Component.onCompleted: {
                                model.append({text: gpsDisabled})
                                model.append({text: gpsUdpPort})

                                for (var i in QGroundControl.linkManager.serialPorts) {
                                    nmeaPortCombo.model.append({text:QGroundControl.linkManager.serialPorts[i]})
                                }
                                var index = nmeaPortCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString);
                                nmeaPortCombo.currentIndex = index;
                                if (QGroundControl.linkManager.serialPorts.length === 0) {
                                    nmeaPortCombo.model.append({text: "Serial <none available>"})
                                }
                            }
                        }

                        QGCLabel {
                            visible:          nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled
                            text:             qsTr("NMEA GPS Baudrate")
                        }
                        QGCComboBox {
                            visible:                nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled
                            id:                     nmeaBaudCombo
                            Layout.preferredWidth:  _comboFieldWidth
                            model:                  [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]

                            onActivated: {
                                if (index != -1) {
                                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = textAt(index);
                                }
                            }
                            Component.onCompleted: {
                                var index = nmeaBaudCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString);
                                nmeaBaudCombo.currentIndex = index;
                            }
                        }

                        QGCLabel {
                            text:       qsTr("NMEA stream UDP port")
                            visible:    nmeaPortCombo.currentText === gpsUdpPort
                        }
                        FactTextField {
                            visible:                nmeaPortCombo.currentText === gpsUdpPort
                            Layout.preferredWidth:  _valueFieldWidth
                            fact:                   QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort
                        }
                    }
                }
                // -----------------------------------------------------------------------------------------

                // -------------------------------------- UAS ID -------------------------------------------
                QGCLabel {
                    id:                 uasIDLabel
                    text:               qsTr("UAS ID")
                    Layout.alignment:   Qt.AlignHCenter
                    font.pointSize:     ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    id:                     uasIDRectangle
                    Layout.preferredHeight: uasIDGrid.height + (_margins * 3)
                    Layout.preferredWidth:  uasIDGrid.width + (_margins * 2)
                    color:                  qgcPal.windowShade
                    Layout.fillWidth:       true

                    border.width:   _borderWidth
                    border.color:   _activeVehicle ? (_activeVehicle.remoteIDManager.basicIDGood ? color : qgcPal.colorRed) : color

                    GridLayout {
                        id:                         uasIDGrid
                        anchors.margins:            _margins
                        anchors.top:                parent.top
                        anchors.horizontalCenter:   parent.horizontalCenter
                        columns:                    2
                        rowSpacing:                 _margins * 3
                        columnSpacing:              _margins * 2

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.uasIDType.shortDescription
                            visible:            QGroundControl.settingsManager.remoteIDSettings.uasIDType.visible
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.uasIDType
                            visible:            QGroundControl.settingsManager.remoteIDSettings.uasIDType.visible
                            Layout.fillWidth:   true
                            sizeToContents:     true
                        }

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.uasType.shortDescription
                            visible:            QGroundControl.settingsManager.remoteIDSettings.uasType.visible
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.uasType
                            visible:            QGroundControl.settingsManager.remoteIDSettings.uasType.visible
                            Layout.fillWidth:   true
                            sizeToContents:     true
                        }

                        QGCLabel {
                            text:               _activeVehicle && _activeVehicle.remoteIDManager.basicIDGood ?
                                                QGroundControl.settingsManager.remoteIDSettings.uasID.shortDescription :
                                                QGroundControl.settingsManager.remoteIDSettings.uasID.shortDescription + qsTr(" (Mandatory)")
                            visible:            QGroundControl.settingsManager.remoteIDSettings.uasID.visible
                            Layout.alignment:   Qt.AlignHCenter
                            Layout.fillWidth:   true
                        }
                        FactTextField {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.uasID
                            visible:            QGroundControl.settingsManager.remoteIDSettings.uasID.visible
                            Layout.fillWidth:   true

                            onEditingFinished: {
                                if (_activeVehicle) {
                                    _activeVehicle.remoteIDManager.checkBasicID() 
                                }
                            }
                        }
                    }
                }
                // ------------------------------------------------------------------------------------------

                // ------------------------------------ OPERATOR ID ----------------------------------------
                QGCLabel {
                    id:                 operatorIDLabel
                    text:               qsTr("Operator ID")
                    Layout.alignment:   Qt.AlignHCenter
                    font.pointSize:     ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    id:                     operatorIDRectangle
                    Layout.preferredHeight: operatorIDGrid.height + (_margins * 3)
                    Layout.preferredWidth:  operatorIDGrid.width + (_margins * 2)
                    color:                  qgcPal.windowShade
                    Layout.fillWidth:       true

                    border.width:   _borderWidth
                    border.color:   (_regionOperation == RemoteIDSettings.RegionOperation.EU || QGroundControl.settingsManager.remoteIDSettings.sendOperatorID.value) ?
                                    (_activeVehicle && !_activeVehicle.remoteIDManager.operatorIDGood ? qgcPal.colorRed : color) : color

                    GridLayout {
                        id:                         operatorIDGrid
                        anchors.margins:            _margins
                        anchors.top:                parent.top
                        anchors.horizontalCenter:   parent.horizontalCenter
                        columns:                    2
                        rowSpacing:                 _margins * 3
                        columnSpacing:              _margins * 2

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.operatorIDType.shortDescription
                            visible:            QGroundControl.settingsManager.remoteIDSettings.operatorIDType.visible
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            fact:               QGroundControl.settingsManager.remoteIDSettings.operatorIDType
                            visible:            QGroundControl.settingsManager.remoteIDSettings.operatorIDType.visible
                            Layout.fillWidth:   true
                            sizeToContents:     true
                        }

                        QGCLabel {
                            text:               _regionOperation == RemoteIDSettings.RegionOperation.FAA ? 
                                                QGroundControl.settingsManager.remoteIDSettings.operatorID.shortDescription :
                                                QGroundControl.settingsManager.remoteIDSettings.operatorID.shortDescription + qsTr(" (Mandatory)")
                            visible:            QGroundControl.settingsManager.remoteIDSettings.operatorID.visible
                            Layout.alignment:   Qt.AlignHCenter
                            Layout.fillWidth:   true
                        }
                        FactTextField {
                            id:                 operatorIDTextField
                            fact:               QGroundControl.settingsManager.remoteIDSettings.operatorID
                            visible:            QGroundControl.settingsManager.remoteIDSettings.operatorID.visible
                            Layout.fillWidth:   true
                            maximumLength:      20 // Maximum defined by Mavlink definition of OPEN_DRONE_ID_OPERATOR_ID message
                            onEditingFinished: {
                                if (_activeVehicle) {
                                    _activeVehicle.remoteIDManager.checkOperatorID() 
                                }
                            }
                            
                        }

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.sendOperatorID.shortDescription
                            Layout.fillWidth:   true
                            visible:            _regionOperation == RemoteIDSettings.RegionOperation.FAA
                        }
                        FactCheckBox {
                            fact:       QGroundControl.settingsManager.remoteIDSettings.sendOperatorID
                            visible:    _regionOperation == RemoteIDSettings.RegionOperation.FAA
                            onClicked: {
                                if (checked) {
                                    if (_activeVehicle) {
                                        _activeVehicle.remoteIDManager.checkOperatorID() 
                                    }
                                }
                            }
                        }
                    }
                }
                // -----------------------------------------------------------------------------------------

                // -------------------------------------- SELF ID ------------------------------------------
                QGCLabel {
                    id:                 selfIDLabel
                    text:               qsTr("Self ID")
                    Layout.alignment:   Qt.AlignHCenter
                    font.pointSize:     ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    id:                     selfIDRectangle
                    Layout.preferredHeight: selfIDGrid.height + (_margins * 3)
                    Layout.preferredWidth:  selfIDGrid.width + (_margins * 2)
                    color:                  qgcPal.windowShade
                    visible:                true
                    Layout.fillWidth:       true

                    GridLayout {
                        id:                         selfIDGrid
                        anchors.margins:            _margins
                        anchors.top:                parent.top
                        anchors.horizontalCenter:   parent.horizontalCenter
                        columns:                    2
                        rowSpacing:                 _margins * 3
                        columnSpacing:              _margins * 2

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.selfIDType.shortDescription
                            visible:            QGroundControl.settingsManager.remoteIDSettings.selfIDType.visible
                            Layout.fillWidth:   true
                        }
                        FactComboBox {
                            id:                 selfIDComboBox
                            fact:               QGroundControl.settingsManager.remoteIDSettings.selfIDType
                            visible:            QGroundControl.settingsManager.remoteIDSettings.selfIDType.visible
                            Layout.fillWidth:   true
                            sizeToContents:     true
                        }

                        QGCLabel {
                            text:               getSelfIdLabelText()
                            Layout.fillWidth:   true
                        }
                        FactTextField {
                            fact:               getSelfIDFact()
                            Layout.fillWidth:   true
                            maximumLength:      23 // Maximum defined by Mavlink definition of OPEN_DRONE_ID_SELF_ID message
                        }

                        QGCLabel {
                            text:               QGroundControl.settingsManager.remoteIDSettings.sendSelfID.shortDescription
                            Layout.fillWidth:   true
                        }
                        FactCheckBox {
                            fact:       QGroundControl.settingsManager.remoteIDSettings.sendSelfID
                            visible:    QGroundControl.settingsManager.remoteIDSettings.sendSelfID.visible
                        }
                    }
                }
                // -----------------------------------------------------------------------------------------
            }
        }
    }
}
