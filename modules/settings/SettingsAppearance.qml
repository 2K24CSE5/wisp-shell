import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.configs
import qs.components
import qs.services

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 16

    Card {
        Layout.fillWidth: true
        title: "Wallpaper"
        iconText: "\ue3f4"

        Item {
            id: previewContainer
            Layout.fillWidth: true
            height: 180

            Rectangle {
                anchors.fill: parent
                radius: Config.radius
                color: Color.overlay
                antialiasing: true
                smooth: true
                visible: !WallpaperService.hasWallpaper

                Text {
                    anchors.centerIn: parent
                    text: "\ue3f4"
                    font.family: Config.iconFont
                    font.pixelSize: 36
                    color: Color.muted
                }
            }

            Image {
                id: previewImage
                anchors.fill: parent
                visible: false
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: true
                smooth: true
                layer.enabled: true
                layer.smooth: true
                source: WallpaperService.hasWallpaper ? (WallpaperService.currentWallpaper.startsWith("file://") ? WallpaperService.currentWallpaper : "file://" + WallpaperService.currentWallpaper) : ""
            }

            Rectangle {
                id: previewMask
                anchors.fill: parent
                visible: false
                radius: Config.radius
                color: "black"
                antialiasing: true
                smooth: true
                layer.enabled: true
                layer.smooth: true
                layer.effect: null
            }

            MultiEffect {
                anchors.fill: parent
                source: previewImage
                maskSource: previewMask
                maskEnabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                visible: WallpaperService.hasWallpaper
            }
        }

        CardRow {
            Layout.fillWidth: true
            clickable: true
            leadingIcon: "\ue1bc"
            trailingIcon: "\ue5cc"
            title: "Wallpaper"
            subtitle: WallpaperService.hasWallpaper ? WallpaperService.currentWallpaper.replace(/^file:\/\//, "") : "No wallpaper selected"
            onClicked: SettingsService.openWallpaperPicker()
        }
    }

    Card {
        Layout.fillWidth: true
        title: "Style"
        iconText: "\ue40a"

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue51c"
            title: "Theme mode"
            subtitle: "Choose between light and dark themes"
            Toggle {
                checked: Color.isDark
                leftText: "Light"
                rightText: "Dark"
                onToggled: checked => Color.setDark(checked)
            }
        }

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue40a"
            title: "Color palette"
            subtitle: Color.isDynamicPalette ? "Dynamic colors generated from wallpaper" : (Color.activePreset === "custom" ? "Custom color scheme" : "Preset: " + (Color.presets.find(p => p.id === Color.activePreset)?.name ?? "Built-in"))

            Toggle {
                // Left = Dynamic (checked: false), Right = Palettes (checked: true)
                checked: !Color.isDynamicPalette
                leftText: "Dynamic"
                rightText: "Palettes"
                onToggled: checked => {
                    if (!checked) {
                        // User explicitly clicked Dynamic: switch back and regenerate
                        Color.setDynamic(true);
                        SettingsService.closePalette();
                        if (WallpaperService.hasWallpaper) {
                            MatugenService.generateColors(WallpaperService.currentWallpaper);
                        }
                    } else {
                        // User clicked Palettes: open picker, but do NOT disable dynamic yet
                        SettingsService.openPalette();
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
