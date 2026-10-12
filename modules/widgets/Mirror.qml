import QtQuick
import qs.configs
import qs.services

Rectangle {
    id: root

    implicitWidth: iconText.implicitWidth + 20
    implicitHeight: 34

    readonly property bool hasLeftNeighbor: TrayService.hasItems

    radius: 0
    topRightRadius: 4
    bottomRightRadius: 4
    topLeftRadius: hasLeftNeighbor ? 4 : Config.radius
    bottomLeftRadius: hasLeftNeighbor ? 4 : Config.radius

    Behavior on topLeftRadius {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    color: (mouseArea.containsMouse || mirrorMenu.visible) ? Color.surface : Color.background
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    readonly property color accentColor: {
        if (MirrorService.isMirroring)
            return Color.primary;
        if (!MirrorService.hasWlMirror)
            return Color.error ?? "#eb6f92";
        if (MirrorService.hasExternalDisplay)
            return Color.primary;
        return Color.muted;
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text: MirrorService.isMirroring ? "\ue308" : "\ue307"
        font.family: Config.iconFont
        font.pixelSize: 16
        color: root.accentColor
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MirrorMenu {
        id: mirrorMenu
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                MirrorService.toggleMirroring();
            } else {
                mirrorMenu.toggle(root);
            }
        }
    }
}
