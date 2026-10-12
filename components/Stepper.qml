import QtQuick
import QtQuick.Layouts
import qs.configs

Item {
    id: root

    property int value: 0
    property int minimumValue: 0
    property int maximumValue: 20
    property int step: 1
    property bool enabled: true

    signal valueModified(int value)

    implicitWidth: mainRow.implicitWidth
    implicitHeight: 34
    width: implicitWidth
    height: implicitHeight

    opacity: root.enabled ? 1.0 : 0.5
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 6

        // 1. Minus Button
        Item {
            id: minusBtn
            width: 28
            height: 28
            Layout.alignment: Qt.AlignVCenter

            readonly property bool canDecrement: root.enabled && root.value > root.minimumValue

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: minusMouse.pressed ? Color.overlay : (minusMouse.containsMouse ? (Color.overlay + "88") : "transparent")
                visible: minusMouse.containsMouse || minusMouse.pressed

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "-"
                font.family: Config.textFont
                font.pixelSize: 18
                font.weight: Font.Normal
                color: minusBtn.canDecrement ? (minusMouse.containsMouse ? Color.text : Color.muted) : (Color.muted + "44")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            MouseArea {
                id: minusMouse
                anchors.fill: parent
                enabled: minusBtn.canDecrement
                hoverEnabled: minusBtn.canDecrement
                cursorShape: minusBtn.canDecrement ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    const next = Math.max(root.minimumValue, root.value - root.step);
                    if (next !== root.value) {
                        root.value = next;
                        root.valueModified(next);
                    }
                }
            }
        }

        // 2. Center Value Pill
        Rectangle {
            id: valuePill
            width: 46
            height: 28
            radius: 9
            color: Color.overlay
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                id: valText
                anchors.centerIn: parent
                text: String(root.value)
                font.family: Config.textFont
                font.pixelSize: 13
                font.weight: Font.Normal
                color: Color.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: root.enabled
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) {
                        if (plusBtn.canIncrement) {
                            const next = Math.min(root.maximumValue, root.value + root.step);
                            root.value = next;
                            root.valueModified(next);
                        }
                    } else if (wheel.angleDelta.y < 0) {
                        if (minusBtn.canDecrement) {
                            const next = Math.max(root.minimumValue, root.value - root.step);
                            root.value = next;
                            root.valueModified(next);
                        }
                    }
                }
            }
        }

        // 3. Plus Button
        Item {
            id: plusBtn
            width: 28
            height: 28
            Layout.alignment: Qt.AlignVCenter

            readonly property bool canIncrement: root.enabled && root.value < root.maximumValue

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: plusMouse.pressed ? Color.overlay : (plusMouse.containsMouse ? (Color.overlay + "88") : "transparent")
                visible: plusMouse.containsMouse || plusMouse.pressed

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "+"
                font.family: Config.textFont
                font.pixelSize: 18
                font.weight: Font.Normal
                color: plusBtn.canIncrement ? (plusMouse.containsMouse ? Color.text : Color.muted) : (Color.muted + "44")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            MouseArea {
                id: plusMouse
                anchors.fill: parent
                enabled: plusBtn.canIncrement
                hoverEnabled: plusBtn.canIncrement
                cursorShape: plusBtn.canIncrement ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    const next = Math.min(root.maximumValue, root.value + root.step);
                    if (next !== root.value) {
                        root.value = next;
                        root.valueModified(next);
                    }
                }
            }
        }
    }
}
