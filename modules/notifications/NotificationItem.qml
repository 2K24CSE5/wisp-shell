import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.configs
import qs.services

Item {
    id: root

    property var itemData: null
    readonly property var item: itemData ?? ({ id: 0, appName: "", appIcon: "", summary: "", body: "", image: "", timeStr: "now", actions: [], expanded: false })
    property bool isToast: false

    implicitHeight: mainRow.implicitHeight + 8
    Layout.fillWidth: true

    readonly property bool isAvatar: Boolean(root.item.image && (root.item.appName.toLowerCase().includes("discord") || root.item.appName.toLowerCase().includes("vesktop") || root.item.image.toLowerCase().includes("avatar")))
    readonly property bool isScreenshot: Boolean(root.item.appName.toLowerCase().includes("niri") || root.item.summary.toLowerCase().includes("screenshot"))

    RowLayout {
        id: mainRow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 2
        }
        spacing: 12

        // 1. Icon / Avatar Column
        Item {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 2
            implicitWidth: 28
            implicitHeight: 28

            // Custom Avatar / Image if present
            Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: root.isAvatar ? 13 : 4
                color: Color.overlay
                clip: true
                visible: Boolean(root.item.image && root.item.image.length > 0)

                Image {
                    anchors.fill: parent
                    source: root.item.image ? (root.item.image.startsWith("file://") || root.item.image.startsWith("http") ? root.item.image : "file://" + root.item.image) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            // Material Symbols Lightbulb for screenshots
            Text {
                anchors.centerIn: parent
                visible: (!root.item.image || root.item.image.length === 0) && root.isScreenshot
                text: "\ue0f0" // lightbulb
                font.family: Config.iconFont
                font.pixelSize: 22
                color: Color.text
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            // App Icon fallback using IconImage
            IconImage {
                anchors.centerIn: parent
                width: 22
                height: 22
                visible: (!root.item.image || root.item.image.length === 0) && !root.isScreenshot && Boolean(root.item.appIcon && root.item.appIcon.length > 0)
                source: root.item.appIcon || ""
            }

            // Default Bell icon fallback
            Text {
                anchors.centerIn: parent
                visible: (!root.item.image || root.item.image.length === 0) && !root.isScreenshot && (!root.item.appIcon || root.item.appIcon.length === 0)
                text: "\ue7f5" // notifications
                font.family: Config.iconFont
                font.pixelSize: 20
                color: Color.text
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // 2. Center Content Column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            // Summary & Relative Time
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.item.summary || root.item.appName || "Notification"
                    font.family: Config.textFont
                    font.pixelSize: 13
                    font.bold: true
                    color: Color.text
                    elide: Text.ElideRight
                    Layout.maximumWidth: 220
                }

                Text {
                    text: "•"
                    font.pixelSize: 10
                    color: Color.muted
                }

                Text {
                    text: root.item.timeStr || "now"
                    font.family: Config.textFont
                    font.pixelSize: 12
                    color: Color.muted
                }
            }

            // Body
            Text {
                visible: Boolean(root.item.body && root.item.body.length > 0)
                text: root.item.body || ""
                font.family: Config.textFont
                font.pixelSize: 12
                color: Color.text
                opacity: 0.9
                lineHeight: 1.15
                wrapMode: Text.Wrap
                maximumLineCount: root.item.expanded ? 50 : 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Action Buttons
            RowLayout {
                visible: Boolean(root.item.actions && root.item.actions.length > 0)
                Layout.topMargin: 4
                spacing: 8

                Repeater {
                    model: root.item.actions || []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        implicitWidth: actText.implicitWidth + 24
                        implicitHeight: 28
                        radius: 4
                        color: actMouse.containsMouse ? Color.overlay : Color.surface
                        border.width: 1
                        border.color: Color.overlay

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            id: actText
                            anchors.centerIn: parent
                            text: modelData.text || "Action"
                            font.family: Config.textFont
                            font.pixelSize: 12
                            font.bold: true
                            color: Color.text
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                try {
                                    modelData.invoke();
                                } catch (_) {}
                            }
                        }
                    }
                }
            }
        }

        // 3. Right Action Column (Close & Expand)
        ColumnLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            spacing: 6

            // Dismiss Button
            Item {
                implicitWidth: 18
                implicitHeight: 18
                Layout.alignment: Qt.AlignRight

                Text {
                    anchors.centerIn: parent
                    text: "\ue5cd" // close
                    font.family: Config.iconFont
                    font.pixelSize: 14
                    color: closeMouse.containsMouse ? Color.text : Color.muted

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.isToast) {
                            NotificationService.dismissToast(root.item.id);
                        } else {
                            NotificationService.dismissItem(root.item.id);
                        }
                    }
                }
            }

            // Expand Chevron
            Item {
                visible: !root.isToast && Boolean((root.item.body && root.item.body.length > 50) || (root.item.actions && root.item.actions.length > 0))
                implicitWidth: 18
                implicitHeight: 18
                Layout.alignment: Qt.AlignRight

                Text {
                    anchors.centerIn: parent
                    text: root.item.expanded ? "\ue5ce" : "\ue5cf" // expand_less vs expand_more
                    font.family: Config.iconFont
                    font.pixelSize: 14
                    color: expMouse.containsMouse ? Color.text : Color.muted
                }

                MouseArea {
                    id: expMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.toggleItemExpanded(root.item.id)
                }
            }
        }
    }
}
