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
        title: "Idle Settings"
        iconText: "\ue897"

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue42b"
            title: "Fade to monitor off"
            subtitle: "Turn off monitors after the lock fade completes"

            Toggle {
                checked: Config.fadeToMonitorOff
                leftText: "Off"
                rightText: "On"
                onToggled: checked => Config.setFadeToMonitorOff(checked)
            }
        }

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue323"
            title: "Lock on lid close"
            subtitle: "Lock the session when the laptop lid is closed"

            Toggle {
                checked: Config.lockOnLidClose
                leftText: "Off"
                rightText: "On"
                onToggled: checked => Config.setLockOnLidClose(checked)
            }
        }

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
            title: "Lock fade grace period"
            subtitle: "Duration to smoothly darken the screen before locking"

            Selector {
                options: [
                    {
                        label: "1 second",
                        ms: 1000
                    },
                    {
                        label: "2 seconds",
                        ms: 2000
                    },
                    {
                        label: "3 seconds",
                        ms: 3000
                    },
                    {
                        label: "4 seconds",
                        ms: 4000
                    },
                    {
                        label: "5 seconds",
                        ms: 5000
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
