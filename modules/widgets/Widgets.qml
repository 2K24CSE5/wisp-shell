import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: topBar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 42
    color: "transparent"

    Item {
        anchors {
            fill: parent
            topMargin: 4
            leftMargin: 4
            rightMargin: 4
        }

        RowLayout {
            id: leftSection
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                right: centerSection.left
                rightMargin: 8
            }
            spacing: 2

            Workspaces {}
            ActiveWindow {}

            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            id: centerSection
            anchors.centerIn: parent
            spacing: 8

            Clock {}
        }

        RowLayout {
            id: rightSection
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                left: centerSection.right
                leftMargin: 8
            }
            layoutDirection: Qt.RightToLeft
            spacing: 2

            QuickMenu {}
            Battery {}
            Tray {}

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
