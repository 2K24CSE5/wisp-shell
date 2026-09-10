import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.configs
import qs.components

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: settingsWindow
            required property var modelData
            screen: modelData

            visible: SettingsService.isOpen
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Modal {
                onClosed: SettingsService.close()

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Sidebar {
                        currentTab: SettingsService.currentTab
                        onTabSelected: tab => SettingsService.setTab(tab)
                        model: [
                            {
                                name: "Appearance",
                                icon: "\ue40a",
                                tab: 0
                            },
                            {
                                name: "Niri",
                                icon: "\uef55",
                                tab: 1
                            },
                            {
                                name: "Lockscreen",
                                icon: "\ue897",
                                tab: 2
                            }
                        ]
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth

                        StackLayout {
                            width: parent.width
                            currentIndex: SettingsService.currentTab

                            SettingsAppearance {
                                Layout.fillWidth: true
                            }

                            SettingsNiri {
                                Layout.fillWidth: true
                            }

                            SettingsLockscreen {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
