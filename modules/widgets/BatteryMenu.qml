import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.configs
import qs.services

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
            x: (root.anchorItem && root.anchorItem.QsWindow.window) ? root.anchorItem.mapToItem(root.anchorItem.QsWindow.window.contentItem, 0, 0).x : 0
            y: (root.anchorItem && root.anchorItem.QsWindow.window) ? (root.anchorItem.mapToItem(root.anchorItem.QsWindow.window.contentItem, 0, 0).y + root.anchorItem.height + 6) : 0
            width: root.anchorItem ? root.anchorItem.width : 0
            height: 0
        }
        edges: Edges.Bottom
        gravity: Edges.Bottom
    }

    Rectangle {
        id: card
        x: -4
        implicitWidth: 320
        implicitHeight: contentCol.implicitHeight + 36
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
            anchors.margins: 18
            spacing: 18

            // Top Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    implicitWidth: 42
                    implicitHeight: 22
                    radius: 4
                    color: "transparent"
                    border.width: 2
                    border.color: Color.primary
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        width: Math.max(2, (parent.width - 4) * Math.min(1.0, Math.max(0.0, BatteryService.percentage / 100)))
                        radius: 2
                        color: Color.primary
                    }

                    Rectangle {
                        anchors.left: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 3
                        implicitHeight: 8
                        radius: 1
                        color: Color.primary
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Battery " + BatteryService.percentage + "%"
                        font.family: Config.textFont
                        font.pixelSize: 15
                        font.bold: true
                        color: Color.text
                    }

                    Text {
                        visible: BatteryService.timeRemaining.length > 0
                        text: BatteryService.timeRemaining
                        font.family: Config.textFont
                        font.pixelSize: 11
                        color: Color.muted
                    }
                }
            }

            // Stats Table
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        {
                            label: "Status:",
                            value: BatteryService.statusText || "DISCHARGING"
                        },
                        {
                            label: "Health:",
                            value: (BatteryService.health ? BatteryService.health.toFixed(1) : "100.0") + "%"
                        },
                        {
                            label: "Charge cycles:",
                            value: String(BatteryService.cycleCount || 0)
                        },
                        {
                            label: "Power draw:",
                            value: (BatteryService.powerDraw ? BatteryService.powerDraw.toFixed(1) : "0.0") + " W"
                        },
                        {
                            label: "Voltage:",
                            value: (BatteryService.voltage ? BatteryService.voltage.toFixed(1) : "0.0") + " V"
                        }
                    ]

                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true

                        Text {
                            text: modelData.label
                            font.family: "monospace"
                            font.pixelSize: 12
                            color: Color.muted
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.value
                            font.family: "monospace"
                            font.pixelSize: 12
                            font.bold: true
                            color: Color.text
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }

            // Power Mode Controls
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Power Mode"
                    font.family: Config.textFont
                    font.pixelSize: 12
                    font.bold: true
                    color: Color.text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            {
                                id: "power-saver",
                                label: "Power Saver"
                            },
                            {
                                id: "balanced",
                                label: "Balanced"
                            },
                            {
                                id: "performance",
                                label: "Performance"
                            }
                        ]

                        delegate: Rectangle {
                            id: modeBtn
                            required property var modelData
                            readonly property bool isSelected: BatteryService.activeProfile === modelData.id
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Config.radius
                            color: isSelected ? Color.surface : (modeMouse.containsMouse ? Color.overlay : "transparent")
                            border.width: 1
                            border.color: isSelected ? Color.primary : Color.overlay

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modeBtn.modelData.label
                                font.family: Config.textFont
                                font.pixelSize: 11
                                font.bold: modeBtn.isSelected
                                color: modeBtn.isSelected ? Color.primary : Color.muted
                            }

                            MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BatteryService.setPowerProfile(modeBtn.modelData.id)
                            }
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
            BatteryService.poll();
            anchorItem = targetItem;
            visible = true;
            card.forceActiveFocus();
        }
    }
}
