pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // --- Public Properties ---
    property int percentage: 100
    property bool isCharging: false
    property bool hasBattery: true

    property string statusText: "DISCHARGING"
    property string timeRemaining: ""
    property real health: 100.0
    property int cycleCount: 0
    property real powerDraw: 0.0
    property real voltage: 0.0

    property string activeProfile: "balanced"
    property string batteryDevicePath: "/org/freedesktop/UPower/devices/DisplayDevice"

    // 1. Discover physical battery path to access hardware voltage/health
    property Process findDeviceProc: Process {
        command: ["sh", "-c", "upower -e | grep -E 'battery_BAT|battery' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const target = this.text ? this.text.trim() : "";
                if (target.length > 0) {
                    root.batteryDevicePath = target;
                    root.hasBattery = true;
                } else {
                    root.hasBattery = false;
                }
                root.refreshAll();
            }
        }
    }

    // 2. Snapshot Fetcher for Battery Device
    property Process upowerDumpProc: Process {
        command: ["upower", "-i", root.batteryDevicePath]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    root.parseUpowerDump(this.text);
                }
            }
        }
    }

    // 3. Direct Hardware Sysfs Reader for Cycle Count
    property Process cycleCountProc: Process {
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/cycle_count 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    const c = parseInt(this.text.trim(), 10);
                    if (!isNaN(c) && c > 0) {
                        root.cycleCount = c;
                    }
                }
            }
        }
    }

    // 4. Persistent DBus Event Monitor
    property Process dBusMonitorProc: Process {
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.UPower"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("PropertiesChanged") || line.includes("Changed")) {
                    updateDebounceTimer.restart();
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                reconnectTimer.interval = 5000;
            }
            reconnectTimer.restart();
        }
    }

    // 5. Power Profiles Monitor
    property Process profileMonitorProc: Process {
        command: ["gdbus", "monitor", "--system", "--dest", "net.hadess.PowerProfiles"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("ActiveProfile") || line.includes("PropertiesChanged")) {
                    if (!root.profileFetchProc.running)
                        root.profileFetchProc.running = true;
                }
            }
        }
    }

    // 6. Power Profiles Active State Fetcher
    property Process profileFetchProc: Process {
        command: ["gdbus", "call", "--system", "--dest", "net.hadess.PowerProfiles", "--object-path", "/net/hadess/PowerProfiles", "--method", "org.freedesktop.DBus.Properties.Get", "net.hadess.PowerProfiles", "ActiveProfile"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text)
                    return;
                const match = this.text.match(/'([^']+)'/);
                if (match && match[1] && match[1] !== root.activeProfile) {
                    root.activeProfile = match[1];
                }
            }
        }
    }

    property Timer updateDebounceTimer: Timer {
        interval: 150
        repeat: false
        onTriggered: {
            if (!root.upowerDumpProc.running)
                root.upowerDumpProc.running = true;
        }
    }

    property Timer reconnectTimer: Timer {
        interval: 2000
        repeat: false
        onTriggered: {
            if (!root.dBusMonitorProc.running)
                root.dBusMonitorProc.running = true;
            if (!root.profileMonitorProc.running)
                root.profileMonitorProc.running = true;
            root.refreshAll();
        }
    }

    function parseUpowerDump(dump: string): void {
        let isPresent = root.hasBattery;
        let stateStr = "";
        let pct = NaN;
        let rate = NaN;
        let volt = NaN;
        let cap = NaN;
        let eFull = NaN;
        let eDesign = NaN;
        let cycles = NaN;
        let timeEmpty = "";
        let timeFull = "";

        const lines = dump.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;

            const colonIdx = line.indexOf(":");
            if (colonIdx === -1)
                continue;

            const key = line.slice(0, colonIdx).trim().toLowerCase();
            const val = line.slice(colonIdx + 1).trim();

            switch (key) {
            case "is-present":
            case "present":
                isPresent = (val === "yes");
                break;
            case "state":
                stateStr = val.toLowerCase();
                break;
            case "percentage":
                pct = parseFloat(val.replace("%", ""));
                break;
            case "energy-rate":
                rate = parseFloat(val.replace("W", ""));
                break;
            case "voltage":
                volt = parseFloat(val.replace("V", ""));
                break;
            case "capacity":
                cap = parseFloat(val.replace("%", ""));
                break;
            case "energy-full":
                eFull = parseFloat(val.replace("Wh", ""));
                break;
            case "energy-full-design":
                eDesign = parseFloat(val.replace("Wh", ""));
                break;
            case "cycle-count":
                cycles = parseInt(val, 10);
                break;
            case "time to empty":
                timeEmpty = val;
                break;
            case "time to full":
                timeFull = val;
                break;
            }
        }

        root.hasBattery = isPresent;
        if (!isNaN(pct))
            root.percentage = Math.round(pct);
        if (!isNaN(volt))
            root.voltage = Math.round(volt * 10) / 10;
        root.powerDraw = !isNaN(rate) ? Math.round(Math.abs(rate) * 10) / 10 : 0.0;

        // Prefer sysfs cycle count if already populated or UPower provided valid cycles
        if (!isNaN(cycles) && cycles > 0)
            root.cycleCount = cycles;

        if (!isNaN(cap)) {
            root.health = Math.min(100.0, Math.round(cap * 10) / 10);
        } else if (!isNaN(eFull) && !isNaN(eDesign) && eDesign > 0) {
            root.health = Math.min(100.0, Math.round((eFull / eDesign) * 1000) / 10);
        }

        const isChargingState = stateStr === "charging" || stateStr === "fully-charged";
        root.isCharging = isChargingState;

        if (stateStr === "charging") {
            root.statusText = "CHARGING";
            root.timeRemaining = timeFull ? timeFull.replace(/\s*\([^)]*\)/, "") : "";
        } else if (stateStr === "fully-charged") {
            root.statusText = "FULL";
            root.timeRemaining = "";
        } else if (stateStr === "discharging") {
            root.statusText = "DISCHARGING";
            root.timeRemaining = timeEmpty ? timeEmpty.replace(/\s*\([^)]*\)/, "") : "";
        } else {
            root.statusText = isChargingState ? "PLUGGED IN" : "DISCHARGING";
            root.timeRemaining = "";
        }
    }

    function setPowerProfile(profileName: string): void {
        Quickshell.execDetached(["gdbus", "call", "--system", "--dest", "net.hadess.PowerProfiles", "--object-path", "/net/hadess/PowerProfiles", "--method", "org.freedesktop.DBus.Properties.Set", "net.hadess.PowerProfiles", "ActiveProfile", "<'" + profileName + "'>"]);
        root.activeProfile = profileName;
    }

    function refreshAll(): void {
        if (!root.upowerDumpProc.running)
            root.upowerDumpProc.running = true;
        if (!root.profileFetchProc.running)
            root.profileFetchProc.running = true;
        if (!root.cycleCountProc.running)
            root.cycleCountProc.running = true;
    }

    function poll(): void {
        root.refreshAll();
    }

    Component.onCompleted: {
        findDeviceProc.running = true;
    }
}
