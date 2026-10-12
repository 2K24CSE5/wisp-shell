import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
        implicitWidth: 340
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
            spacing: 14

            // 1. Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: Math.max(4, Config.radius - 4)
                    color: MirrorService.isMirroring ? Color.primary : Color.overlay

                    Text {
                        anchors.centerIn: parent
                        text: MirrorService.isMirroring ? "\ue308" : "\ue307"
                        font.family: Config.iconFont
                        font.pixelSize: 20
                        color: MirrorService.isMirroring ? Color.background : Color.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Projector & Mirror"
                        font.family: Config.textFont
                        font.pixelSize: 15
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
                        font.pixelSize: 11
                        color: Color.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    implicitWidth: statusText.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: MirrorService.isMirroring ? (Color.primary + "22") : Color.overlay
                    border.width: MirrorService.isMirroring ? 1 : 0
                    border.color: Color.primary

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: MirrorService.isMirroring ? "ACTIVE" : (MirrorService.hasExternalDisplay ? "READY" : "IDLE")
                        font.family: Config.textFont
                        font.pixelSize: 9
                        font.bold: true
                        color: MirrorService.isMirroring ? Color.primary : Color.muted
                    }
                }
            }

            // 2. Notice if wl-mirror is missing
            Rectangle {
                visible: !MirrorService.hasWlMirror
                Layout.fillWidth: true
                implicitHeight: noticeCol.implicitHeight + 20
                radius: Math.max(4, Config.radius - 2)
                color: (Color.error ?? "#ffb4ab") + "15"
                border.width: 1
                border.color: (Color.error ?? "#ffb4ab") + "44"

                ColumnLayout {
                    id: noticeCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "\ue000"
                            font.family: Config.iconFont
                            font.pixelSize: 16
                            color: Color.error ?? "#ffb4ab"
                        }
                        Text {
                            text: "wl-mirror is not installed"
                            font.family: Config.textFont
                            font.pixelSize: 12
                            font.bold: true
                            color: Color.text
                        }
                    }

                    Text {
                        text: "Install wl-mirror to enable projector output mirroring:"
                        font.family: Config.textFont
                        font.pixelSize: 11
                        color: Color.muted
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 4
                        color: Color.overlay

                        Text {
                            anchors.centerIn: parent
                            text: "sudo dnf install wl-mirror"
                            font.family: "monospace"
                            font.pixelSize: 11
                            color: Color.text
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        buttonHeight: 32
                        variant: "secondary"
                        leadingIcon: MirrorService.copiedCommand ? "\ue876" : "\ue14d"
                        text: MirrorService.copiedCommand ? "Copied Command!" : "Copy Install Command"
                        onClicked: MirrorService.copyInstallCommand()
                    }
                }
            }

            // 3. Primary Action Button
            Button {
                Layout.fillWidth: true
                buttonHeight: 40
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
                onClicked: {
                    MirrorService.toggleMirroring();
                }
            }

            // 4. Displays Section
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: displaysCol.implicitHeight + 20
                radius: Math.max(4, Config.radius - 2)
                color: Color.surface
                border.width: 1
                border.color: Color.overlay

                ColumnLayout {
                    id: displaysCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "DETECTED DISPLAYS (" + MirrorService.outputs.length + ")"
                            font.family: Config.textFont
                            font.pixelSize: 10
                            font.bold: true
                            color: Color.muted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "\ue5d5"
                            font.family: Config.iconFont
                            font.pixelSize: 15
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
                            height: 38
                            radius: 6
                            color: (modelData.name === MirrorService.targetOutput && MirrorService.isMirroring) ? (Color.primary + "18") : Color.background
                            border.width: 1
                            border.color: (modelData.name === MirrorService.targetOutput && MirrorService.isMirroring) ? Color.primary : Color.overlay

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: modelData.isExternal ? "\ue8d8" : "\ue325"
                                    font.family: Config.iconFont
                                    font.pixelSize: 18
                                    color: modelData.isExternal ? Color.primary : Color.muted
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: modelData.name
                                        font.family: Config.textFont
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Color.text
                                    }

                                    Text {
                                        text: modelData.description
                                        font.family: Config.textFont
                                        font.pixelSize: 10
                                        color: Color.muted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    implicitWidth: tagText.implicitWidth + 8
                                    implicitHeight: 18
                                    radius: 4
                                    color: modelData.isExternal ? (Color.primary + "20") : Color.overlay

                                    Text {
                                        id: tagText
                                        anchors.centerIn: parent
                                        text: modelData.isExternal ? "Projector" : "Built-in"
                                        font.family: Config.textFont
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: modelData.isExternal ? Color.primary : Color.muted
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 5. Options
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Source Output:"
                        font.family: Config.textFont
                        font.pixelSize: 12
                        color: Color.text
                        Layout.fillWidth: true
                    }
                    Selector {
                        options: MirrorService.sourceOptions
                        selectedValue: MirrorService.sourceOutput
                        selectorWidth: 150
                        selectorHeight: 32
                        onSelected: val => MirrorService.setSourceOutput(val)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Target Output:"
                        font.family: Config.textFont
                        font.pixelSize: 12
                        color: Color.text
                        Layout.fillWidth: true
                    }
                    Selector {
                        options: MirrorService.targetOptions
                        selectedValue: MirrorService.targetOutput
                        selectorWidth: 150
                        selectorHeight: 32
                        onSelected: val => MirrorService.setTargetOutput(val)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Fullscreen Target:"
                        font.family: Config.textFont
                        font.pixelSize: 12
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
                        font.pixelSize: 12
                        color: Color.text
                        Layout.fillWidth: true
                    }
                    Selector {
                        options: MirrorService.scalingOptions
                        selectedValue: MirrorService.scaling
                        selectorWidth: 150
                        selectorHeight: 32
                        onSelected: val => MirrorService.setScaling(val)
                    }
                }
            }

            // 6. Footer tip
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Right-click widget pill to quickly toggle mirroring"
                font.family: Config.textFont
                font.pixelSize: 10
                color: Color.muted
            }
        }
    }

    function toggle(targetItem) {
        if (visible) {
            visible = false;
        } else {
            MirrorService.poll();
            anchorItem = targetItem;
            visible = true;
            card.forceActiveFocus();
        }
    }
}
