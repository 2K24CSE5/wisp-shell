import QtQuick
import QtQuick.Layouts
import qs.configs

Rectangle {
    id: root

    implicitWidth: clockRow.implicitWidth + 24
    implicitHeight: 34

    radius: Config.radius
    color: Color.background

    property string currentTime: ""
    property string currentDate: ""

    function updateTime() {
        const now = new Date();
        root.currentTime = Qt.formatTime(now, "hh:mm A");
        root.currentDate = Qt.formatDate(now, "ddd, MMM d");
    }

    Component.onCompleted: updateTime()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateTime()
    }

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.currentTime
            font.family: Config.textFont
            font.pixelSize: 13
            font.bold: true
            color: Color.text
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            implicitWidth: 3
            implicitHeight: 3
            radius: 1.5
            color: Color.muted
            opacity: 0.6
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.currentDate
            font.family: Config.textFont
            font.pixelSize: 12
            color: Color.muted
            verticalAlignment: Text.AlignVCenter
        }
    }
}
