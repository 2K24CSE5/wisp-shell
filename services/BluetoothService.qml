pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: false
    property bool connected: false
    property string connectedDeviceName: ""
    property int connectedDeviceBattery: -1
    property string lastConnectedAddress: ""
    property var devices: []

    // 1. Debounce rapid DBus property change events
    property Timer updateDebounceTimer: Timer {
        interval: 80
        repeat: false
        onTriggered: root.refreshDevices()
    }

    // 2. Real-time BlueZ DBus Event Stream (0ms latency, zero repeated forks)
    property Process bluezMonitorProc: Process {
        command: ["gdbus", "monitor", "--system", "--dest", "org.bluez"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("Connected") || line.includes("Powered") || line.includes("Battery") || line.includes("InterfacesAdded") || line.includes("InterfacesRemoved")) {
                    root.updateDebounceTimer.restart();
                }
            }
        }
        onExited: () => reconnectTimer.restart()
    }

    property Timer reconnectTimer: Timer {
        interval: 2000
        repeat: false
        onTriggered: {
            if (!root.bluezMonitorProc.running) {
                root.bluezMonitorProc.running = true;
            }
            root.poll();
        }
    }

    // 3. Adapter Power Check
    property Process btShowProcess: Process {
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text || "";
                root.enabled = out.includes("Powered: yes");
            }
        }
    }

    // 4. Single-pass Python Device / Battery Extractor (replaces multiple subshells, sed, awk pipes)
    property Process btDevicesProcess: Process {
        command: ["python3", "-c", `
import subprocess, re, json

def clean_ansi(text):
    return re.sub(r'\\x1B\\[[0-9;]*[a-zA-Z]', '', text)

def run_cmd(cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=3)
        return clean_ansi(p.stdout)
    except Exception:
        return ""

all_devs_out = run_cmd(["bluetoothctl", "devices"])
conn_devs_out = run_cmd(["bluetoothctl", "devices", "Connected"])

connected_macs = set()
for line in conn_devs_out.splitlines():
    line = line.strip()
    if line.startswith("Device "):
        parts = line.split(" ", 2)
        if len(parts) >= 2:
            connected_macs.add(parts[1].strip())

devices = []
primary_name = ""
primary_addr = ""
primary_batt = -1

for line in all_devs_out.splitlines():
    line = line.strip()
    if not line.startswith("Device "):
        continue
    parts = line.split(" ", 2)
    if len(parts) < 3:
        continue
    mac = parts[1].strip()
    name = parts[2].strip()
    is_conn = mac in connected_macs

    batt = -1
    if is_conn:
        info = run_cmd(["bluetoothctl", "info", mac])
        m = re.search(r'Battery Percentage:\\s*.*?\\((\\d+)\\)', info)
        if m:
            batt = int(m.group(1))
        if not primary_name:
            primary_name = name
            primary_addr = mac
            primary_batt = batt

    devices.append({
        "address": mac,
        "name": name,
        "connected": is_conn,
        "battery": batt,
        "paired": True
    })

devices.sort(key=lambda d: (not d["connected"], d["name"].lower()))
print(json.dumps({
    "devices": devices,
    "connected": len(connected_macs) > 0,
    "primaryName": primary_name,
    "primaryAddr": primary_addr,
    "battery": primary_batt
}))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || !this.text.trim())
                    return;
                try {
                    const data = JSON.parse(this.text.trim());
                    root.devices = data.devices || [];
                    root.connected = Boolean(data.connected);
                    root.connectedDeviceName = data.primaryName || "";
                    root.connectedDeviceBattery = data.battery !== undefined ? data.battery : -1;
                    if (data.primaryAddr) {
                        root.lastConnectedAddress = data.primaryAddr;
                    }
                } catch (_) {}
            }
        }
    }

    // 5. Active Discovery Scan
    property Process btScanProcess: Process {
        command: ["bluetoothctl", "--timeout", "5", "scan", "on"]
        onExited: () => root.refreshDevices()
    }

    function refreshDevices(): void {
        if (!btShowProcess.running)
            btShowProcess.running = true;
        if (!btDevicesProcess.running)
            btDevicesProcess.running = true;
    }

    function togglePower(): void {
        const nextState = root.enabled ? "off" : "on";
        Quickshell.execDetached(["bluetoothctl", "power", nextState]);
        root.enabled = !root.enabled;
        if (!root.enabled) {
            root.connected = false;
            root.connectedDeviceName = "";
            root.connectedDeviceBattery = -1;
            root.devices = [];
        }
        updateDebounceTimer.restart();
    }

    function scan(): void {
        if (!root.enabled)
            return;
        if (!btScanProcess.running)
            btScanProcess.running = true;
    }

    function connectDevice(address: string): void {
        if (!address)
            return;
        Quickshell.execDetached(["sh", "-c", `bluetoothctl connect "${address}" && \
             for i in $(seq 1 8); do \
                 SINK=$(wpctl status | awk '/Sinks:/, /Sink endpoints:/' | grep -i "bluez" | head -n1 | tr -dc '0-9'); \
                 [ -n "$SINK" ] && wpctl set-default "$SINK" && break; \
                 sleep 0.3; \
             done`]);
        updateDebounceTimer.restart();
    }

    function disconnectDevice(address: string): void {
        if (!address)
            return;
        Quickshell.execDetached(["bluetoothctl", "disconnect", address]);
        updateDebounceTimer.restart();
    }

    function poll(): void {
        refreshDevices();
    }

    // 6. Idle heartbeat poll (relaxed to 10s since DBus monitor captures live events)
    property Timer pollTimer: Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    // 7. IPC Interface
    property IpcHandler bluetoothIpc: IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            root.togglePower();
        }

        function scan(): void {
            root.scan();
        }

        function connect(address: string): void {
            root.connectDevice(address);
        }

        function disconnect(address: string): void {
            root.disconnectDevice(address);
        }

        function poll(): void {
            root.poll();
        }
    }

    Component.onCompleted: {
        root.poll();
    }
}
