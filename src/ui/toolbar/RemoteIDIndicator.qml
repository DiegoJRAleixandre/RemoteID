import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

//-------------------------------------------------------------------------
//-- Remote ID Indicator
Item {
    id:             _root
    width:          remoteIDIcon.width * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: QGroundControl.settingsManager.remoteIDSettings.enable.value

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property int    remoteIDState:      RemoteIDIndicator.RIDState.UNAVAILABLE
    property bool   remoteIDAvailable:  true//(_activeVehicle && _activeVehicle.remoteID.available)
    property bool   gpsFlag:            true//(_activeVehicle && _activeVehicle.gpsFlag)
    property bool   uasIDFlag:          true//(_activeVehicle && _activeVehicle.uasIDFlag)
    property bool   armFlag:            true//(_activeVehicle && _activeVehicle.armFlag)
    property bool   commsFlag:          true//(_activeVehicle && _activeVehicle.commsFlag)

    // Flags visual properties
    property real   flagsWidth:         ScreenTools.defaultFontPixelWidth * 10
    property real   flagsHeight:        ScreenTools.defaultFontPixelWidth * 5
    property int    radiusFlags:        5

    enum RIDState {
        HEALTHY,
        WARNING,
        ERROR,
        UNAVAILABLE
    }

    function getRIDIcon() {
        switch (remoteIDState) {
            case RemoteIDIndicator.RIDState.HEALTHY: 
                return "/qmlimages/RID_ICON_GREEN_SVG.svg"
                break
            case RemoteIDIndicator.RIDState.WARNING: 
                return "/qmlimages/RID_ICON_YELLOW_SVG.svg"
                break
            case RemoteIDIndicator.RIDState.ERROR: 
                return "/qmlimages/RID_ICON_RED_SVG.svg"
                break
            case RemoteIDIndicator.RIDState.UNAVAILABLE: 
                return "/qmlimages/RID_ICON_GREY_SVG.svg"
                break
            default:
                return "/qmlimages/RID_ICON_GREY_SVG.svg"
        }
    }

    Component {
        id: remoteIDInfo

        Rectangle {
            width:          remoteIDCol.width   + ScreenTools.defaultFontPixelWidth  * 3
            height:         remoteIDCol.height  + ScreenTools.defaultFontPixelHeight * 2
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                 remoteIDCol
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(remoteIDGrid.width, remoteIDLabel.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    id:                         remoteIDLabel
                    text:                       remoteIDAvailable ? qsTr("RemoteID Status") : qsTr("RemoteID Data Unavailable")
                    font.family:                ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter:   parent.horizontalCenter
                }

                GridLayout {
                    id:                         remoteIDGrid
                    visible:                    remoteIDAvailable
                    anchors.margins:            ScreenTools.defaultFontPixelHeight
                    columnSpacing:              ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter:   parent.horizontalCenter
                    columns:                    2

                    Image {
                        id:                 gpsFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             gpsFlag ? "/qmlimages/RID_FLAG_BACKGROUND_GREEN_SVG.svg" : "/qmlimages/RID_FLAG_BACKGROUND_RED_SVG.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("GCS GPS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }
                    }

                    Image {
                        id:                 uasIDFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             uasIDFlag ? "/qmlimages/RID_FLAG_BACKGROUND_GREEN_SVG.svg" : "/qmlimages/RID_FLAG_BACKGROUND_RED_SVG.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("UAS ID")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }
                    }

                    Image {
                        id:                 armFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             armFlag ? "/qmlimages/RID_FLAG_BACKGROUND_GREEN_SVG.svg" : "/qmlimages/RID_FLAG_BACKGROUND_RED_SVG.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("ARM STATUS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }
                    }

                    Image {
                        id:                 commsFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             commsFlag ? "/qmlimages/RID_FLAG_BACKGROUND_GREEN_SVG.svg" : "/qmlimages/RID_FLAG_BACKGROUND_RED_SVG.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("RID COMMS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }
                    }
                }

                QGCLabel {
                    id:                     emergencyDeclareLabel
                    text:                   qsTr("Press to declare emergency")
                    font.family:            ScreenTools.demiboldFontFamily
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    wrapMode:               Text.WordWrap
                    horizontalAlignment:    Text.AlignHCenter
                }

                Image {
                    id:                         emergencyButton
                    width:                      flagsWidth * 2
                    height:                     flagsHeight * 2
                    source:                     "/qmlimages/RID_EMERGENCY_BACKGROUND_SVG.svg"
                    fillMode:                   Image.PreserveAspectFit
                    sourceSize.height:          height
                    anchors.horizontalCenter:   parent.horizontalCenter

                    QGCLabel {
                        anchors.fill:           parent
                        text:                   qsTr("EMERGENCY")
                        wrapMode:               Text.WordWrap
                        horizontalAlignment:    Text.AlignHCenter
                        verticalAlignment:      Text.AlignVCenter
                        font.bold:              true
                        font.pointSize:         ScreenTools.largeFontPointSize
                    }

                    Timer {
                        id:             emergencyButtonTimer
                        interval:       350
                        onTriggered: {
                            emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_SVG.svg"
                        }
                    }

                    MouseArea {
                        anchors.fill:   parent
                        onClicked: {
                            emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_HIGHLIGHT_SVG.svg"
                            emergencyButtonTimer.restart()
                            //Declare emergency
                        }
                    }
                }
            }
        }
    }

    Image {
        id:                 remoteIDIcon
        width:              height
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        source:             getRIDIcon()
        fillMode:           Image.PreserveAspectFit
        sourceSize.height:  height
    }

    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, remoteIDInfo)
        }
    }
}
