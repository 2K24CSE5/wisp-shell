pragma Singleton
import QtQuick
import Quickshell.Io
import qs.services

QtObject {
    id: root

    property string niriTitle: ""
    property string niriAppId: ""
    property string rawBuffer: ""

    readonly property bool isPolkitActive: PolkitService.dialogOpen && PolkitService.flow !== null
    readonly property bool isSettingsActive: SettingsService.isOpen

    readonly property string formattedAppName: {
        if (root.isPolkitActive) {
            return "Security";
        }
        if (root.isSettingsActive) {
            return "Settings";
        }
        if (!root.niriAppId)
            return "";
        let name = root.niriAppId;
        if (name.includes(".")) {
            name = name.split(".").pop();
        }
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    readonly property string activeTitle: {
        if (root.isPolkitActive) {
            return "Authentication";
        }
        if (root.isSettingsActive) {
            return SettingsService.currentTab === 0 ? "Appearance" : "Niri";
        }
        return root.niriTitle;
    }

    readonly property bool hasActiveWindow: root.isPolkitActive || root.isSettingsActive || (root.niriTitle.length > 0 || root.niriAppId.length > 0)

    property Process winProcess: Process {
        command: ["niri", "msg", "-j", "focused-window"]

        stdout: SplitParser {
            onRead: data => {
                root.rawBuffer += data;
            }
        }

        onExited: () => {
            if (!root.rawBuffer.trim()) {
                root.niriTitle = "";
                root.niriAppId = "";
                return;
            }

            try {
                const win = JSON.parse(root.rawBuffer);
                root.niriTitle = win.title ?? "";
                root.niriAppId = win.app_id ?? "";
            } catch (e) {
                root.niriTitle = "";
                root.niriAppId = "";
            }

            root.rawBuffer = "";
        }
    }

    property Timer pollTimer: Timer {
        interval: 300
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.winProcess.running) {
                root.winProcess.running = true;
            }
        }
    }

    function refresh() {
        if (!root.winProcess.running) {
            root.winProcess.running = true;
        }
    }
}
