import QtQuick
import QtQuick.Layouts
import qs.configs

Rectangle {
    id: root

    property string title: ""
    property string statusText: ""
    property string iconText: ""
    property bool active: false

    signal clicked

    implicitWidth: 120
    implicitHeight: 44

    topLeftRadius: Config.radius
    bottomLeftRadius: Config.radius
    topRightRadius: 4
    bottomRightRadius: 4

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

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 8

        // Icon circular badge
        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: width / 2
            color: root.active ? Color.background : (mouseArea.containsMouse ? Color.overlay : Color.background)
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.iconText
                font.family: Config.iconFont
                font.pixelSize: 15
                color: root.active ? Color.primary : Color.muted
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }
            }
        }

        // Title and micro status typography
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                text: root.title
                font.family: Config.textFont
                font.pixelSize: 11
                font.bold: true
                color: root.active ? Color.background : Color.text
                elide: Text.ElideRight
                Layout.fillWidth: true

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }
            }

            Text {
                text: root.statusText.toUpperCase()
                font.family: Config.textFont
                font.pixelSize: 8
                font.bold: true
                color: root.active ? Qt.darker(Color.background, 1.25) : Color.muted
                opacity: root.active ? 0.9 : 0.85
                elide: Text.ElideRight
                Layout.fillWidth: true

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }
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
