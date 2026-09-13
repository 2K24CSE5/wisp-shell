import QtQuick
import QtQuick.Layouts
import qs.configs
import qs.services

Rectangle {
    id: root

    implicitWidth: Math.min(320, appCol.implicitWidth + 24)
    implicitHeight: 34

    topLeftRadius: 4
    bottomLeftRadius: 4
    topRightRadius: Config.radius
    bottomRightRadius: Config.radius

    color: Color.background
    visible: NiriService.hasActiveWindow

    ColumnLayout {
        id: appCol
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: -12
        Layout.alignment: Qt.AlignVCenter

        Text {
            visible: NiriService.formattedAppName.length > 0
            text: NiriService.formattedAppName
            font.family: Config.textFont
            font.pixelSize: 10
            font.bold: true
            color: Color.primary
            verticalAlignment: Text.AlignVCenter
            lineHeight: 1.0
        }

        Text {
            Layout.fillWidth: true
            visible: NiriService.activeTitle.length > 0
            text: NiriService.activeTitle
            font.family: Config.textFont
            font.pixelSize: 10
            color: Color.text
            opacity: 0.85
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            lineHeight: 1.0
        }
    }
}
