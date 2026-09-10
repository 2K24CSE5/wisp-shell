pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int currentWorkspaceId: 1
    property var activeWorkspaces: []
    property string rawBuffer: ""

    property Process wsProcess: Process {
        command: ["niri", "msg", "-j", "workspaces"]

        stdout: SplitParser {
            onRead: data => {
                root.rawBuffer += data;
            }
        }

        onExited: () => {
            if (!root.rawBuffer.trim())
                return;

            try {
                const list = JSON.parse(root.rawBuffer);
                if (Array.isArray(list)) {
                    list.sort((a, b) => (a.idx ?? a.id ?? 0) - (b.idx ?? b.id ?? 0));

                    for (const ws of list) {
                        if (ws.is_active || ws.is_focused) {
                            root.currentWorkspaceId = ws.id ?? ws.idx ?? 1;
                            break;
                        }
                    }

                    root.activeWorkspaces = list.map(ws => {
                        const id = ws.id ?? ws.idx ?? 1;
                        return {
                            raw: ws,
                            id: id,
                            idx: ws.idx ?? 1,
                            isActive: Boolean(ws.is_active || ws.is_focused || (id === root.currentWorkspaceId))
                        };
                    });
                }
            } catch (e) {
                console.warn("[WorkspacesService] Failed to parse workspaces JSON:", e);
            }

            root.rawBuffer = "";
        }
    }

    property Timer pollTimer: Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.wsProcess.running) {
                root.wsProcess.running = true;
            }
        }
    }

    property Process actionProcess: Process {}

    function isWorkspaceActive(modelData) {
        if (!modelData)
            return false;
        const id = modelData.id ?? (modelData.idx ?? 1);
        return Boolean(modelData.is_active || modelData.is_focused || id === root.currentWorkspaceId);
    }

    function focusWorkspace(wsObject) {
        if (!wsObject)
            return;

        const target = wsObject.raw ? wsObject.raw : wsObject;
        let cmd = ["niri", "msg", "action", "focus-workspace"];

        if (target.idx !== undefined && target.idx !== null) {
            cmd.push(String(target.idx));
        } else if (target.id !== undefined && target.id !== null) {
            cmd.push("--id", String(target.id));
        } else if (target.name) {
            cmd.push(String(target.name));
        } else {
            cmd.push(String(target));
        }

        root.actionProcess.command = cmd;
        root.actionProcess.running = true;

        if (!root.wsProcess.running) {
            root.wsProcess.running = true;
        }
    }
}
