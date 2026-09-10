pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool ethernetConnected: false
    property bool wifiEnabled: false
    property bool wifiConnected: false

    property bool bluetoothEnabled: false
    property bool bluetoothConnected: false

    property var nmBuffer: []

    property Process nmProcess: Process {
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]

        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length > 0)
                    root.nmBuffer.push(data.trim());
            }
        }

        onExited: () => {
            let ethConn = false;
            let wifiOn = false;
            let wifiConn = false;

            for (const line of root.nmBuffer) {
                const [type, state] = line.split(":");
                if (type === "ethernet" && state === "connected") {
                    ethConn = true;
                } else if (type === "wifi") {
                    if (state !== "unavailable" && state !== "unmanaged")
                        wifiOn = true;
                    if (state === "connected")
                        wifiConn = true;
                }
            }

            root.ethernetConnected = ethConn;
            root.wifiEnabled = wifiOn;
            root.wifiConnected = wifiConn;
            root.nmBuffer = [];
        }
    }

    property string btBuffer: ""

    property Process btProcess: Process {
        command: ["bluetoothctl", "show"]

        stdout: SplitParser {
            onRead: data => {
                root.btBuffer += data + "\n";
            }
        }

        onExited: () => {
            root.bluetoothEnabled = root.btBuffer.includes("Powered: yes");
            root.btBuffer = "";
        }
    }

    property string btConnBuffer: ""

    property Process btConnectedProcess: Process {
        command: ["bluetoothctl", "devices", "Connected"]

        stdout: SplitParser {
            onRead: data => {
                root.btConnBuffer += data.trim();
            }
        }

        onExited: () => {
            root.bluetoothConnected = root.btConnBuffer.length > 0;
            root.btConnBuffer = "";
        }
    }

    property Timer pollTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!nmProcess.running)
                nmProcess.running = true;
            if (!btProcess.running)
                btProcess.running = true;
            if (!btConnectedProcess.running)
                btConnectedProcess.running = true;
        }
    }
}
