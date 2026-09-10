import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.configs
import qs.services

Rectangle {
    id: root

    implicitWidth: batContent.implicitWidth + 24
    implicitHeight: 34

    readonly property bool hasLeftNeighbor: SystemTray.items.values.length > 0

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

    color: mouseArea.containsMouse ? Color.surface : Color.background
    visible: BatteryService.hasBattery

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    readonly property color accentColor: {
        if (BatteryService.percentage <= 20 && !BatteryService.isCharging) {
            return Color.error ?? "#e06c75";
        }
        return Color.primary;
    }

    ColumnLayout {
        id: batContent
        anchors.centerIn: parent
        spacing: 0

        Text {
            text: BatteryService.percentage + "%"
            font.family: Config.textFont
            font.pixelSize: 11
            font.bold: true
            color: Color.text
            Layout.alignment: Qt.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 26
            implicitHeight: 2
            radius: 1
            color: Color.overlay

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(1.0, Math.max(0.0, BatteryService.percentage / 100))
                radius: 1
                color: root.accentColor

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
