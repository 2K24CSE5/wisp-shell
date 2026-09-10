import QtQuick
import QtQuick.Layouts
import qs.configs
import qs.services

Rectangle {
    id: root

    implicitWidth: wsRow.implicitWidth + 24
    implicitHeight: 34

    topLeftRadius: Config.radius
    bottomLeftRadius: Config.radius
    topRightRadius: ActiveWindowService.hasActiveWindow ? 4 : Config.radius
    bottomRightRadius: ActiveWindowService.hasActiveWindow ? 4 : Config.radius

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

    RowLayout {
        id: wsRow
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: WorkspacesService.activeWorkspaces

            delegate: Item {
                id: wsDelegate
                required property var modelData

                readonly property bool isActive: modelData.isActive ?? WorkspacesService.isWorkspaceActive(modelData)
                readonly property bool isHovered: wsMouse.containsMouse

                implicitWidth: slashBar.width + 4
                implicitHeight: 34

                Rectangle {
                    id: slashBar
                    anchors.centerIn: parent
                    width: wsDelegate.isActive ? 4 : 2
                    height: wsDelegate.isActive ? 16 : (wsDelegate.isHovered ? 12 : 8)
                    radius: 1

                    rotation: -18

                    color: {
                        if (wsDelegate.isActive)
                            return Color.primary;
                        if (wsDelegate.isHovered)
                            return Color.text;
                        return Color.muted;
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WorkspacesService.focusWorkspace(wsDelegate.modelData)
                }
            }
        }
    }
}
