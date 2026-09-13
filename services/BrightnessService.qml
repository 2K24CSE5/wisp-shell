pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property real brightness: 0.8
    property string backlightPath: ""
    property real maxBrightness: 1.0

    // 1. One-time hardware backlight discovery
    property Process findDeviceProc: Process {
        command: ["sh", "-c", "ls -d /sys/class/backlight/* 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text ? this.text.trim() : "";
                if (dev.length > 0) {
                    root.backlightPath = dev;
                    if (!root.fetchMaxProc.running) {
                        root.fetchMaxProc.running = true;
                    }
                } else {
                    root.poll();
                }
            }
        }
    }

    // 2. Fetch max brightness value once (since it does not change at runtime)
    property Process fetchMaxProc: Process {
        command: ["cat", root.backlightPath + "/max_brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseFloat((this.text || "").trim());
                if (!isNaN(val) && val > 0) {
                    root.maxBrightness = val;
                }
                root.poll();
            }
        }
    }

    // 3. Debounce rapid udev bursts (e.g. holding down hardware brightness keys)
    property Timer fetchDebounceTimer: Timer {
        interval: 30
        repeat: false
        onTriggered: {
            if (!root.brightStatusProc.running) {
                root.brightStatusProc.running = true;
            }
        }
    }

    // 4. Lightweight status poller: uses direct file read when sysfs is known, brightnessctl as fallback
    property Process brightStatusProc: Process {
        command: root.backlightPath.length > 0 ? ["cat", root.backlightPath + "/actual_brightness"] : ["sh", "-c", "brightnessctl -m i 2>/dev/null | awk -F, '{gsub(\"%\",\"\",$4); printf \"%.2f\", $4/100}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = (this.text || "").trim();
                if (!raw)
                    return;

                if (root.backlightPath.length > 0) {
                    const cur = parseFloat(raw);
                    if (!isNaN(cur) && root.maxBrightness > 0) {
                        root.brightness = Math.min(1.0, Math.max(0.0, cur / root.maxBrightness));
                    }
                } else {
                    const val = parseFloat(raw);
                    if (!isNaN(val) && val >= 0.0) {
                        root.brightness = Math.min(1.0, Math.max(0.0, val));
                    }
                }
            }
        }
    }

    // 5. Zero-latency kernel backlight udev listener with auto-restart
    property Process brightnessEventProc: Process {
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        running: true
        stdout: SplitParser {
            onRead: _line => {
                root.fetchDebounceTimer.restart();
            }
        }
        onExited: () => reconnectTimer.restart()
    }

    property Timer reconnectTimer: Timer {
        interval: 2000
        repeat: false
        onTriggered: {
            if (!root.brightnessEventProc.running) {
                root.brightnessEventProc.running = true;
            }
            root.poll();
        }
    }

    function setBrightness(val: real): void {
        const clamped = Math.max(0.0, Math.min(1.0, val));
        root.brightness = clamped;
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(clamped * 100) + "%"]);
    }

    function adjustBrightness(delta: real): void {
        setBrightness(root.brightness + delta);
    }

    function poll(): void {
        if (!brightStatusProc.running) {
            brightStatusProc.running = true;
        }
    }

    property IpcHandler brightnessIpc: IpcHandler {
        target: "brightness"

        function adjustBrightness(delta: real): void {
            root.adjustBrightness(delta);
        }

        function setBrightness(val: real): void {
            root.setBrightness(val);
        }

        function getBrightness(): real {
            return root.brightness;
        }

        function poll(): void {
            root.poll();
        }
    }

    Component.onCompleted: {
        findDeviceProc.running = true;
    }
}
