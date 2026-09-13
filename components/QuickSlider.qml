import QtQuick
import QtQuick.Layouts
import qs.configs

Rectangle {
    id: root

    property string iconText: ""
    property real value: 0.0 // 0.0 to 1.0

    signal moved(real val)

    implicitWidth: 140
    implicitHeight: 38
    radius: Config.radius
    color: Color.surface
    clip: true

    // Track active fill
    Rectangle {
        id: fillTrack
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: Math.max(0, Math.min(parent.width, parent.width * root.value))
        radius: Config.radius
        color: Color.primary
        opacity: root.enabled ? 1.0 : 0.4

        Behavior on width {
            enabled: !sliderMouse.pressed
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Icon
        Text {
            visible: root.iconText.length > 0
            text: root.iconText
            font.family: Config.iconFont
            font.pixelSize: 17
            color: root.value > 0.12 ? Color.background : Color.text
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Percentage text
        Text {
            text: Math.round(root.value * 100) + "%"
            font.family: Config.textFont
            font.pixelSize: 11
            font.bold: true
            color: root.value > 0.88 ? Color.background : Color.text
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }
        }
    }

    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateValue(mouseX) {
            let newVal = Math.max(0.0, Math.min(1.0, mouseX / root.width));
            root.moved(newVal);
        }

        onPressed: mouse => updateValue(mouse.x)
        onPositionChanged: mouse => {
            if (pressed) {
                updateValue(mouse.x);
            }
        }

        onWheel: wheel => {
            let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            let targetVal = Math.max(0.0, Math.min(1.0, root.value + delta));
            root.moved(targetVal);
        }
    }
}
