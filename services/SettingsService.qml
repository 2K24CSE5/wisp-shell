pragma Singleton
import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.configs
import qs.services

Singleton {
    id: root

    property bool isOpen: false
    property int currentTab: 0
    property bool isPaletteOpen: false

    FileDialog {
        id: wallpaperPicker
        title: "Choose wallpaper"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp)"]
        onAccepted: {
            WallpaperService.setWallpaper(selectedFile.toString());
        }
    }

    function openWallpaperPicker(): void {
        wallpaperPicker.open();
    }

    function open(): void {
        isOpen = true;
    }

    function close(): void {
        isOpen = false;
        isPaletteOpen = false;
    }

    function toggle(): void {
        isOpen = !isOpen;
        if (!isOpen)
            isPaletteOpen = false;
    }

    function openPalette(): void {
        isPaletteOpen = true;
    }

    function closePalette(): void {
        isPaletteOpen = false;
    }

    function setTab(tabIndex: int): void {
        currentTab = tabIndex;
    }

    function openNetwork(): void {
        currentTab = 3;
        open();
    }

    function setIdleLockTimeout(minutes: int): void {
        Config.setIdleLockTimeout(minutes);
    }

    function setFadeDuration(ms: int): void {
        Config.setFadeDuration(ms);
    }

    function setOpenMaximized(enabled: bool): void {
        Config.setOpenMaximized(enabled);
    }

    function setBorderEnabled(enabled: bool): void {
        Config.setBorderEnabled(enabled);
    }

    function setBorderWidth(width: int): void {
        Config.setBorderWidth(width);
    }

    function setFocusRingEnabled(enabled: bool): void {
        Config.setFocusRingEnabled(enabled);
    }

    function setFocusRingWidth(width: int): void {
        Config.setFocusRingWidth(width);
    }

    function setGaps(gaps: int): void {
        Config.setGaps(gaps);
    }

    property IpcHandler settingsIpc: IpcHandler {
        target: "settings"
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function openPalette(): void {
            root.openPalette();
        }
        function closePalette(): void {
            root.closePalette();
        }
        function setTab(tabIndex: int): void {
            root.setTab(tabIndex);
        }
        function openNetwork(): void {
            root.openNetwork();
        }
        function setIdleLockTimeout(minutes: int): void {
            root.setIdleLockTimeout(minutes);
        }
        function setFadeDuration(ms: int): void {
            root.setFadeDuration(ms);
        }
        function setOpenMaximized(enabled: bool): void {
            root.setOpenMaximized(enabled);
        }
        function setBorderEnabled(enabled: bool): void {
            root.setBorderEnabled(enabled);
        }
        function setBorderWidth(width: int): void {
            root.setBorderWidth(width);
        }
        function setFocusRingEnabled(enabled: bool): void {
            root.setFocusRingEnabled(enabled);
        }
        function setFocusRingWidth(width: int): void {
            root.setFocusRingWidth(width);
        }
        function setGaps(gaps: int): void {
            root.setGaps(gaps);
        }
        function getGaps(): int {
            return Config.gaps;
        }
        function isOpen(): bool {
            return root.isOpen;
        }
    }
}
