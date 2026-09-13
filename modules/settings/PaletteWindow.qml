import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.configs
import qs.components
import qs.services

Scope {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: paletteWin
            required property var modelData
            screen: modelData
            visible: SettingsService.isPaletteOpen
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: SettingsService.isPaletteOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Modal {
                cardWidth: 620
                cardHeight: 580
                showCloseButton: true
                closeOnBackdropClick: true
                closeOnEscape: true
                // Cancelling / closing keeps dynamic active unless a palette was chosen
                onClosed: SettingsService.closePalette()

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Color Palettes"
                            font.family: Config.textFont
                            font.pixelSize: 17
                            font.bold: true
                            color: Color.text
                            Layout.fillWidth: true
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth

                        ColumnLayout {
                            width: parent.width
                            spacing: 16

                            Text {
                                text: "BUILT-IN PALETTES"
                                font.family: Config.textFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Color.muted
                            }

                            Repeater {
                                model: Color.presets
                                delegate: Rectangle {
                                    id: presetItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 52
                                    radius: Config.radius
                                    color: (Color.activePreset === modelData.id && !Color.isDynamicPalette) ? Color.overlay : (presetMouse.containsMouse ? Color.surface : "transparent")
                                    border.width: 1
                                    border.color: (Color.activePreset === modelData.id && !Color.isDynamicPalette) ? Color.primary : Color.overlay

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        Text {
                                            text: presetItem.modelData.name
                                            font.family: Config.textFont
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Color.text
                                            Layout.fillWidth: true
                                        }

                                        Row {
                                            id: previewColorsRow
                                            spacing: 6
                                            Layout.alignment: Qt.AlignVCenter
                                            readonly property var targetSet: Color.isDark ? presetItem.modelData.dark : presetItem.modelData.light

                                            Repeater {
                                                model: ["primary", "secondary", "tertiary", "surface", "background"]
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    width: 18
                                                    height: 18
                                                    radius: 9
                                                    color: (previewColorsRow.targetSet && previewColorsRow.targetSet[modelData]) || "#000000"
                                                    border.width: 1
                                                    border.color: Color.overlay
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: presetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // Applying preset turns isDynamicPalette = false and applies colors
                                            Color.applyPreset(presetItem.modelData.id);
                                            SettingsService.closePalette();
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.preferredHeight: 6
                            }

                            Text {
                                text: "CUSTOM SCHEME (" + (Color.isDark ? "DARK" : "LIGHT") + ")"
                                font.family: Config.textFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Color.muted
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 12

                                Repeater {
                                    model: [
                                        {
                                            key: "primary",
                                            label: "Primary Accent"
                                        },
                                        {
                                            key: "secondary",
                                            label: "Secondary"
                                        },
                                        {
                                            key: "tertiary",
                                            label: "Tertiary"
                                        },
                                        {
                                            key: "background",
                                            label: "Background"
                                        },
                                        {
                                            key: "surface",
                                            label: "Surface"
                                        },
                                        {
                                            key: "text",
                                            label: "Text"
                                        }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        height: 40
                                        radius: Config.radius
                                        color: Color.surface
                                        border.width: 1
                                        border.color: Color.overlay

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            Rectangle {
                                                width: 20
                                                height: 20
                                                radius: 10
                                                color: Color.getColor(modelData.key)
                                                border.width: 1
                                                border.color: Color.overlay
                                            }

                                            Text {
                                                text: modelData.label
                                                font.family: Config.textFont
                                                font.pixelSize: 12
                                                color: Color.text
                                                Layout.fillWidth: true
                                            }

                                            TextInput {
                                                text: Color.palette[modelData.key] ?? ""
                                                font.family: Config.textFont
                                                font.pixelSize: 12
                                                color: Color.primary
                                                selectByMouse: true
                                                maximumLength: 7
                                                onEditingFinished: {
                                                    let val = text.trim();
                                                    if (val.length > 0 && !val.startsWith("#"))
                                                        val = "#" + val;
                                                    if (/^#[0-9A-Fa-f]{6}$/.test(val)) {
                                                        Color.setColor(modelData.key, val);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
