import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.configs
import qs.services

Rectangle {
    id: root
    implicitWidth: mainRow.implicitWidth + 20
    implicitHeight: 34

    readonly property bool hasLeftNeighbor: true

    radius: 0
    topRightRadius: 4
    bottomRightRadius: 4
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

    color: (mouseArea.containsMouse || batteryMenu.visible) ? Color.surface : Color.background
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    visible: BatteryService.hasBattery

    readonly property color accentColor: {
        if (BatteryService.isCharging)
            return Color.primary;
        if (BatteryService.percentage <= 20)
            return Color.error ?? "#eb6f92";
        if (BatteryService.percentage <= 35)
            return Color.warning ?? "#f6c177";
        return Color.primary;
    }

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 6

        ColumnLayout {
            spacing: -2
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 2
                Layout.alignment: Qt.AlignRight

                Text {
                    visible: BatteryService.isCharging
                    text: "\ue3e7" // Material lightning icon
                    font.family: Config.iconFont
                    font.pixelSize: 10
                    color: root.accentColor
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: BatteryService.isCharging ? "PWR" : "BAT"
                    font.family: Config.textFont
                    font.pixelSize: 8
                    font.bold: true
                    color: root.accentColor
                    lineHeight: 1.0
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Text {
                text: BatteryService.percentage + "%"
                font.family: Config.textFont
                font.pixelSize: 11
                font.bold: true
                color: Color.text
                lineHeight: 1.0
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    BatteryMenu {
        id: batteryMenu
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: batteryMenu.toggle(root)
    }
}
