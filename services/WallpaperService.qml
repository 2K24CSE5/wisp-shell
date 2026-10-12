pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configs
import qs.services

Singleton {
    id: service

    readonly property var _matugen: MatugenService

    property string currentWallpaper: Config.wallpaper
    property int revision: 0
    readonly property bool hasWallpaper: currentWallpaper !== ""
    readonly property string imageSource: hasWallpaper ? currentWallpaper + "?rev=" + revision : ""
    readonly property string wallpaperPath: Config.configDir + "/wallpaper.jpg"

    property string pendingWallpaper: ""
    property string copyingWallpaper: ""

    Component.onCompleted: {
        if (Config.loaded && Config.wallpaper === "") {
            restoreProcess.running = true;
        }
    }

    Process {
        id: restoreProcess
        command: ["test", "-f", service.cleanFilePath(service.wallpaperPath)]

        onExited: exitCode => {
            if (exitCode === 0 && Config.wallpaper === "") {
                const restoredPath = service.formatPath(service.wallpaperPath);
                service.currentWallpaper = restoredPath;
                service.revision++;
                Config.setWallpaper(restoredPath);
            }
        }
    }

    Process {
        id: clearProcess
        command: ["rm", "-f", service.cleanFilePath(service.wallpaperPath)]
    }

    Process {
        id: copyProcess

        onExited: exitCode => {
            const copiedTarget = service.copyingWallpaper;
            service.copyingWallpaper = "";

            if (exitCode === 0) {
                const copiedPath = service.formatPath(service.wallpaperPath);

                // Update properties atomically without zeroing out to prevent blank frame flashes
                service.currentWallpaper = copiedPath;
                service.revision++;

                // Persist to configuration and trigger Matugen
                if (Config.wallpaper !== copiedPath && typeof Config.setWallpaper === "function") {
                    Config.setWallpaper(copiedPath);
                }
                service._matugen.generateColors(copiedPath);
            } else {
                console.warn("[WallpaperService] Failed to copy wallpaper:", copiedTarget);
            }

            // Process queued wallpaper if selection changed while copying
            if (service.pendingWallpaper && service.pendingWallpaper !== copiedTarget) {
                const next = service.pendingWallpaper;
                service.pendingWallpaper = "";
                service.copyWallpaper(next);
            } else {
                service.pendingWallpaper = "";
            }
        }
    }

    Connections {
        target: Config
        function onWallpaperChanged(): void {
            if (Config.wallpaper !== service.currentWallpaper) {
                service.copyWallpaper(Config.wallpaper);
            }
        }

        function onTargetHomeChanged(): void {
            service.copyWallpaper(Config.wallpaper);
        }

        function onLoadedChanged(): void {
            if (Config.loaded && Config.wallpaper === "") {
                restoreProcess.running = true;
            }
        }
    }

    function cleanFilePath(path: string): string {
        if (!path)
            return "";
        let clean = path.trim();
        if (clean.startsWith("file://")) {
            clean = clean.slice(7);
        }
        try {
            clean = decodeURIComponent(clean);
        } catch (_) {}
        return clean;
    }

    function formatPath(path: string): string {
        if (!path || path.trim() === "")
            return "";
        if (path.startsWith("file://") || path.startsWith("http://") || path.startsWith("https://")) {
            return path;
        }
        return "file://" + path;
    }

    function copyWallpaper(path: string): void {
        if (!path || !Config.targetHome || Config.targetHome.startsWith("/var/lib") || Config.targetHome === "/root")
            return;

        const formatted = formatPath(path);
        if (!formatted || !formatted.startsWith("file://")) {
            currentWallpaper = formatted;
            if (formatted && typeof Config.setWallpaper === "function" && Config.wallpaper !== formatted)
                Config.setWallpaper(formatted);
            return;
        }

        const rawSource = cleanFilePath(formatted);
        const rawDest = cleanFilePath(wallpaperPath);

        if (rawSource === rawDest) {
            currentWallpaper = formatted;
            revision++;
            return;
        }

        if (copyProcess.running) {
            pendingWallpaper = formatted;
            return;
        }

        copyingWallpaper = formatted;
        copyProcess.command = ["install", "-D", "-m", "0644", rawSource, rawDest];
        copyProcess.running = true;
    }

    function setWallpaper(path: string): void {
        copyWallpaper(path);
    }

    function clear(): void {
        currentWallpaper = "";
        if (typeof Config.setWallpaper === "function") {
            Config.setWallpaper("");
        }
        clearProcess.running = true;
    }

    property IpcHandler wallpaperIpc: IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            service.setWallpaper(path);
        }

        function clear(): void {
            service.clear();
        }

        function get(): string {
            return service.currentWallpaper;
        }
    }
}
