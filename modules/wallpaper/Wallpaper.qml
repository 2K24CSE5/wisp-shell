import QtQuick
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

                CrossfadeImage {
                    source: WallpaperService.imageSource
                    fillMode: Image.PreserveAspectCrop
                    transitionDuration: 350
                }
            }
        }
    }
}
