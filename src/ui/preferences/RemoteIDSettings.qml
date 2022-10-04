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

    property real _margins:             ScreenTools.defaultFontPixelWidth
    property real _labelWidth:          ScreenTools.defaultFontPixelWidth * 28
    property real _valueWidth:          ScreenTools.defaultFontPixelWidth * 24
    property real _columnSpacing:       ScreenTools.defaultFontPixelHeight * 0.25
    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle

    QGCPalette { id: qgcPal }

    QGCFlickable {
        clip:               true
        anchors.fill:       parent
        anchors.margins:    ScreenTools.defaultFontPixelWidth
        contentHeight:      outerItem.height
        contentWidth:       outerItem.width
        flickableDirection: Flickable.VerticalFlick

            Item {
            id:     outerItem
            width:  Math.max(remoteIDRoot.width, settingsItem.width)
            height: settingsItem.height

            ColumnLayout {
                id:                         settingsItem
                anchors.horizontalCenter:   parent.horizontalCenter

                QGCLabel {
                    id:                 customSettingsLabel
                    text:               qsTr("Remote ID")
                    Layout.alignment:   Qt.AlignHCenter
                }

                Rectangle {
                    id: settingsRectangle
                    Layout.preferredHeight: customSettingsGrid.height + (_margins * 2)
                    Layout.preferredWidth:  customSettingsGrid.width + (_margins * 2)
                    color:                  qgcPal.windowShade
                    visible:                true
                    Layout.fillWidth:       true

                    GridLayout {
                        id:                         customSettingsGrid
                        anchors.topMargin:          _margins
                        anchors.top:                parent.top
                        Layout.fillWidth:           false
                        anchors.horizontalCenter:   parent.horizontalCenter
                        columns:                    2
                        rowSpacing:                 _margins * 3
                        columnSpacing:              _margins * 2
                    }
                }
            }
        }
    }
}
