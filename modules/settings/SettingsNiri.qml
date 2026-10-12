import QtQuick
import QtQuick.Layouts
import qs.configs
import qs.components
import qs.services

ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: 16

    Card {
        Layout.fillWidth: true
        title: "Window Behavior"
        iconText: "\uef55"

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue5d0"
            title: "Open windows maximized"
            subtitle: "Automatically maximize new windows into columns"

            Toggle {
                checked: Config.openMaximized
                leftText: "Off"
                rightText: "On"
                onToggled: checked => SettingsService.setOpenMaximized(checked)
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
