pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configs

Singleton {
    id: root

    readonly property string configDir: Config.configDir
    readonly property string configPath: configDir + "/colors.json"

    readonly property var darkPalette: ({
            background: "#0e1513",
            surface: "#171d1b",
            overlay: "#252b29",
            muted: "#89938f",
            subtle: "#3f4945",
            text: "#dee4e0",
            primary: "#85d6c0",
            secondary: "#b1ccc3",
            tertiary: "#aacbe3",
            warning: "#aacbe3",
            info: "#b1ccc3",
            error: "#ffb4ab"
        })

    readonly property var lightPalette: ({
            background: "#f5fbf7",
            surface: "#eff5f1",
            overlay: "#e3eae6",
            muted: "#6f7975",
            subtle: "#bfc9c4",
            text: "#171d1b",
            primary: "#0a6b5a",
            secondary: "#4b635c",
            tertiary: "#426277",
            warning: "#426277",
            info: "#4b635c",
            error: "#ba1a1a"
        })

    readonly property var presets: [
        {
            id: "default",
            name: "Default Emerald",
            dark: root.darkPalette,
            light: root.lightPalette
        },
        {
            id: "rose-pine",
            name: "Rosé Pine",
            dark: {
                background: "#191724",
                surface: "#1f1d2e",
                overlay: "#26233a",
                muted: "#6e6a86",
                subtle: "#908caa",
                text: "#e0def4",
                primary: "#ebbcba",
                secondary: "#31748f",
                tertiary: "#9ccfd8",
                warning: "#f6c177",
                info: "#9ccfd8",
                error: "#eb6f92"
            },
            light: {
                background: "#faf4ed",
                surface: "#fffaf3",
                overlay: "#f2e9e1",
                muted: "#9893a5",
                subtle: "#797593",
                text: "#575279",
                primary: "#d7827e",
                secondary: "#286983",
                tertiary: "#56949f",
                warning: "#ea9d34",
                info: "#56949f",
                error: "#b4637a"
            }
        },
        {
            id: "catppuccin",
            name: "Catppuccin",
            dark: {
                background: "#1e1e2e",
                surface: "#181825",
                overlay: "#313244",
                muted: "#6c7086",
                subtle: "#a6adc8",
                text: "#cdd6f4",
                primary: "#cba6f7",
                secondary: "#89b4fa",
                tertiary: "#f5c2e7",
                warning: "#f9e2af",
                info: "#89dceb",
                error: "#f38ba8"
            },
            light: {
                background: "#eff1f5",
                surface: "#e6e9ef",
                overlay: "#ccd0da",
                muted: "#8c8fa1",
                subtle: "#6c6f85",
                text: "#4c4f69",
                primary: "#8839ef",
                secondary: "#1e66f5",
                tertiary: "#ea76cb",
                warning: "#df8e1d",
                info: "#04a5e5",
                error: "#d20f39"
            }
        },
        {
            id: "nord",
            name: "Nord",
            dark: {
                background: "#2e3440",
                surface: "#3b4252",
                overlay: "#434c5e",
                muted: "#4c566a",
                subtle: "#d8dee9",
                text: "#eceff4",
                primary: "#88c0d0",
                secondary: "#81a1c1",
                tertiary: "#8fbcbb",
                warning: "#ebcb8b",
                info: "#5e81ac",
                error: "#bf616a"
            },
            light: {
                background: "#eceff4",
                surface: "#e5e9f0",
                overlay: "#d8dee9",
                muted: "#4c566a",
                subtle: "#3b4252",
                text: "#2e3440",
                primary: "#5e81ac",
                secondary: "#81a1c1",
                tertiary: "#88c0d0",
                warning: "#d08770",
                info: "#88c0d0",
                error: "#bf616a"
            }
        }
    ]

    property bool isDark: true
    property bool isDynamicPalette: true
    property string activePreset: "default"
    property int revision: 0

    property var colorData: ({
            dark: darkPalette,
            light: lightPalette
        })

    readonly property var palette: {
        root.revision;
        return isDark ? colorData.dark : colorData.light;
    }

    function getColor(key) {
        root.revision;
        return palette?.[key] ?? "#000000";
    }

    readonly property color background: getColor("background")
    readonly property color surface: getColor("surface")
    readonly property color overlay: getColor("overlay")
    readonly property color muted: getColor("muted")
    readonly property color subtle: getColor("subtle")
    readonly property color text: getColor("text")
    readonly property color primary: getColor("primary")
    readonly property color secondary: getColor("secondary")
    readonly property color tertiary: getColor("tertiary")
    readonly property color warning: getColor("warning")
    readonly property color info: getColor("info")
    readonly property color error: getColor("error")

    Process {
        id: initProcess
        command: ["sh", "-c", "mkdir -p '" + root.configDir + "' && " + "if [ ! -f '" + root.configPath + "' ]; then " + "  cat << 'EOF' > '" + root.configPath + "'\n" + JSON.stringify({
                isDark: root.isDark,
                isDynamicPalette: root.isDynamicPalette,
                activePreset: root.activePreset,
                dark: root.darkPalette,
                light: root.lightPalette
            }, null, 2) + "\nEOF\n" + "fi"]
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
            if (exitCode !== 0) {
                console.error("[Color] Error writing colors.json:", exitCode);
            }
        }
    }

    FileView {
        id: fileView
        path: root.configPath
        onLoaded: root.load()
        onPathChanged: root.load()
    }

    function load() {
        const text = fileView.text();
        if (!text || text.trim() === "")
            return;
        try {
            const parsed = JSON.parse(text);
            if (typeof parsed.isDark === "boolean") {
                root.isDark = parsed.isDark;
            }
            if (typeof parsed.isDynamicPalette === "boolean") {
                root.isDynamicPalette = parsed.isDynamicPalette;
            }
            if (parsed.activePreset) {
                root.activePreset = parsed.activePreset;
            }
            if (parsed.dark || parsed.light) {
                colorData = {
                    dark: Object.assign({}, darkPalette, parsed.dark ?? {}),
                    light: Object.assign({}, lightPalette, parsed.light ?? {})
                };
                root.revision++;
            }
        } catch (e) {
            console.warn("[Color] Failed to parse colors.json:", e);
        }
    }

    function applyPreset(presetId) {
        const preset = presets.find(p => p.id === presetId);
        if (!preset)
            return;

        activePreset = preset.id;
        isDynamicPalette = false;
        colorData = {
            dark: Object.assign({}, preset.dark),
            light: Object.assign({}, preset.light)
        };
        root.revision++;
        save();
    }

    function updatePalette(newPaletteData, saveToFile) {
        if (!newPaletteData)
            return;
        if (saveToFile === undefined) {
            saveToFile = true;
        }
        colorData = {
            dark: Object.assign({}, colorData.dark, newPaletteData.dark ?? {}),
            light: Object.assign({}, colorData.light, newPaletteData.light ?? {})
        };
        root.revision++;
        if (saveToFile) {
            save();
        }
    }

    function setColor(key, value) {
        const mode = isDark ? "dark" : "light";
        const updated = Object.assign({}, colorData);
        const modeCopy = Object.assign({}, updated[mode]);
        modeCopy[key] = value;
        updated[mode] = modeCopy;
        colorData = updated;
        isDynamicPalette = false;
        activePreset = "custom";
        root.revision++;
        save();
    }

    function setDark(dark) {
        if (root.isDark !== dark) {
            root.isDark = dark;
            root.revision++;
            save();
        }
    }

    function setDynamic(dynamic) {
        if (root.isDynamicPalette !== dynamic) {
            root.isDynamicPalette = dynamic;
            save();
        }
    }

    function save() {
        const payload = {
            isDark: root.isDark,
            isDynamicPalette: root.isDynamicPalette,
            activePreset: root.activePreset,
            dark: colorData.dark,
            light: colorData.light
        };
        writeProcess.command = ["sh", "-c", "cat << 'EOF' > '" + root.configPath + "'\n" + JSON.stringify(payload, null, 2) + "\nEOF"];
        writeProcess.running = true;
    }

    property IpcHandler colorIpc: IpcHandler {
        target: "color"
        function set(key: string, val: string): void {
            root.setColor(key, val);
        }
        function get(key: string): string {
            return root.palette[key] ?? "";
        }
        function toggleMode(): void {
            root.setDark(!root.isDark);
        }
        function setDarkMode(val: bool): void {
            root.setDark(val);
        }
        function setDynamic(val: bool): void {
            root.setDynamic(val);
        }
    }
}
