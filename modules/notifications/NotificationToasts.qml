import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.configs
import qs.services

PanelWindow {
    id: root

    visible: NotificationService.toasts.length > 0 && !NotificationService.isOpen && !LockScreenService.isLocked
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: 48
        right: 12
    }

    implicitWidth: 380
    implicitHeight: toastCol.implicitHeight

    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: toastCol
        width: 380
        spacing: 8

        Repeater {
            model: NotificationService.toasts

            delegate: Rectangle {
                id: toastCard
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: toastItem.implicitHeight + 12
                radius: Config.radius
                color: Color.background
                clip: true

                NotificationItem {
                    id: toastItem
                    anchors.centerIn: parent
                    width: parent.width - 12
                    itemData: toastCard.modelData
                    isToast: true
                }
            }
        }
    }
}
