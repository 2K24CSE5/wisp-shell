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

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: Math.max(4, Config.radius - 4)
                color: MirrorService.isMirroring ? Color.primary : Color.overlay

                Text {
                    anchors.centerIn: parent
                    text: MirrorService.isMirroring ? "\ue308" : "\ue307"
                    font.family: Config.iconFont
                    font.pixelSize: 18
                    color: MirrorService.isMirroring ? Color.background : Color.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Projector & Mirror"
                    font.family: Config.textFont
                    font.pixelSize: 14
                    font.bold: true
                    color: Color.text
                }

                Text {
                    text: {
                        if (MirrorService.isMirroring)
                            return "Mirroring to " + (MirrorService.targetOutput || "display");
                        if (!MirrorService.hasWlMirror)
                            return "Requires wl-mirror utility";
                        if (MirrorService.hasExternalDisplay)
                            return "Projector / external display detected";
                        return "Mirror screen to window or display";
                    }
                    font.family: Config.textFont
                    font.pixelSize: 10
                    color: Color.muted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            CloseButton {
                size: 26
                iconSize: 16
                Layout.alignment: Qt.AlignTop
                onClicked: root.collapseRequested()
            }
        }

        // Notice if wl-mirror is missing
        Rectangle {
            visible: !MirrorService.hasWlMirror
            Layout.fillWidth: true
            implicitHeight: noticeCol.implicitHeight + 16
            radius: Math.max(4, Config.radius - 4)
            color: (Color.error ?? "#ffb4ab") + "15"
            border.width: 1
            border.color: (Color.error ?? "#ffb4ab") + "44"

            ColumnLayout {
                id: noticeCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    spacing: 6
                    Text {
                        text: "\ue000"
                        font.family: Config.iconFont
                        font.pixelSize: 14
                        color: Color.error ?? "#ffb4ab"
                    }
                    Text {
                        text: "wl-mirror is not installed"
                        font.family: Config.textFont
                        font.pixelSize: 11
                        font.bold: true
                        color: Color.text
                    }
                }

                Button {
                    Layout.fillWidth: true
                    buttonHeight: 28
                    variant: "secondary"
                    leadingIcon: MirrorService.copiedCommand ? "\ue876" : "\ue14d"
                    text: MirrorService.copiedCommand ? "Copied Command!" : "Copy Install Command"
                    onClicked: MirrorService.copyInstallCommand()
                }
            }
        }

        // Primary Action Button
        Button {
            Layout.fillWidth: true
            buttonHeight: 34
            variant: MirrorService.isMirroring ? "danger" : "primary"
            leadingIcon: MirrorService.isMirroring ? "\ue047" : "\ue307"
            text: {
                if (MirrorService.isMirroring)
                    return "Stop Mirroring";
                if (MirrorService.hasExternalDisplay)
                    return "Mirror to " + MirrorService.targetOutput;
                return "Open Mirror Window";
            }
            enabled: MirrorService.hasWlMirror
            onClicked: MirrorService.toggleMirroring()
        }

        // Displays Section
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: displaysCol.implicitHeight + 16
            radius: Math.max(4, Config.radius - 4)
            color: Color.surface
            border.width: 1
            border.color: Color.overlay

            ColumnLayout {
                id: displaysCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "DISPLAYS (" + MirrorService.outputs.length + ")"
                        font.family: Config.textFont
                        font.pixelSize: 9
                        font.bold: true
                        color: Color.muted
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "\ue5d5"
                        font.family: Config.iconFont
                        font.pixelSize: 14
                        color: refreshMouse.containsMouse ? Color.primary : Color.muted
                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MirrorService.poll()
                        }
                    }
                }

                Repeater {
                    model: MirrorService.outputs

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 32
                        radius: 4
                        color: (modelData.name === MirrorService.targetOutput && MirrorService.isMirroring) ? (Color.primary + "18") : Color.background
                        border.width: 1
                        border.color: (modelData.name === MirrorService.targetOutput && MirrorService.isMirroring) ? Color.primary : Color.overlay

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: modelData.isExternal ? "\ue8d8" : "\ue325"
                                font.family: Config.iconFont
                                font.pixelSize: 16
                                color: modelData.isExternal ? Color.primary : Color.muted
                            }

                            Text {
                                text: modelData.name
                                font.family: Config.textFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Color.text
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                implicitWidth: tagText.implicitWidth + 8
                                implicitHeight: 16
                                radius: 3
                                color: modelData.isExternal ? (Color.primary + "20") : Color.overlay

                                Text {
                                    id: tagText
                                    anchors.centerIn: parent
                                    text: modelData.isExternal ? "Projector" : "Built-in"
                                    font.family: Config.textFont
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: modelData.isExternal ? Color.primary : Color.muted
                                }
                            }
                        }
                    }
                }
            }
        }

        // Options
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Target Output:"
                    font.family: Config.textFont
                    font.pixelSize: 11
                    color: Color.text
                    Layout.fillWidth: true
                }
                Selector {
                    options: MirrorService.targetOptions
                    selectedValue: MirrorService.targetOutput
                    selectorWidth: 140
                    selectorHeight: 28
                    onSelected: val => MirrorService.setTargetOutput(val)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Fullscreen Target:"
                    font.family: Config.textFont
                    font.pixelSize: 11
                    color: Color.text
                    Layout.fillWidth: true
                }
                Toggle {
                    checked: MirrorService.fullscreen
                    onToggled: chk => MirrorService.setFullscreen(chk)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Scaling Mode:"
                    font.family: Config.textFont
                    font.pixelSize: 11
                    color: Color.text
                    Layout.fillWidth: true
                }
                Selector {
                    options: MirrorService.scalingOptions
                    selectedValue: MirrorService.scaling
                    selectorWidth: 140
                    selectorHeight: 28
                    onSelected: val => MirrorService.setScaling(val)
                }
            }
        }
    }
}
