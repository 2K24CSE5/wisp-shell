import QtQuick
import QtQuick.Layouts
import qs.configs
import qs.services
import qs.components

Item {
    id: root

    signal collapseRequested()

    implicitHeight: contentCol.implicitHeight + 12

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 6
        spacing: 12

        // Top Clock Header with collapse button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: DateTimeService.currentTime
                    font.family: Config.textFont
                    font.pixelSize: 26
                    font.bold: true
                    color: Color.text
                }

                Text {
                    text: DateTimeService.fullDateText
                    font.family: Config.textFont
                    font.pixelSize: 11
                    color: Color.primary
                }
            }

            CloseButton {
                size: 26
                iconSize: 16
                Layout.alignment: Qt.AlignTop
                onClicked: root.collapseRequested()
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.overlay
        }

        // Month Navigation Row
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: DateTimeService.viewMonthName
                font.family: Config.textFont
                font.pixelSize: 13
                font.bold: true
                color: Color.text
                Layout.fillWidth: true
            }

            // Today Button
            Rectangle {
                implicitWidth: 44
                implicitHeight: 24
                radius: Math.max(2, Config.radius - 4)
                color: todayMouse.containsMouse ? Color.overlay : Color.surface

                Text {
                    anchors.centerIn: parent
                    text: "Today"
                    font.family: Config.textFont
                    font.pixelSize: 10
                    color: Color.text
                }

                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DateTimeService.resetToToday()
                }
            }

            // Prev Month
            Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: Math.max(2, Config.radius - 4)
                color: prevMouse.containsMouse ? Color.overlay : Color.surface

                Text {
                    anchors.centerIn: parent
                    text: "\ue5cb" // chevron_left
                    font.family: Config.iconFont
                    font.pixelSize: 16
                    color: Color.text
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DateTimeService.prevMonth()
                }
            }

            // Next Month
            Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: Math.max(2, Config.radius - 4)
                color: nextMouse.containsMouse ? Color.overlay : Color.surface

                Text {
                    anchors.centerIn: parent
                    text: "\ue5cc" // chevron_right
                    font.family: Config.iconFont
                    font.pixelSize: 16
                    color: Color.text
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DateTimeService.nextMonth()
                }
            }
        }

        // Calendar Weekdays Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Text {
                    required property string modelData
                    text: modelData
                    font.family: Config.textFont
                    font.pixelSize: 10
                    font.bold: true
                    color: Color.muted
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }

        // Days Grid
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: DateTimeService.calendarDays

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: Math.max(2, Config.radius - 6)
                    color: modelData.isToday ? Color.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: String(modelData.day)
                        font.family: Config.textFont
                        font.pixelSize: 11
                        font.bold: modelData.isToday
                        color: {
                            if (modelData.isToday)
                                return Color.background;
                            if (!modelData.isCurrentMonth)
                                return Color.muted;
                            return Color.text;
                        }
                        opacity: modelData.isCurrentMonth ? 1.0 : 0.35
                    }
                }
            }
        }
    }
}
