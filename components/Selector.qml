import QtQuick
import QtQuick.Controls
import qs.configs

Item {
    id: root

    property var options: []
    property string textRole: "label"
    property string valueRole: "value"
    property var selectedValue: null
    property string placeholderText: "Select"
    property real selectorWidth: 150
    property real selectorHeight: 36

    signal selected(var value)

    implicitWidth: root.selectorWidth
    implicitHeight: root.selectorHeight

    function selectedIndex(): int {
        return root.options.findIndex(option => option[root.valueRole] === root.selectedValue);
    }

    function selectedText(): string {
        const index = root.selectedIndex();
        return index >= 0 ? String(root.options[index][root.textRole]) : root.placeholderText;
    }

    Rectangle {
        id: selectorSurface
        anchors.fill: parent
        radius: Config.radius
        color: popup.open || selectorMouseArea.containsMouse ? Color.overlay : Color.surface

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - expandIcon.width - parent.spacing
                text: root.selectedText()
                elide: Text.ElideRight
                font.family: Config.textFont
                font.pixelSize: 12
                color: Color.text
            }

            Text {
                id: expandIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "\ue5cf"
                font.family: Config.iconFont
                font.pixelSize: 18
                color: Color.muted
            }
        }

        MouseArea {
            id: selectorMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.open()
        }
    }

    Popup {
        id: popup
        x: 0
        y: root.height + 4
        width: root.width
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: Config.radius
            color: Color.surface
            border.width: 1
            border.color: Color.overlay
        }

        contentItem: ListView {
            id: optionsView
            implicitHeight: Math.min(contentHeight, 240)
            clip: true
            model: root.options

            delegate: Rectangle {
                required property var modelData

                width: optionsView.width
                height: 34
                radius: Config.radius - 2
                color: optionMouseArea.containsMouse ? Color.overlay : "transparent"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    text: modelData[root.textRole]
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.family: Config.textFont
                    font.pixelSize: 12
                    color: modelData[root.valueRole] === root.selectedValue ? Color.primary : Color.text
                }

                MouseArea {
                    id: optionMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedValue = modelData[root.valueRole];
                        root.selected(modelData[root.valueRole]);
                        popup.close();
                    }
                }
            }
        }
    }
}