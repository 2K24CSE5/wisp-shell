import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.configs
import qs.components

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: bgWindow
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.namespace: "quickshell-wallpaper"
                exclusionMode: ExclusionMode.Ignore
                color: Color.background

                Item {
                    id: wallpaperContainer
                    anchors {
                        fill: parent
                        topMargin: NiriService.isOverviewActive ? 56 : 0
                        leftMargin: NiriService.isOverviewActive ? 16 : 0
                        rightMargin: NiriService.isOverviewActive ? 16 : 0
                        bottomMargin: 0
                    }

                    Behavior on anchors.topMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on anchors.leftMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on anchors.rightMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    CrossfadeImage {
                        id: wallpaperImg
                        anchors.fill: parent
                        source: WallpaperService.imageSource
                        fillMode: Image.PreserveAspectCrop
                        transitionDuration: 350
                        opacity: 0
                        layer.enabled: true
                        layer.smooth: true
                    }

                    Rectangle {
                        id: wallpaperMask
                        anchors.fill: parent
                        opacity: 0
                        layer.enabled: true
                        layer.smooth: true
                        color: "black"

                        topLeftRadius: NiriService.isOverviewActive ? Math.max(20, Config.radius * 2) : 0
                        topRightRadius: NiriService.isOverviewActive ? Math.max(20, Config.radius * 2) : 0
                        bottomLeftRadius: 0
                        bottomRightRadius: 0

                        Behavior on topLeftRadius {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on topRightRadius {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: wallpaperImg
                        maskSource: wallpaperMask
                        maskEnabled: true
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        visible: WallpaperService.hasWallpaper
                    }
                }
            }
        }
    }
}
