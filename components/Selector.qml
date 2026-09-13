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
    property bool enabled: true
    property real radiusValue: Config.radius
    property color backgroundColor: Color.surface
    property color hoverColor: Color.overlay
    property color borderColor: Color.overlay
    property color activeBorderColor: Color.primary

    signal selected(var value)

    implicitWidth: root.selectorWidth
    implicitHeight: root.selectorHeight
    opacity: root.enabled ? 1.0 : 0.55

    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

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
        radius: root.radiusValue
        color: selectorMouseArea.pressed ? Qt.darker(root.hoverColor, 1.08) : (popup.open || selectorMouseArea.containsMouse ? root.hoverColor : root.backgroundColor)

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
                color: root.enabled ? Color.text : Color.muted
            }

            Text {
                id: expandIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "\ue5cf"
                font.family: Config.iconFont
                font.pixelSize: 18
                color: Color.text
            }
        }

        MouseArea {
            id: selectorMouseArea
            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: root.enabled
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        enabled: root.enabled

        background: Rectangle {
            radius: root.radiusValue
            color: Color.surface
            border.width: 1
            border.color: Color.overlay
        }

        contentItem: ListView {
            id: optionsView
            implicitHeight: Math.min(contentHeight, 240)
            clip: true
            model: root.options
            spacing: 4

            delegate: Rectangle {
                required property var modelData

                width: optionsView.width
                height: 34
                radius: Math.max(2, root.radiusValue - 2)
                color: modelData[root.valueRole] === root.selectedValue ? Color.overlay : (optionMouseArea.containsMouse ? Color.overlay : "transparent")

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 30
                    text: modelData[root.textRole]
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.family: Config.textFont
                    font.pixelSize: 12
                    color: modelData[root.valueRole] === root.selectedValue ? Color.primary : Color.text
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue5ca"
                    font.family: Config.iconFont
                    font.pixelSize: 16
                    color: Color.primary
                    visible: modelData[root.valueRole] === root.selectedValue
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