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
        spacing: 14

        // Top Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                implicitWidth: 38
                implicitHeight: 20
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
                Layout.fillWidth: true
                spacing: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Battery " + BatteryService.percentage + "%"
                    font.family: Config.textFont
                    font.pixelSize: 14
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

            CloseButton {
                size: 26
                iconSize: 16
                Layout.alignment: Qt.AlignTop
                onClicked: root.collapseRequested()
            }
        }

        // Stats Table
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

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
                        font.pixelSize: 11
                        color: Color.muted
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.value
                        font.family: "monospace"
                        font.pixelSize: 11
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
            spacing: 6

            Text {
                text: "Power Mode"
                font.family: Config.textFont
                font.pixelSize: 11
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
                        implicitHeight: 30
                        radius: Math.max(2, Config.radius - 4)
                        color: isSelected ? Color.primary : (modeMouse.containsMouse ? Color.overlay : Color.surface)
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
                            font.pixelSize: 10
                            font.bold: modeBtn.isSelected
                            color: modeBtn.isSelected ? Color.background : Color.text
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
