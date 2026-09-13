pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property real volume: 0.5
    property bool isMuted: false

    // Debounce rapid event bursts (e.g. holding down volume keys)
    property Timer fetchDebounceTimer: Timer {
        interval: 35
        repeat: false
        onTriggered: {
            if (!root.audioStatusProc.running) {
                root.audioStatusProc.running = true;
            }
        }
    }

    // Direct process without intermediate shell fork
    property Process audioStatusProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                const text = data.trim();
                if (!text)
                    return;

                const parts = text.split(/\s+/);
                if (parts.length >= 2) {
                    const vol = parseFloat(parts[1]);
                    if (!isNaN(vol)) {
                        root.volume = Math.min(1.0, Math.max(0.0, vol));
                    }
                }
                root.isMuted = text.includes("[MUTED]");
            }
        }
    }

    // Direct machine-parsable event subscription (no subshell, grep, or pipe buffering)
    property Process audioEventProc: Process {
        command: ["pactl", "-m", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("sink") || line.includes("server")) {
                    root.fetchDebounceTimer.restart();
                }
            }
        }
        onExited: () => {
            reconnectTimer.restart();
        }
    }

    // Auto-reconnect if PulseAudio/PipeWire daemon restarts
    property Timer reconnectTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: {
            if (!root.audioEventProc.running) {
                root.audioEventProc.running = true;
            }
            root.poll();
        }
    }

    function setVolume(val: real): void {
        const clamped = Math.max(0.0, Math.min(1.0, val));
        root.volume = clamped;
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", Math.round(clamped * 100) + "%"]);
    }

    function adjustVolume(delta: real): void {
        setVolume(root.volume + delta);
    }

    function toggleMute(): void {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        root.fetchDebounceTimer.restart();
    }

    function poll(): void {
        if (!audioStatusProc.running) {
            audioStatusProc.running = true;
        }
    }

    property IpcHandler audioIpc: IpcHandler {
        target: "audio"

        function adjustVolume(delta: real): void {
            root.adjustVolume(delta);
        }

        function toggleMute(): void {
            root.toggleMute();
        }

        function setVolume(val: real): void {
            root.setVolume(val);
        }

        function getVolume(): real {
            return root.volume;
        }

        function isMuted(): bool {
            return root.isMuted;
        }

        function poll(): void {
            root.poll();
        }
    }

    Component.onCompleted: {
        root.poll();
    }
}
