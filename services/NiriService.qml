pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

QtObject {
    id: root

    // --- Workspaces State ---
    property int currentWorkspaceId: 1
    property int currentWorkspaceIndex: 0
    property var activeWorkspaces: []

    // --- Active Window State ---
    property string niriTitle: ""
    property string niriAppId: ""

    // Overlay State Integrations
    readonly property bool isPolkitActive: PolkitService.dialogOpen && PolkitService.flow !== null
    readonly property bool isSettingsActive: SettingsService.isOpen

    readonly property string formattedAppName: {
        if (root.isPolkitActive)
            return "Security";
        if (root.isSettingsActive)
            return "Settings";
        if (!root.niriAppId)
            return "";

        let name = root.niriAppId;
        if (name.includes(".")) {
            name = name.split(".").pop();
        }
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    readonly property string activeTitle: {
        if (root.isPolkitActive)
            return "Authentication";
        if (root.isSettingsActive) {
            switch (SettingsService.currentTab) {
            case 0:
                return "Appearance";
            case 1:
                return "Niri";
            case 2:
                return "Lockscreen";
            default:
                return "Settings";
            }
        }
        return root.niriTitle;
    }

    readonly property bool hasActiveWindow: root.isPolkitActive || root.isSettingsActive || (root.niriTitle.length > 0 || root.niriAppId.length > 0)

    // --- Debounced Snapshot Fetchers ---
    property Timer fetchDebounceTimer: Timer {
        interval: 35
        repeat: false
        onTriggered: root.refreshAll()
    }

    // 1. Snapshot fetcher: Workspaces
    property Process wsSnapshotProcess: Process {
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    root.parseWorkspaces(this.text.trim());
                }
            }
        }
    }

    // 2. Snapshot fetcher: Focused Window
    property Process winSnapshotProcess: Process {
        command: ["niri", "msg", "-j", "focused-window"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || this.text.trim().length === 0) {
                    root.niriTitle = "";
                    root.niriAppId = "";
                    return;
                }
                try {
                    const win = JSON.parse(this.text.trim());
                    if (win && typeof win === "object") {
                        root.niriTitle = win.title ?? "";
                        root.niriAppId = win.app_id ?? "";
                    } else {
                        root.niriTitle = "";
                        root.niriAppId = "";
                    }
                } catch (_) {
                    root.niriTitle = "";
                    root.niriAppId = "";
                }
            }
        }
    }

    // 3. Persistent Event Stream
    property Process streamProcess: Process {
        command: ["niri", "msg", "-j", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim();
                if (!trimmed)
                    return;

                try {
                    const event = JSON.parse(trimmed);

                    if (event.WorkspacesChanged || event.WorkspaceActivated || event.WindowFocusChanged || event.FocusedWindowChanged) {
                        root.fetchDebounceTimer.restart();
                    }
                } catch (_) {}
            }
        }

        onExited: () => {
            reconnectTimer.restart();
        }
    }

    property Timer reconnectTimer: Timer {
        id: reconnectTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (!root.streamProcess.running) {
                root.streamProcess.running = true;
            }
            root.refreshAll();
        }
    }

    // --- Action & Helper Methods ---

    function refreshAll(): void {
        if (!root.wsSnapshotProcess.running)
            root.wsSnapshotProcess.running = true;
        if (!root.winSnapshotProcess.running)
            root.winSnapshotProcess.running = true;
    }

    function parseWorkspaces(jsonText: string): void {
        try {
            const list = JSON.parse(jsonText);
            if (!Array.isArray(list))
                return;

            list.sort((a, b) => (a.idx ?? a.id ?? 0) - (b.idx ?? b.id ?? 0));

            let focusedId = 1;
            let activeIdx = 0;

            const mapped = new Array(list.length);
            for (let i = 0; i < list.length; i++) {
                const ws = list[i];
                const id = ws.id ?? ws.idx ?? (i + 1);
                const isCurrent = Boolean(ws.is_active || ws.is_focused);
                if (isCurrent) {
                    focusedId = id;
                    activeIdx = i;
                }
                mapped[i] = {
                    raw: ws,
                    id: id,
                    idx: ws.idx ?? (i + 1),
                    isActive: isCurrent
                };
            }

            root.currentWorkspaceId = focusedId;
            root.currentWorkspaceIndex = activeIdx;
            root.activeWorkspaces = mapped;
        } catch (e) {
            console.warn("[NiriService] Failed to parse workspaces JSON:", e);
        }
    }

    function isWorkspaceActive(modelData): bool {
        if (!modelData)
            return false;
        const id = modelData.id ?? (modelData.idx ?? 1);
        return Boolean(modelData.is_active || modelData.is_focused || id === root.currentWorkspaceId);
    }

    function focusWorkspace(wsObject): void {
        if (!wsObject)
            return;

        const target = wsObject.raw ? wsObject.raw : wsObject;
        const targetRef = target.idx !== undefined && target.idx !== null ? String(target.idx) : (target.name ? String(target.name) : String(target.id ?? target));

        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", targetRef]);

        const nextId = target.id ?? target.idx;
        if (nextId !== undefined && nextId !== null) {
            root.currentWorkspaceId = nextId;
            const targetIdx = root.activeWorkspaces.findIndex(w => w.id === nextId || w.idx === nextId);
            if (targetIdx >= 0) {
                root.currentWorkspaceIndex = targetIdx;
            }
        }
    }

    Component.onCompleted: {
        root.refreshAll();
    }
}
