import QtQuick
import qs.configs

Item {
    id: root

    property bool checked: false
    property bool enabled: true
    property string leftText: ""
    property string rightText: ""
    property int padding: 3

    signal toggled(bool checked)

    implicitWidth: 140
    implicitHeight: 36
    opacity: enabled ? 1.0 : 0.5

    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: Config.radius
        color: Color.overlay

        Rectangle {
            id: thumb
            readonly property real segmentWidth: (track.width - (root.padding * 2)) / 2

            width: segmentWidth
            height: track.height - (root.padding * 2)
            radius: Math.max(2, (Config.radius ?? 8) - 2)
            anchors.verticalCenter: parent.verticalCenter
            x: root.padding + (root.checked ? segmentWidth : 0)
            color: Color.primary
            scale: wholeTrackArea.pressed ? 0.95 : 1.0
            transformOrigin: Item.Center

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutQuint
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 180
                }
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: root.padding

            Item {
                width: parent.width / 2
                height: parent.height

                Text {
                    id: leftLabel
                    anchors.centerIn: parent
                    text: root.leftText
                    font.family: Config.textFont
                    font.pixelSize: 12
                    font.weight: !root.checked ? Font.DemiBold : Font.Normal
                    color: !root.checked ? Color.background : Color.muted

                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }
            }

            Item {
                width: parent.width / 2
                height: parent.height

                Text {
                    id: rightLabel
                    anchors.centerIn: parent
                    text: root.rightText
                    font.family: Config.textFont
                    font.pixelSize: 12
                    font.weight: root.checked ? Font.DemiBold : Font.Normal
                    color: root.checked ? Color.background : Color.muted

                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }
            }
        }

        MouseArea {
            id: wholeTrackArea
            anchors.fill: parent
            hoverEnabled: root.enabled
            enabled: root.enabled
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: mouse => {
                // If clicked on left half: Light (checked = false)
                // If clicked on right half: Dark (checked = true)
                const isRightSide = mouse.x >= (width / 2);
                if (root.checked !== isRightSide) {
                    root.toggled(isRightSide);
                } else {
                    root.toggled(!root.checked);
                }
            }
        }
    }
}
