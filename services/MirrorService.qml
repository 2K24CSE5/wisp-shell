pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

QtObject {
    id: root

    property bool hasWlMirror: false
    property bool isMirroring: false
    property var outputs: []
    property string focusedOutput: ""
    property string sourceOutput: ""
    property string targetOutput: ""
    property bool fullscreen: true
    property string scaling: "fit"
    property bool copiedCommand: false

    readonly property bool hasExternalDisplay: root.outputs.some(o => o.isExternal)

    readonly property var sourceOptions: {
        return root.outputs.map(o => ({
            label: o.label,
            value: o.name
        }));
    }

    readonly property var targetOptions: {
        return root.outputs.map(o => ({
            label: o.label,
            value: o.name
        }));
    }

    readonly property var scalingOptions: [
        { label: "Fit to screen", value: "fit" },
        { label: "Cover (crop to fill)", value: "cover" },
        { label: "Exact 1:1", value: "exact" }
    ]

    property Process pollProcess: Process {
        command: ["sh", "-c",
            "MIRROR_BIN=$(command -v wl-mirror || echo ''); " +
            "IS_RUNNING=$(pgrep -x wl-mirror >/dev/null && echo '1' || echo '0'); " +
            "OUTPUTS=$(niri msg -j outputs 2>/dev/null || echo '{}'); " +
            "FOCUSED=$(niri msg -j focused-output 2>/dev/null || echo '{}'); " +
            "printf '{\"installed\":%s,\"running\":%s,\"outputs\":%s,\"focused\":%s}\\n' " +
            "\"$([ -n \"$MIRROR_BIN\" ] && echo true || echo false)\" " +
            "\"$([ \"$IS_RUNNING\" = '1' ] && echo true || echo false)\" " +
            "\"$OUTPUTS\" " +
            "\"$FOCUSED\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    root.parseStatus(this.text.trim());
                }
            }
        }
    }

    function parseStatus(jsonText: string): void {
        try {
            const data = JSON.parse(jsonText);
            root.hasWlMirror = Boolean(data.installed);
            root.isMirroring = Boolean(data.running);

            if (data.focused && data.focused.name) {
                root.focusedOutput = data.focused.name;
            }

            const rawOutputs = data.outputs || {};
            const list = [];
            let defaultSrc = "";
            let defaultTgt = "";

            for (const k in rawOutputs) {
                const v = rawOutputs[k];
                const name = v.name || k;
                const make = v.make || "";
                const model = v.model || "";
                const modeIdx = v.current_mode || 0;
                const modes = v.modes || [];
                const mode = (modes.length > modeIdx) ? modes[modeIdx] : (modes[0] || {});
                const w = mode.width || 0;
                const h = mode.height || 0;
                const rr = mode.refresh_rate ? Math.round(mode.refresh_rate / 1000) : 60;
                const isInternal = name.startsWith("eDP") || name.startsWith("LVDS");

                const item = {
                    name: name,
                    label: w > 0 ? (name + " (" + w + "x" + h + "@" + rr + "Hz)") : name,
                    description: (make || model) ? (make + " " + model).trim() : (isInternal ? "Built-in Display" : "External Display / Projector"),
                    isExternal: !isInternal,
                    width: w,
                    height: h,
                    refreshRate: rr
                };
                list.push(item);

                if (isInternal && !defaultSrc) {
                    defaultSrc = name;
                }
                if (!isInternal && !defaultTgt) {
                    defaultTgt = name;
                }
            }

            root.outputs = list;
            if (!defaultSrc && list.length > 0) defaultSrc = list[0].name;
            if (!defaultTgt && list.length > 1) defaultTgt = list[1].name;
            else if (!defaultTgt && list.length > 0) defaultTgt = list[0].name;

            if (!root.sourceOutput || !list.some(o => o.name === root.sourceOutput)) {
                root.sourceOutput = defaultSrc;
            }
            if (!root.targetOutput || !list.some(o => o.name === root.targetOutput)) {
                root.targetOutput = defaultTgt;
            }
        } catch (e) {
            console.warn("[MirrorService] Error parsing status:", e);
        }
    }

    function startMirroring(): void {
        if (!root.hasWlMirror) {
            return;
        }

        const src = root.sourceOutput || root.focusedOutput || (root.outputs.length > 0 ? root.outputs[0].name : "");
        if (!src) return;

        let tgt = root.targetOutput;
        if (!tgt) {
            const ext = root.outputs.find(o => o.isExternal);
            if (ext) tgt = ext.name;
        }

        const scale = root.scaling || "fit";

        if (root.fullscreen && tgt && tgt !== src) {
            Quickshell.execDetached(["wl-mirror", "--fullscreen-output", tgt, "-s", scale, src]);
        } else {
            Quickshell.execDetached(["wl-mirror", "-s", scale, src]);
        }

        quickPollTimer.restart();
    }

    function stopMirroring(): void {
        Quickshell.execDetached(["pkill", "-x", "wl-mirror"]);
        quickPollTimer.restart();
    }

    function toggleMirroring(): void {
        if (root.isMirroring) {
            root.stopMirroring();
        } else {
            root.startMirroring();
        }
    }

    function setSourceOutput(outputName: string): void {
        root.sourceOutput = outputName;
    }

    function setTargetOutput(outputName: string): void {
        root.targetOutput = outputName;
    }

    function setFullscreen(enabled: bool): void {
        root.fullscreen = enabled;
    }

    function setScaling(mode: string): void {
        root.scaling = mode;
    }

    function copyInstallCommand(): void {
        Quickshell.execDetached(["wl-copy", "sudo dnf install -y wl-mirror"]);
        root.copiedCommand = true;
        copiedTimer.restart();
    }

    function poll(): void {
        if (!root.pollProcess.running) {
            root.pollProcess.running = true;
        }
    }

    property Timer pollTimer: Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.poll()
    }

    property Timer quickPollTimer: Timer {
        interval: 250
        repeat: false
        onTriggered: root.poll()
    }

    property Timer copiedTimer: Timer {
        interval: 2500
        repeat: false
        onTriggered: root.copiedCommand = false
    }

    property Connections screenConn: Connections {
        target: Quickshell
        function onScreensChanged(): void {
            root.poll();
        }
    }

    property IpcHandler mirrorIpc: IpcHandler {
        target: "mirror"
        function toggle(): void {
            root.toggleMirroring();
        }
        function start(): void {
            root.startMirroring();
        }
        function stop(): void {
            root.stopMirroring();
        }
        function isMirroring(): bool {
            return root.isMirroring;
        }
    }

    Component.onCompleted: {
        root.poll();
    }
}
