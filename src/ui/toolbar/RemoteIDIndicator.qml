/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

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
    property int    remoteIDState:      getRemoteIDState()
    property bool   gpsFlag:            _activeVehicle ? _activeVehicle.remoteIDManager.gcsGPSGood : false
    property bool   uasIDFlag:          _activeVehicle ? _activeVehicle.remoteIDManager.basicIDGood : false
    property bool   armFlag:            _activeVehicle ? _activeVehicle.remoteIDManager.armStatusGood : false
    property bool   commsFlag:          _activeVehicle ? _activeVehicle.remoteIDManager.commsGood : false
    property bool   emergencyDeclared:  _activeVehicle ? _activeVehicle.remoteIDManager.emergencyDeclared : false
    property bool   operatorIDFlag:     _activeVehicle ? _activeVehicle.remoteIDManager.operatorIDGood : false
    property int    _regionOperation:   QGroundControl.settingsManager.remoteIDSettings.region.value

    // Flags visual properties
    property real   flagsWidth:         ScreenTools.defaultFontPixelWidth * 10
    property real   flagsHeight:        ScreenTools.defaultFontPixelWidth * 5
    property int    radiusFlags:        5

    // Visual properties
    property real   _margins:           ScreenTools.defaultFontPixelWidth

    enum RIDState {
        HEALTHY,
        WARNING,
        ERROR,
        UNAVAILABLE
    }

    enum RegionOperation {
        FAA,
        EU
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

    function getRemoteIDState() {
        if (!_activeVehicle) {
            return RemoteIDIndicator.RIDState.UNAVAILABLE
        }
        // We need to have comms and arm healthy to even be in any other state other than ERROR
        if (!commsFlag || !armFlag || emergencyDeclared) {
            return RemoteIDIndicator.RIDState.ERROR
        }
        if (!gpsFlag || !uasIDFlag) {
            return RemoteIDIndicator.RIDState.WARNING
        }
        if (_regionOperation == RemoteIDIndicator.RegionOperation.EU || QGroundControl.settingsManager.remoteIDSettings.sendOperatorID.value) {
            if (!operatorIDFlag) {
                return RemoteIDIndicator.RIDState.WARNING
            }
        }
        return RemoteIDIndicator.RIDState.HEALTHY
    }

    function goToSettings() {
        if (!mainWindow.preventViewSwitch()) {
            globals.commingFromRIDIndicator = true
            mainWindow.showSettingsTool()
        }
    }

    Component {
        id: remoteIDInfo

        Rectangle {
            width:          remoteIDCol.width + ScreenTools.defaultFontPixelWidth  * 3
            height:         remoteIDCol.height + ScreenTools.defaultFontPixelHeight * 2 + (emergencyButtonItem.visible ? emergencyButtonItem.height : 0)
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                         remoteIDCol
                spacing:                    ScreenTools.defaultFontPixelHeight * 0.5
                width:                      Math.max(remoteIDGrid.width, remoteIDLabel.width)
                anchors.margins:            ScreenTools.defaultFontPixelHeight
                anchors.top:                parent.top
                anchors.horizontalCenter:   parent.horizontalCenter

                QGCLabel {
                    id:                         remoteIDLabel
                    text:                       qsTr("RemoteID Status")
                    font.family:                ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter:   parent.horizontalCenter
                }

                GridLayout {
                    id:                         remoteIDGrid
                    anchors.margins:            ScreenTools.defaultFontPixelHeight
                    columnSpacing:              ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter:   parent.horizontalCenter
                    columns:                    2

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

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
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

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }
                    
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

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
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

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }

                    Image {
                        id:                 operatorIDFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             operatorIDFlag ? "/qmlimages/RID_FLAG_BACKGROUND_GREEN_SVG.svg" : "/qmlimages/RID_FLAG_BACKGROUND_RED_SVG.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height
                        visible:            _activeVehicle ? (QGroundControl.settingsManager.remoteIDSettings.sendOperatorID.value || _regionOperation == RemoteIDIndicator.RegionOperation.EU) : false

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("OPERATOR ID")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }
                }
            }

            Item {
                id:             emergencyButtonItem
                anchors.top:    remoteIDCol.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height:         emergencyDeclared ? emergencyDeclaredLabel.height + (_margins * 2): emergencyDeclareLabel.height + emergencyButton.height + (_margins * 4)
                visible:        commsFlag

                QGCLabel {
                    id:                     emergencyDeclaredLabel
                    text:                   qsTr("EMERGENCY HAS BEEN DECLARED")
                    font.family:            ScreenTools.demiboldFontFamily
                    anchors.top:            parent.top
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.margins:        _margins
                    anchors.topMargin:      _margins * 3
                    wrapMode:               Text.WordWrap
                    horizontalAlignment:    Text.AlignHCenter
                    color:                  qgcPal.colorRed
                    visible:                emergencyDeclared
                }
                
                QGCLabel {
                    id:                     emergencyDeclareLabel
                    text:                   qsTr("Press&Hold below button to declare emergency")
                    font.family:            ScreenTools.demiboldFontFamily
                    anchors.top:            parent.top
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.margins:        _margins
                    anchors.topMargin:      _margins * 3
                    wrapMode:               Text.WordWrap
                    horizontalAlignment:    Text.AlignHCenter
                    visible:                !emergencyDeclared
                }

                Image {
                    id:                         emergencyButton
                    width:                      flagsWidth * 2
                    height:                     flagsHeight * 1.5
                    source:                     "/qmlimages/RID_EMERGENCY_BACKGROUND_SVG.svg"
                    sourceSize.height:          height
                    anchors.horizontalCenter:   parent.horizontalCenter
                    anchors.top:                emergencyDeclareLabel.bottom
                    anchors.margins:            _margins
                    visible:                    !emergencyDeclared

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
                            if (emergencyButton.source == "/qmlimages/RID_EMERGENCY_BACKGROUND_HIGHLIGHT_SVG.svg" ) {
                                emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_SVG.svg"
                            } else {
                                emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_HIGHLIGHT_SVG.svg"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill:   parent
                        hoverEnabled:   true
                        onEntered:      emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_HIGHLIGHT_SVG.svg"
                        onExited:       emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_SVG.svg"
                        onPressAndHold: {
                            if (emergencyButton.source == "/qmlimages/RID_EMERGENCY_BACKGROUND_HIGHLIGHT_SVG.svg" ) {
                                emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_SVG.svg"
                            } else {
                                emergencyButton.source = "/qmlimages/RID_EMERGENCY_BACKGROUND_HIGHLIGHT_SVG.svg"
                            }
                            emergencyButtonTimer.restart()
                            if (_activeVehicle) {
                                _activeVehicle.remoteIDManager.declareEmergency()
                            }
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
