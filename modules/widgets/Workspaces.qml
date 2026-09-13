import QtQuick
import qs.configs
import qs.services

Rectangle {
    id: root

    readonly property int itemWidth: 20
    readonly property int itemSpacing: 2
    readonly property int padMargin: 4

    implicitWidth: railTrack.implicitWidth + 16
    implicitHeight: 34

    topLeftRadius: Config.radius
    bottomLeftRadius: Config.radius
    topRightRadius: NiriService.hasActiveWindow ? 4 : Config.radius
    bottomRightRadius: NiriService.hasActiveWindow ? 4 : Config.radius

    Behavior on topRightRadius {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    Behavior on bottomRightRadius {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    color: Color.background

    // Recessed track
    Rectangle {
        id: railTrack
        anchors.centerIn: parent
        implicitWidth: wsRow.implicitWidth + (root.padMargin * 2)
        implicitHeight: 24
        radius: Config.radius
        color: Color.surface

        // Direct mathematical slider positioning
        Rectangle {
            id: indicator
            height: 18
            width: root.itemWidth
            radius: Math.max(2, (Config.radius ?? 8) - 4)
            color: Color.primary
            anchors.verticalCenter: parent.verticalCenter
            visible: NiriService.activeWorkspaces.length > 0 && NiriService.currentWorkspaceIndex >= 0 && NiriService.currentWorkspaceIndex < NiriService.activeWorkspaces.length

            x: root.padMargin + (NiriService.currentWorkspaceIndex * (root.itemWidth + root.itemSpacing))

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutQuint
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
            }
        }

        Row {
            id: wsRow
            anchors.left: parent.left
            anchors.leftMargin: root.padMargin
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.itemSpacing

            Repeater {
                id: wsRepeater
                model: NiriService.activeWorkspaces

                delegate: Item {
                    id: wsDelegate
                    required property var modelData
                    required property int index

                    readonly property bool isActive: (index === NiriService.currentWorkspaceIndex)
                    readonly property bool isHovered: wsMouse.containsMouse

                    implicitWidth: root.itemWidth
                    implicitHeight: 18

                    Text {
                        anchors.centerIn: parent
                        text: String(modelData.idx ?? modelData.id ?? (index + 1))
                        font.family: Config.textFont
                        font.pixelSize: 11
                        font.bold: wsDelegate.isActive
                        scale: wsDelegate.isHovered && !wsDelegate.isActive ? 1.15 : 1.0

                        color: {
                            if (wsDelegate.isActive)
                                return Color.background;
                            if (wsDelegate.isHovered)
                                return Color.text;
                            return Color.muted;
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutQuad
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NiriService.focusWorkspace(wsDelegate.modelData)
                    }
                }
            }
        }
    }
}
