pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool ethernetConnected: false
    property bool wifiEnabled: false
    property bool wifiConnected: false
    property string connectedWifiSsid: ""
    property var accessPoints: []

    property string nmRawOutput: ""
    property Process nmProcess: Process {
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: SplitParser {
            onRead: data => {
                root.nmRawOutput += data + "\n";
            }
        }
        onExited: () => {
            let ethConn = false;
            let wifiOn = false;
            let wifiConn = false;
            let activeSsid = "";
            const lines = root.nmRawOutput.split("\n");
            root.nmRawOutput = "";

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (!line)
                    continue;
                const parts = line.split(":");
                const type = parts[0];
                const state = parts[1];
                const connName = parts.slice(2).join(":");

                if (type === "ethernet" && state === "connected") {
                    ethConn = true;
                } else if (type === "wifi") {
                    if (state !== "unavailable" && state !== "unmanaged")
                        wifiOn = true;
                    if (state === "connected") {
                        wifiConn = true;
                        activeSsid = connName || "";
                    }
                }
            }
            root.ethernetConnected = ethConn;
            root.wifiEnabled = wifiOn;
            root.wifiConnected = wifiConn;
            root.connectedWifiSsid = activeSsid;
        }
    }

    property string apRawOutput: ""
    property Process apProcess: Process {
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SECURITY", "device", "wifi", "list"]
        stdout: SplitParser {
            onRead: data => {
                root.apRawOutput += data;
            }
        }
        onExited: () => {
            const raw = root.apRawOutput;
            root.apRawOutput = "";
            if (!raw || raw.trim().length === 0) {
                root.accessPoints = [];
                return;
            }

            const formatted = raw.replace(/([^\n])\*(?=:)/g, "$1\n*").replace(/([^\n]) (?=:)/g, "$1\n ");
            const lines = formatted.split("\n");
            const aps = {};

            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();
                if (!line)
                    continue;
                line = line.replace(/\\:/g, "__COLON__");
                const parts = line.split(":");
                const inUse = parts[0].trim() === "*";
                const ssid = (parts[1] || "").replace(/__COLON__/g, ":").trim();
                const sec = (parts[2] || "").replace(/__COLON__/g, ":").trim();
                if (!ssid || ssid === "--")
                    continue;

                if (!aps[ssid] || inUse) {
                    aps[ssid] = {
                        "ssid": ssid,
                        "connected": inUse,
                        "requiresPassword": Boolean(sec && !sec.includes("--"))
                    };
                }
            }
            const res = Object.values(aps);
            res.sort((a, b) => (b.connected - a.connected) || a.ssid.localeCompare(b.ssid));
            root.accessPoints = res;
        }
    }

    function toggleWifiRadio(): void {
        const nextState = root.wifiEnabled ? "off" : "on";
        Quickshell.execDetached(["nmcli", "radio", "wifi", nextState]);
        root.wifiEnabled = !root.wifiEnabled;
        if (!root.wifiEnabled) {
            root.wifiConnected = false;
            root.connectedWifiSsid = "";
            root.accessPoints = [];
        }
        poll();
    }

    function disconnectWifi(): void {
        Quickshell.execDetached(["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2==\"wifi\" && $3==\"connected\" {print $1}' | xargs -r nmcli device disconnect"]);
        root.wifiConnected = false;
        root.connectedWifiSsid = "";
        poll();
    }

    function connectWifi(ssid: string): void {
        if (!ssid)
            return;
        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid]);
        poll();
    }

    function scanWifi(): void {
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
        if (!apProcess.running)
            apProcess.running = true;
    }

    function poll(): void {
        if (!nmProcess.running)
            nmProcess.running = true;
    }

    property Timer pollTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
