pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: service

    // ── State ────────────────────────────────────────────────────────────────

    property string activeTab: ""
    property string lastActiveTab: "quick"
    readonly property bool isExpanded: activeTab !== ""

    onActiveTabChanged: {
        if (activeTab !== "") {
            lastActiveTab = activeTab;
        }
    }

    // ── Public API ───────────────────────────────────────────────────────────

    function toggleTab(tabName: string): void {
        if (activeTab === tabName) {
            activeTab = "";
        } else {
            activeTab = tabName;
            if (tabName === "clock") {
                DateTimeService.resetToToday();
            } else if (tabName === "quick") {
                Qt.callLater(() => {
                    NetworkService.poll();
                    BluetoothService.poll();
                });
            } else if (tabName === "battery") {
                Qt.callLater(() => BatteryService.poll());
            } else if (tabName === "mirror") {
                Qt.callLater(() => MirrorService.poll());
            } else if (tabName === "notifications") {
                NotificationService.hasUnread = false;
            }
        }
    }

    function collapse(): void {
        activeTab = "";
    }

    // ── Auto-collapse on lock / dim ──────────────────────────────────────────

    Connections {
        target: LockScreenService

        function onIsLockedChanged(): void {
            if (LockScreenService.isLocked)
                service.collapse();
        }

        function onIsDimmedChanged(): void {
            if (LockScreenService.isDimmed)
                service.collapse();
        }
    }

    // ── IPC ──────────────────────────────────────────────────────────────────

    property IpcHandler barIpc: IpcHandler {
        target: "bar"

        function toggle(tab: string): void {
            service.toggleTab(tab || "quick");
        }

        function collapse(): void {
            service.collapse();
        }

        function isExpanded(): bool {
            return service.isExpanded;
        }
    }
}
