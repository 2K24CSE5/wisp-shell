import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.configs
import qs.services
import qs.components

PopupWindow {
    id: root

    property Item anchorItem: null
    visible: false
    color: "transparent"

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    anchor {
        window: root.anchorItem ? root.anchorItem.QsWindow.window : null
        rect {
            x: (root.anchorItem && root.anchorItem.QsWindow.window) ? root.anchorItem.mapToItem(root.anchorItem.QsWindow.window.contentItem, 0, 0).x + (root.anchorItem.width / 2) - (card.implicitWidth / 2) : 0
            y: (root.anchorItem && root.anchorItem.QsWindow.window) ? (root.anchorItem.mapToItem(root.anchorItem.QsWindow.window.contentItem, 0, 0).y + root.anchorItem.height + 6) : 0
            width: card.implicitWidth
            height: 0
        }
        edges: Edges.Bottom
        gravity: Edges.Bottom
    }

    Rectangle {
        id: card
        implicitWidth: 310
        implicitHeight: contentCol.implicitHeight + 32
        radius: Config.radius
        color: Color.background
        border.width: 1
        border.color: Color.overlay
        focus: true

        Component.onCompleted: card.forceActiveFocus()
        onActiveFocusChanged: {
            if (!activeFocus) {
                root.visible = false;
            }
        }

        Keys.onEscapePressed: event => {
            root.visible = false;
            event.accepted = true;
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // --- Top Clock Header ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: DateTimeService.currentTime
                    font.family: Config.textFont
                    font.pixelSize: 28
                    font.bold: true
                    color: Color.text
                }

                Text {
                    text: DateTimeService.fullDateText
                    font.family: Config.textFont
                    font.pixelSize: 11
                    font.bold: false
                    color: Color.primary
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Color.overlay
            }

            // --- Month Navigation Row ---
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
                    radius: Config.radius - 2
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
                    radius: Config.radius - 2
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
                    radius: Config.radius - 2
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

            // --- Calendar Weekdays Header ---
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
                        Layout.preferredWidth: (card.implicitWidth - 32) / 7
                    }
                }
            }

            // --- Days Grid ---
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 0

                Repeater {
                    model: DateTimeService.calendarDays

                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: (card.implicitWidth - 32) / 7
                        implicitHeight: 28
                        radius: Config.radius - 4
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

    function toggle(targetItem) {
        if (visible) {
            visible = false;
        } else {
            DateTimeService.resetToToday();
            anchorItem = targetItem;
            visible = true;
            card.forceActiveFocus();
        }
    }
}
