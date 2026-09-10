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
    }

    function toggle(): void {
        isOpen = !isOpen;
    }

    function setTab(tabIndex: int): void {
        currentTab = tabIndex;
    }

    function setIdleLockTimeout(minutes: int): void {
        Config.setIdleLockTimeout(minutes);
    }

    function setFadeDuration(ms: int): void {
        Config.setFadeDuration(ms);
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
        function setTab(tabIndex: int): void {
            root.setTab(tabIndex);
        }
        function setIdleLockTimeout(minutes: int): void {
            root.setIdleLockTimeout(minutes);
        }
        function setFadeDuration(ms: int): void {
            root.setFadeDuration(ms);
        }
        function isOpen(): bool {
            return root.isOpen;
        }
    }
}
