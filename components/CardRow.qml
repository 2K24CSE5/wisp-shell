import QtQuick
import QtQuick.Layouts
import qs.configs

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string leadingIcon: ""
    property string trailingIcon: ""
    property real subtitleMaxWidth: 320
    property real rowHeight: 48
    property real rowRadius: Config.radius
    property real horizontalPadding: 8
    property real iconSize: 20
    property real titleSize: 13
    property real subtitleSize: 11
    property bool clickable: false

    property color idleColor: "transparent"
    property color hoverColor: Color.overlay
    property color textColor: Color.text
    property color mutedColor: Color.muted

    property alias leadingContent: leadingSlot.data
    default property alias trailingContent: trailingSlot.data

    signal clicked

    Layout.fillWidth: true
    implicitHeight: Math.max(root.rowHeight, labelsCol.implicitHeight + 16)
    radius: root.rowRadius
    color: (root.clickable && rowMouseArea.containsMouse) ? root.hoverColor : root.idleColor

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        spacing: 8

        Item {
            id: leadingSlot
            visible: children.length > 0
            implicitWidth: children.length > 0 ? children[0].implicitWidth || root.iconSize : 0
            implicitHeight: children.length > 0 ? children[0].implicitHeight || root.iconSize : 0
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: leadingSlot.children.length === 0 && root.leadingIcon.length > 0
            text: root.leadingIcon
            font.family: Config.iconFont
            font.pixelSize: root.iconSize
            color: root.textColor
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            id: labelsCol
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: root.title
                font.family: Config.textFont
                font.pixelSize: root.titleSize
                font.bold: true
                color: root.textColor
                visible: root.title.length > 0
            }

            Text {
                text: root.subtitle
                font.family: Config.textFont
                font.pixelSize: root.subtitleSize
                color: root.mutedColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.maximumWidth: root.subtitleMaxWidth
                visible: root.subtitle.length > 0
            }
        }

        Item {
            id: trailingSlot
            visible: children.length > 1 || root.trailingIcon.length > 0
            implicitWidth: {
                if (children.length > 1) {
                    return children[1].implicitWidth || children[1].width || 0;
                }
                return root.trailingIcon.length > 0 ? root.iconSize : 0;
            }
            implicitHeight: {
                if (children.length > 1) {
                    return children[1].implicitHeight || children[1].height || 0;
                }
                return root.trailingIcon.length > 0 ? root.iconSize : 0;
            }
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                visible: parent.children.length === 1 && root.trailingIcon.length > 0
                text: root.trailingIcon
                font.family: Config.iconFont
                font.pixelSize: root.iconSize
                color: root.textColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    MouseArea {
        id: rowMouseArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
