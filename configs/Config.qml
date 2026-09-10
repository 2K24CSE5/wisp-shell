pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: config

    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    property string targetUser: ""
    property string targetHome: homeDir
    readonly property string configDir: targetHome + "/.config/wisp-shell"
    readonly property string configPath: configDir + "/settings.json"

    property var settings: ({
            wallpaper: "",
            radius: 12,
            iconFont: "Material Symbols Rounded",
            textFont: "Inter",
            idleLockTimeout: 0,
            fadeDuration: 1000,
            selectedSession: ""
        })

    readonly property string wallpaper: settings.wallpaper
    readonly property int radius: settings.radius
    readonly property string iconFont: settings.iconFont
    readonly property string textFont: settings.textFont
    readonly property int idleLockTimeout: Math.max(0, Number(settings.idleLockTimeout) || 0)
    readonly property int fadeDuration: Math.max(300, Number(settings.fadeDuration) || 1000)
    readonly property string selectedSession: settings.selectedSession || ""

    Process {
        id: initProcess
        command: ["sh", "-c", "mkdir -p '" + config.configDir + "' && " + "if [ ! -f '" + config.configPath + "' ]; then " + "  echo '{\"wallpaper\": \"\", \"radius\": 12, \"iconFont\": \"Material Symbols Rounded\", \"textFont\": \"Inter\", \"idleLockTimeout\": 0, \"fadeDuration\": 1000, \"selectedSession\": \"\"}' > '" + config.configPath + "'; " + "fi"]
        running: true
        onExited: exitCode => {
            if (exitCode === 0) {
                fileView.reload();
            }
        }
    }

    Process {
        id: writeProcess
        onExited: exitCode => {
            if (exitCode === 0) {
                fileView.reload();
            } else {
                console.error("[Config] Error writing settings.json:", exitCode);
            }
        }
    }

    FileView {
        id: fileView
        path: config.configPath
        onLoaded: {
            config.load();
        }
        onPathChanged: {
            config.load();
        }
    }

    Process {
        id: userProcess
        command: ["sh", "-c", "getent passwd | awk -F: '$3 >= 1000 && $6 ~ /^\\/home\\// && $7 !~ /(nologin|false)$/ {print $1 \"|\" $6; exit}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|");
                if (parts.length === 2 && parts[0] && parts[1]) {
                    config.targetUser = parts[0];
                    config.targetHome = parts[1];
                }
            }
        }
        running: true
    }

    function load(): void {
        const text = fileView.text();
        if (!text || text.trim() === "")
            return;
        try {
            const parsed = JSON.parse(text);
            settings = Object.assign({}, settings, parsed);
        } catch (e) {
            console.warn("[Config] Failed parsing settings.json:", e);
        }
    }

    function setWallpaper(path: string): void {
        const updated = Object.assign({}, settings);
        updated.wallpaper = path;
        settings = updated;
        save();
    }

    function setRadius(value: int): void {
        const updated = Object.assign({}, settings);
        updated.radius = value;
        settings = updated;
        save();
    }

    function setIconFont(fontName: string): void {
        const updated = Object.assign({}, settings);
        updated.iconFont = fontName;
        settings = updated;
        save();
    }

    function setTextFont(fontName: string): void {
        const updated = Object.assign({}, settings);
        updated.textFont = fontName;
        settings = updated;
        save();
    }

    function setIdleLockTimeout(minutes: int): void {
        const updated = Object.assign({}, settings);
        updated.idleLockTimeout = Math.max(0, minutes);
        settings = updated;
        save();
    }

    function setFadeDuration(ms: int): void {
        const updated = Object.assign({}, settings);
        updated.fadeDuration = Math.max(300, ms);
        settings = updated;
        save();
    }

    function setSelectedSession(sessionName: string): void {
        const updated = Object.assign({}, settings);
        updated.selectedSession = sessionName;
        settings = updated;
        save();
    }

    function save(): void {
        writeProcess.command = ["sh", "-c", "cat << 'EOF' > '" + config.configPath + "'\n" + JSON.stringify(settings, null, 2) + "\nEOF"];
        writeProcess.running = true;
    }

    property IpcHandler configIpc: IpcHandler {
        target: "config"
        function setRadius(val: int): void {
            config.setRadius(val);
        }
        function getRadius(): int {
            return config.radius;
        }
        function setIconFont(val: string): void {
            config.setIconFont(val);
        }
        function setTextFont(val: string): void {
            config.setTextFont(val);
        }
        function setFadeDuration(val: int): void {
            config.setFadeDuration(val);
        }
    }
}
