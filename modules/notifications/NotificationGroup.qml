import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.configs
import qs.services

Rectangle {
    id: root

    required property var modelData
    readonly property var groupData: modelData ?? ({ appName: "App", appIcon: "", timeStr: "now", count: 0, items: [] })

    Layout.fillWidth: true
    implicitHeight: groupCol.implicitHeight + 20
    radius: Config.radius
    color: Color.surface

    ColumnLayout {
        id: groupCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 8

        // Group Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // App Icon
            Item {
                implicitWidth: 18
                implicitHeight: 18
                Layout.alignment: Qt.AlignVCenter

                readonly property bool isNiri: root.groupData.appName.toLowerCase().includes("niri")
                readonly property string iconSrc: root.groupData.appIcon || ""

                IconImage {
                    id: iconImg
                    anchors.fill: parent
                    source: parent.iconSrc
                    visible: !parent.isNiri && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.isNiri || !iconImg.visible
                    text: parent.isNiri ? "\uef55" : "\ue871" // niri icon vs apps icon fallback
                    font.family: Config.iconFont
                    font.pixelSize: 18
                    color: Color.text
                }
            }

            // App Name
            Text {
                text: root.groupData.appName
                font.family: Config.textFont
                font.pixelSize: 13
                font.bold: true
                color: Color.text
                verticalAlignment: Text.AlignVCenter
            }

            // Relative Time
            Text {
                text: root.groupData.timeStr || "now"
                font.family: Config.textFont
                font.pixelSize: 12
                color: Color.muted
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            // Badge Count
            Rectangle {
                implicitWidth: Math.max(20, countText.implicitWidth + 12)
                implicitHeight: 20
                radius: 10
                color: Color.overlay

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: String(root.groupData.count)
                    font.family: Config.textFont
                    font.pixelSize: 11
                    font.bold: true
                    color: Color.text
                }
            }

            // Dismiss Group Button
            Item {
                implicitWidth: 20
                implicitHeight: 20

                Text {
                    anchors.centerIn: parent
                    text: "\ue5cd" // close
                    font.family: Config.iconFont
                    font.pixelSize: 16
                    color: groupCloseMouse.containsMouse ? Color.text : Color.muted

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    id: groupCloseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.dismissGroup(root.groupData.appName)
                }
            }
        }

        // Divider below header
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.overlay
            opacity: 0.6
        }

        // Notification Items in this group
        Repeater {
            model: root.groupData.items

            delegate: ColumnLayout {
                id: itemDelegate
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 0

                Rectangle {
                    visible: itemDelegate.index > 0
                    Layout.fillWidth: true
                    height: 1
                    color: Color.overlay
                    opacity: 0.4
                    Layout.bottomMargin: 4
                }

                NotificationItem {
                    itemData: itemDelegate.modelData
                }
            }
        }
    }
}
