pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configs

Singleton {
    id: config

    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    property string targetUser: ""
    property string targetHome: homeDir
    readonly property string configDir: targetHome + "/.config/wisp-shell"
    readonly property string configPath: configDir + "/settings.json"
    property bool loaded: false

    property var settings: ({
            wallpaper: "",
            radius: 12,
            borderEnabled: false,
            borderWidth: 4,
            focusRingEnabled: false,
            focusRingWidth: 4,
            gaps: 16,
            iconFont: "Material Symbols Rounded",
            textFont: "Inter",
            idleLockTimeout: 0,
            fadeDuration: 1000,
            lockOnLidClose: false,
            fadeToMonitorOff: true,
            selectedSession: "",
            openMaximized: false
        })

    readonly property string wallpaper: settings.wallpaper
    readonly property int radius: settings.radius
    readonly property bool borderEnabled: settings.borderEnabled === true
    readonly property int borderWidth: Math.max(1, Number(settings.borderWidth) || 4)
    readonly property bool focusRingEnabled: settings.focusRingEnabled === true
    readonly property int focusRingWidth: Math.max(1, Number(settings.focusRingWidth) || 4)
    readonly property int gaps: settings.gaps !== undefined ? Math.max(0, Number(settings.gaps)) : 16
    readonly property string iconFont: settings.iconFont
    readonly property string textFont: settings.textFont
    readonly property int idleLockTimeout: Math.max(0, Number(settings.idleLockTimeout) || 0)
    readonly property int fadeDuration: Math.max(300, Number(settings.fadeDuration) || 1000)
    readonly property bool lockOnLidClose: settings.lockOnLidClose === true
    readonly property bool fadeToMonitorOff: settings.fadeToMonitorOff !== false
    readonly property string selectedSession: settings.selectedSession || ""
    readonly property bool openMaximized: settings.openMaximized === true

    function ensureConfig(): void {
        if (!config.targetHome || config.targetHome.startsWith("/var/lib") || config.targetHome === "/root")
            return;
        initProcess.command = ["sh", "-c", "mkdir -p '" + config.configDir + "' && " +
            "if [ ! -f '" + config.configPath + "' ]; then " +
            "  echo '{\"wallpaper\": \"\", \"radius\": 12, \"borderEnabled\": false, \"borderWidth\": 4, \"focusRingEnabled\": false, \"focusRingWidth\": 4, \"gaps\": 16, \"iconFont\": \"Material Symbols Rounded\", \"textFont\": \"Inter\", \"idleLockTimeout\": 0, \"fadeDuration\": 1000, \"lockOnLidClose\": false, \"fadeToMonitorOff\": true, \"selectedSession\": \"\", \"openMaximized\": false}' > '" + config.configPath + "'; " +
            "fi && chmod 0666 '" + config.configPath + "' && " +
            "rm -f '" + config.configDir + "/niri.kdl'"
        ];
        initProcess.running = true;
    }

    Process {
        id: initProcess
        running: false
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
            config.loaded = true;
            config.syncNiriConfig();
        }
        onPathChanged: {
            config.load();
            config.loaded = true;
            config.syncNiriConfig();
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
                    config.ensureConfig();
                }
            }
        }
        running: true
    }

    Component.onCompleted: {
        config.ensureConfig();
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
        syncNiriConfig();
    }

    function setBorderEnabled(enabled: bool): void {
        const updated = Object.assign({}, settings);
        updated.borderEnabled = enabled;
        settings = updated;
        save();
        syncNiriConfig();
    }

    function setBorderWidth(value: int): void {
        const updated = Object.assign({}, settings);
        updated.borderWidth = Math.max(1, value);
        settings = updated;
        save();
        syncNiriConfig();
    }

    function setFocusRingEnabled(enabled: bool): void {
        const updated = Object.assign({}, settings);
        updated.focusRingEnabled = enabled;
        settings = updated;
        save();
        syncNiriConfig();
    }

    function setFocusRingWidth(value: int): void {
        const updated = Object.assign({}, settings);
        updated.focusRingWidth = Math.max(1, value);
        settings = updated;
        save();
        syncNiriConfig();
    }

    function setGaps(value: int): void {
        const updated = Object.assign({}, settings);
        updated.gaps = Math.max(0, value);
        settings = updated;
        save();
        syncNiriConfig();
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

    function setLockOnLidClose(enabled: bool): void {
        const updated = Object.assign({}, settings);
        updated.lockOnLidClose = enabled;
        settings = updated;
        save();
    }

    function setFadeToMonitorOff(enabled: bool): void {
        const updated = Object.assign({}, settings);
        updated.fadeToMonitorOff = enabled;
        settings = updated;
        save();
    }

    function setSelectedSession(sessionName: string): void {
        const updated = Object.assign({}, settings);
        updated.selectedSession = sessionName;
        settings = updated;
        save();
    }

    function setOpenMaximized(enabled: bool): void {
        const updated = Object.assign({}, settings);
        updated.openMaximized = enabled;
        settings = updated;
        save();
        syncNiriConfig();
    }

    Connections {
        target: Color
        function onRevisionChanged(): void {
            config.syncNiriConfig();
        }
        function onIsDarkChanged(): void {
            config.syncNiriConfig();
        }
    }

    function syncNiriConfig(): void {
        if (!config.targetHome || config.targetHome.startsWith("/var/lib") || config.targetHome === "/root")
            return;

        let activeColor = "#85d6c0";
        let inactiveColor = "#3f4945";
        let urgentColor = "#ffb4ab";
        try {
            if (typeof Color !== "undefined" && Color) {
                activeColor = Color.getColor("primary") || activeColor;
                inactiveColor = Color.getColor("subtle") || inactiveColor;
                urgentColor = Color.getColor("error") || urgentColor;
            }
        } catch (_) {}

        const winRadius = Math.max(0, Number(config.radius) || 12);
        const bWidth = Math.max(1, Number(config.borderWidth) || 4);
        const fWidth = Math.max(1, Number(config.focusRingWidth) || 4);
        const winGaps = Math.max(0, config.gaps !== undefined ? Number(config.gaps) : 16);
        const isBorder = (config.borderEnabled === true) || (config.settings && config.settings.borderEnabled === true);
        const isFocusRing = (config.focusRingEnabled === true) || (config.settings && config.settings.focusRingEnabled === true);

        let focusRingKdl = "";
        if (isFocusRing) {
            focusRingKdl = "    focus-ring {\n" +
                "        on\n" +
                "        width " + fWidth + "\n" +
                "        active-color \"" + activeColor + "\"\n" +
                "        inactive-color \"" + inactiveColor + "\"\n" +
                "    }\n\n";
        } else {
            focusRingKdl = "    focus-ring {\n" +
                "        off\n" +
                "        active-color \"" + activeColor + "\"\n" +
                "        inactive-color \"" + inactiveColor + "\"\n" +
                "    }\n\n";
        }

        let borderKdl = "";
        if (isBorder) {
            borderKdl = "    border {\n" +
                "        on\n" +
                "        width " + bWidth + "\n" +
                "        active-color \"" + activeColor + "\"\n" +
                "        inactive-color \"" + inactiveColor + "\"\n" +
                "    }\n";
        } else {
            borderKdl = "    border {\n" +
                "        off\n" +
                "        active-color \"" + activeColor + "\"\n" +
                "        inactive-color \"" + inactiveColor + "\"\n" +
                "    }\n";
        }

        let kdl = "// ==============================================================================\n" +
            "//  Wisp Shell — Niri Compositor Configuration\n" +
            "//  https://github.com/physteorts/wisp-shell\n" +
            "// ==============================================================================\n\n" +
            "spawn-sh-at-startup \"quickshell -p ~/.config/quickshell/wisp-shell\"\n" +
            "prefer-no-csd\n\n" +
            "hotkey-overlay {\n" +
            "    skip-at-startup\n" +
            "}\n\n" +
            "layout {\n" +
            "    gaps " + winGaps + "\n" +
            "    background-color \"transparent\"\n\n" +
            focusRingKdl +
            borderKdl +
            "}\n\n" +
            "layer-rule {\n" +
            "    match namespace=\"^quickshell-wallpaper$\"\n" +
            "    place-within-backdrop true\n" +
            "}\n\n" +
            "layer-rule {\n" +
            "    match namespace=\"^wisp-lockscreen$\"\n" +
            "    block-out-from \"screen-capture\"\n" +
            "}\n\n" +
            "overview {\n" +
            "    workspace-shadow {\n" +
            "        off\n" +
            "    }\n" +
            "}\n\n" +
            "recent-windows {\n" +
            "    highlight {\n" +
            "        active-color \"" + activeColor + "\"\n" +
            "        urgent-color \"" + urgentColor + "\"\n" +
            "        corner-radius " + winRadius + "\n" +
            "    }\n" +
            "}\n\n" +
            "window-rule {\n" +
            "    geometry-corner-radius " + winRadius + "\n" +
            "    clip-to-geometry true\n" +
            "}\n\n";

        if (config.openMaximized) {
            kdl += "window-rule {\n" +
                "    open-maximized true\n" +
                "}\n\n";
        }

        kdl += "binds {\n" +
            "    Mod+S hotkey-overlay-title=\"Toggle Wisp Shell Settings\" {\n" +
            "        spawn-sh \"quickshell -c wisp-shell ipc call settings toggle\"\n" +
            "    }\n\n" +
            "    Mod+T hotkey-overlay-title=\"Open a Terminal: ghostty\" {\n" +
            "        spawn \"ghostty\"\n" +
            "    }\n" +
            "}\n";

        const niriTarget = config.targetHome + "/.config/niri/wisp-shell.kdl";
        const repoTarget = config.targetHome + "/.config/quickshell/wisp-shell/configs/wisp-shell.kdl";

        const script = "mkdir -p '" + config.targetHome + "/.config/niri' && " +
            "cat << 'EOF' > '" + niriTarget + "'\n" + kdl + "EOF\n" +
            "if [ -d '" + config.targetHome + "/.config/quickshell/wisp-shell/configs' ]; then " +
            "  cat << 'EOF' > '" + repoTarget + "'\n" + kdl + "EOF\n" +
            "fi\n" +
            "rm -f '" + config.configDir + "/niri.kdl'\n" +
            "if command -v niri >/dev/null 2>&1; then " +
            "  niri msg action load-config-file 2>/dev/null || true\n" +
            "fi\n";

        Quickshell.execDetached(["sh", "-c", script]);
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
        function setLockOnLidClose(val: bool): void {
            config.setLockOnLidClose(val);
        }
        function setFadeToMonitorOff(val: bool): void {
            config.setFadeToMonitorOff(val);
        }
        function setOpenMaximized(val: bool): void {
            config.setOpenMaximized(val);
        }
        function getOpenMaximized(): bool {
            return config.openMaximized;
        }
        function setBorderEnabled(val: bool): void {
            config.setBorderEnabled(val);
        }
        function getBorderEnabled(): bool {
            return config.borderEnabled;
        }
        function setBorderWidth(val: int): void {
            config.setBorderWidth(val);
        }
        function getBorderWidth(): int {
            return config.borderWidth;
        }
        function setFocusRingEnabled(val: bool): void {
            config.setFocusRingEnabled(val);
        }
        function getFocusRingEnabled(): bool {
            return config.focusRingEnabled;
        }
        function setFocusRingWidth(val: int): void {
            config.setFocusRingWidth(val);
        }
        function getFocusRingWidth(): int {
            return config.focusRingWidth;
        }
        function setGaps(val: int): void {
            config.setGaps(val);
        }
        function getGaps(): int {
            return config.gaps;
        }
    }
}
