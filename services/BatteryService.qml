pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int percentage: 100
    property bool isCharging: false
    property bool hasBattery: true

    property Process batProcess: Process {
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1"]

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line)
                    return;

                const val = parseInt(line);
                if (!isNaN(val)) {
                    root.percentage = Math.min(100, Math.max(0, val));
                    root.hasBattery = true;
                } else {
                    root.isCharging = (line.toLowerCase() === "charging");
                }
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.batProcess.running) {
                root.batProcess.running = true;
            }
        }
    }
}
