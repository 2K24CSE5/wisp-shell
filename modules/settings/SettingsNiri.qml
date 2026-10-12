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

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue3c6"
            title: "Window border"
            subtitle: "Continuous border drawn around all windows"

            Toggle {
                checked: Config.borderEnabled
                leftText: "Off"
                rightText: "On"
                onToggled: checked => SettingsService.setBorderEnabled(checked)
            }
        }

        CardRow {
            visible: Config.borderEnabled
            Layout.fillWidth: true
            leadingIcon: "\ue22b"
            title: "Border width"
            subtitle: "Adjust border thickness (" + Config.borderWidth + "px)"

            Stepper {
                value: Config.borderWidth
                minimumValue: 1
                maximumValue: 20
                onValueModified: val => SettingsService.setBorderWidth(val)
            }
        }

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue9eb"
            title: "Window gaps"
            subtitle: "Space between windows (" + Config.gaps + "px)"

            Stepper {
                value: Config.gaps
                minimumValue: 0
                maximumValue: 64
                onValueModified: val => SettingsService.setGaps(val)
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
