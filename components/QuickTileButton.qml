import QtQuick
import qs.configs

Rectangle {
    id: root

    property bool active: false
    property bool expanded: false

    signal clicked

    implicitWidth: 30
    implicitHeight: 44

    topRightRadius: Config.radius
    bottomRightRadius: Config.radius
    topLeftRadius: 4
    bottomLeftRadius: 4

    // Reverted: active uses Color.primary; inactive uses Color.surface
    color: {
        if (root.active) {
            return mouseArea.containsMouse ? Qt.lighter(Color.primary, 1.08) : Color.primary;
        }
        return mouseArea.containsMouse ? Color.overlay : Color.surface;
    }

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.expanded ? "\ue5cf" : "\ue5cc"
        font.family: Config.iconFont
        font.pixelSize: 18
        color: root.active ? Color.background : (mouseArea.containsMouse ? Color.text : Color.muted)

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
