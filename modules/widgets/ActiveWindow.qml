import QtQuick
import QtQuick.Layouts
import qs.configs
import qs.services

Rectangle {
    id: root

    implicitWidth: Math.min(320, appRow.implicitWidth + 24)
    implicitHeight: 34

    topLeftRadius: 4
    bottomLeftRadius: 4
    topRightRadius: Config.radius
    bottomRightRadius: Config.radius

    color: Color.background

    visible: ActiveWindowService.hasActiveWindow

    RowLayout {
        id: appRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            visible: ActiveWindowService.formattedAppName.length > 0
            text: ActiveWindowService.formattedAppName
            font.family: Config.textFont
            font.pixelSize: 12
            font.bold: true
            color: Color.primary
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            visible: ActiveWindowService.formattedAppName.length > 0 && ActiveWindowService.activeTitle.length > 0
            implicitWidth: 3
            implicitHeight: 3
            radius: 1.5
            color: Color.muted
            opacity: 0.6
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            Layout.fillWidth: true
            visible: ActiveWindowService.activeTitle.length > 0
            text: ActiveWindowService.activeTitle
            font.family: Config.textFont
            font.pixelSize: 12
            color: Color.text
            opacity: 0.9
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
