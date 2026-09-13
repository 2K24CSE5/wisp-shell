import QtQuick
import qs.configs

Item {
    id: root

    property bool checked: false
    property bool enabled: true
    property string leftText: "Off"
    property string rightText: "On"
    property int padding: 3
    property int labelPadding: 10

    signal toggled(bool checked)

    readonly property real leftSegmentWidth: Math.round(leftLabel.implicitWidth + (root.labelPadding * 2))
    readonly property real rightSegmentWidth: Math.round(rightLabel.implicitWidth + (root.labelPadding * 2))

    implicitWidth: root.leftSegmentWidth + root.rightSegmentWidth + (root.padding * 2)
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

        // Sliding thumb adapting to each option's dynamic width
        Rectangle {
            id: thumb
            width: root.checked ? root.rightSegmentWidth : root.leftSegmentWidth
            height: track.height - (root.padding * 2)
            radius: Math.max(2, (Config.radius ?? 8) - 2)
            anchors.verticalCenter: parent.verticalCenter
            x: root.padding + (root.checked ? root.leftSegmentWidth : 0)
            color: Color.primary
            scale: (leftArea.pressed || rightArea.pressed) ? 0.95 : 1.0
            transformOrigin: Item.Center

            Behavior on x {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutQuint
                }
            }

            Behavior on width {
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
                id: leftSegment
                width: root.leftSegmentWidth
                height: parent.height

                Text {
                    id: leftLabel
                    anchors.centerIn: parent
                    text: root.leftText
                    font.family: Config.textFont
                    font.pixelSize: 12
                    font.weight: !root.checked ? Font.DemiBold : Font.Normal
                    color: !root.checked ? Color.background : (leftArea.containsMouse ? Color.text : Color.muted)

                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }

                MouseArea {
                    id: leftArea
                    anchors.fill: parent
                    hoverEnabled: root.enabled
                    enabled: root.enabled
                    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.toggled(false)
                }
            }

            Item {
                id: rightSegment
                width: root.rightSegmentWidth
                height: parent.height

                Text {
                    id: rightLabel
                    anchors.centerIn: parent
                    text: root.rightText
                    font.family: Config.textFont
                    font.pixelSize: 12
                    font.weight: root.checked ? Font.DemiBold : Font.Normal
                    color: root.checked ? Color.background : (rightArea.containsMouse ? Color.text : Color.muted)

                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }

                MouseArea {
                    id: rightArea
                    anchors.fill: parent
                    hoverEnabled: root.enabled
                    enabled: root.enabled
                    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.toggled(true)
                }
            }
        }
    }
}
