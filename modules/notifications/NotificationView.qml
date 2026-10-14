import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.configs
import qs.services
import qs.modules.notifications

Item {
    id: root

    signal collapseRequested

    implicitWidth: 380
    implicitHeight: {
        if (NotificationService.count === 0)
            return 380;
        return Math.min(520, Math.max(220, groupsList.contentHeight + 56));
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8

        // Top Header Row
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8

            Text {
                text: "Notifications"
                font.family: Config.textFont
                font.pixelSize: 15
                font.bold: true
                color: Color.text
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            // Clear All Button
            Rectangle {
                implicitWidth: clearRow.implicitWidth + 20
                implicitHeight: 28
                radius: Math.max(4, Config.radius - 6)
                color: clearMouse.containsMouse ? Color.overlay : Color.surface
                border.width: 1
                border.color: Color.overlay

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\ue0b8" // clear_all
                        font.family: Config.iconFont
                        font.pixelSize: 15
                        color: Color.text
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: "Clear All"
                        font.family: Config.textFont
                        font.pixelSize: 12
                        font.bold: true
                        color: Color.text
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearAll()
                }
            }
        }

        // Content Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty State (Screenshot 1)
            Item {
                anchors.fill: parent
                visible: NotificationService.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "\ue7f6" // notifications_off
                        font.family: Config.iconFont
                        font.pixelSize: 42
                        color: Color.text
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No notifications"
                        font.family: Config.textFont
                        font.pixelSize: 14
                        font.bold: true
                        color: Color.text
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Populated State (Screenshot 2)
            ScrollView {
                id: scrollView
                anchors.fill: parent
                visible: NotificationService.count > 0
                clip: true
                contentWidth: availableWidth

                ListView {
                    id: groupsList
                    width: scrollView.availableWidth
                    spacing: 10
                    model: NotificationService.groups

                    delegate: NotificationGroup {
                        width: groupsList.width
                    }
                }
            }
        }
    }
}
