import QtQuick
import QtQuick.Layouts
import qs.configs
import qs.components
import qs.services

ColumnLayout {
    id: root

    Layout.fillWidth: true

    Card {
        Layout.fillWidth: true
        title: "Lock screen"
        iconText: "\ue897"

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\uea9b"
            title: "Lock when idle"
            subtitle: "Automatically lock the session after inactivity"

            Selector {
                options: [
                    {
                        label: "Disabled",
                        minutes: 0
                    },
                    {
                        label: "5 minutes",
                        minutes: 5
                    },
                    {
                        label: "10 minutes",
                        minutes: 10
                    },
                    {
                        label: "15 minutes",
                        minutes: 15
                    },
                    {
                        label: "30 minutes",
                        minutes: 30
                    },
                    {
                        label: "1 hour",
                        minutes: 60
                    }
                ]
                valueRole: "minutes"
                selectedValue: Config.idleLockTimeout
                onSelected: value => SettingsService.setIdleLockTimeout(value)
            }
        }

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue3e7"
            title: "Fade out speed"
            subtitle: "Duration to smoothly darken the screen before locking"

            Selector {
                options: [
                    {
                        label: "Fast (500ms)",
                        ms: 500
                    },
                    {
                        label: "Normal (1s)",
                        ms: 1000
                    },
                    {
                        label: "Smooth (1.5s)",
                        ms: 1500
                    },
                    {
                        label: "Slow (2s)",
                        ms: 2000
                    },
                    {
                        label: "Cinema (3s)",
                        ms: 3000
                    }
                ]
                valueRole: "ms"
                selectedValue: Config.fadeDuration
                onSelected: value => SettingsService.setFadeDuration(value)
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
