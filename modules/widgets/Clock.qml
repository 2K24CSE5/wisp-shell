import QtQuick
import QtQuick.Layouts
import qs.configs
import qs.services

Rectangle {
    id: root

    implicitWidth: clockRow.implicitWidth + 24
    implicitHeight: 34
    radius: Config.radius
    color: (clockMouse.containsMouse || clockMenu.visible) ? Color.surface : Color.background

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8

        // Stacked Date
        ColumnLayout {
            spacing: -1
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: DateTimeService.currentDay
                font.family: Config.textFont
                font.pixelSize: 8
                font.bold: true
                color: Color.primary
                lineHeight: 1.0
            }

            Text {
                text: DateTimeService.currentMonthDate
                font.family: Config.textFont
                font.pixelSize: 9
                color: Color.text
                lineHeight: 1.0
            }
        }

        // Vertical Separator
        Rectangle {
            implicitWidth: 1
            implicitHeight: 11
            color: Color.overlay
            opacity: 0.8
            Layout.alignment: Qt.AlignVCenter
        }

        // Time
        Text {
            text: DateTimeService.currentTime
            font.family: Config.textFont
            font.pixelSize: 13
            font.bold: true
            color: Color.text
            verticalAlignment: Text.AlignVCenter
        }
    }

    ClockMenu {
        id: clockMenu
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: clockMenu.toggle(root)
    }
}
