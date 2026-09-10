import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.configs
import qs.services

Rectangle {
    id: root

    implicitWidth: iconRow.implicitWidth + 20
    implicitHeight: 34

    readonly property bool hasLeftNeighbor: BatteryService.hasBattery || SystemTray.items.values.length > 0

    topRightRadius: Config.radius
    bottomRightRadius: Config.radius
    topLeftRadius: hasLeftNeighbor ? 4 : Config.radius
    bottomLeftRadius: hasLeftNeighbor ? 4 : Config.radius

    Behavior on topLeftRadius {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    color: buttonArea.containsMouse ? Color.surface : Color.background

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    RowLayout {
        id: iconRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: WidgetsService.ethernetConnected || WidgetsService.wifiEnabled
            font.family: Config.iconFont
            font.pixelSize: 18

            text: WidgetsService.ethernetConnected ? "settings_ethernet" : (WidgetsService.wifiConnected ? "wifi" : "wifi_off")

            color: (WidgetsService.ethernetConnected || WidgetsService.wifiConnected) ? Color.primary : Color.text
        }

        Text {
            visible: WidgetsService.bluetoothEnabled
            font.family: Config.iconFont
            font.pixelSize: 18
            text: WidgetsService.bluetoothConnected ? "bluetooth_connected" : "bluetooth"

            color: WidgetsService.bluetoothConnected ? Color.primary : Color.text
        }
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {}
    }
}
