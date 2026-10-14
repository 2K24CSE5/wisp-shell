pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.configs
import qs.services

Singleton {
    id: root

    readonly property bool isOpen: BarService.activeTab === "notifications"
    property bool hasUnread: false
    property var notifications: []
    property var groups: []
    property var toasts: []
    readonly property int count: notifications.length

    onIsOpenChanged: {
        if (isOpen) {
            hasUnread = false;
            toasts = [];
        }
    }

    // ── Notification Server ───────────────────────────────────────────────────

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true

        onNotification: notif => {
            root.handleNotification(notif);
        }
    }

    // ── Periodic Relative Time Updater ────────────────────────────────────────

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            for (let i = 0; i < root.notifications.length; i++) {
                root.notifications[i].timeStr = root.formatRelativeTime(root.notifications[i].timestamp);
            }
            root.rebuildGroups();
        }
    }

    // ── Helper Functions ──────────────────────────────────────────────────────

    function formatRelativeTime(timestamp) {
        const diff = Math.max(0, Math.floor((Date.now() - timestamp) / 1000));
        if (diff < 60)
            return "now";
        if (diff < 3600)
            return Math.floor(diff / 60) + "m";
        if (diff < 86400)
            return Math.floor(diff / 3600) + "h";
        return Math.floor(diff / 86400) + "d";
    }

    function rebuildGroups(): void {
        const map = {};
        const groupList = [];

        for (let i = 0; i < notifications.length; i++) {
            const item = notifications[i];
            const app = item.appName || "System";
            if (!map[app]) {
                const grp = {
                    appName: app,
                    appIcon: item.appIcon || "",
                    timeStr: item.timeStr || formatRelativeTime(item.timestamp),
                    latestTimestamp: item.timestamp,
                    count: 1,
                    items: [item]
                };
                map[app] = grp;
                groupList.push(grp);
            } else {
                map[app].items.push(item);
                map[app].count++;
                if (!map[app].appIcon && item.appIcon) {
                    map[app].appIcon = item.appIcon;
                }
            }
        }

        groupList.sort((a, b) => b.latestTimestamp - a.latestTimestamp);
        groups = groupList;
    }

    function handleNotification(notif): void {
        notif.tracked = true;

        const notifId = notif.id;
        const item = {
            id: notifId,
            appName: notif.appName || "System",
            appIcon: notif.appIcon || "",
            summary: notif.summary || "",
            body: notif.body || "",
            image: notif.image || "",
            urgency: notif.urgency,
            timestamp: Date.now(),
            timeStr: "now",
            expanded: false,
            actions: notif.actions || [],
            notif: notif
        };

        const existingIdx = notifications.findIndex(n => n.id === notifId);
        let updated = notifications.slice();
        if (existingIdx >= 0) {
            updated[existingIdx] = item;
        } else {
            updated.unshift(item);
        }
        notifications = updated;
        hasUnread = true;
        rebuildGroups();

        notif.closed.connect(reason => {
            root.removeNotification(notifId);
        });

        if (!isOpen && !LockScreenService.isLocked) {
            addToast(item);
        }
    }

    function removeNotification(notifId): void {
        notifications = notifications.filter(n => n.id !== notifId);
        toasts = toasts.filter(t => t.id !== notifId);
        rebuildGroups();
    }

    function dismissItem(notifId): void {
        const item = notifications.find(n => n.id === notifId);
        if (item && item.notif) {
            try {
                item.notif.dismiss();
            } catch (_) {}
        }
        removeNotification(notifId);
    }

    function dismissGroup(appName: string): void {
        const targetApp = appName || "System";
        const toRemove = notifications.filter(n => (n.appName || "System") === targetApp);
        toRemove.forEach(item => {
            if (item.notif) {
                try {
                    item.notif.dismiss();
                } catch (_) {}
            }
        });
        notifications = notifications.filter(n => (n.appName || "System") !== targetApp);
        toasts = toasts.filter(t => (t.appName || "System") !== targetApp);
        rebuildGroups();
    }

    function clearAll(): void {
        notifications.forEach(item => {
            if (item.notif) {
                try {
                    item.notif.dismiss();
                } catch (_) {}
            }
        });
        notifications = [];
        toasts = [];
        groups = [];
        hasUnread = false;
    }

    function toggleItemExpanded(notifId): void {
        const updated = notifications.slice();
        const item = updated.find(n => n.id === notifId);
        if (item) {
            item.expanded = !item.expanded;
            notifications = updated;
            rebuildGroups();
        }
    }

    // ── Toast Popups ──────────────────────────────────────────────────────────

    function addToast(item): void {
        let updated = toasts.filter(t => t.id !== item.id);
        updated.unshift(item);
        if (updated.length > 3) {
            updated = updated.slice(0, 3);
        }
        toasts = updated;

        const timeout = (item.notif && item.notif.expireTimeout > 0) ? item.notif.expireTimeout : 5000;
        const timer = Qt.createQmlObject('import QtQuick; Timer { interval: ' + timeout + '; repeat: false; }', root);
        timer.triggered.connect(() => {
            root.dismissToast(item.id);
            timer.destroy();
        });
        timer.start();
    }

    function dismissToast(notifId): void {
        toasts = toasts.filter(t => t.id !== notifId);
    }

    // ── Panel Visibility ──────────────────────────────────────────────────────

    function toggleCenter(): void {
        BarService.toggleTab("notifications");
    }

    function openCenter(): void {
        if (BarService.activeTab !== "notifications") {
            BarService.toggleTab("notifications");
        }
    }

    function closeCenter(): void {
        if (BarService.activeTab === "notifications") {
            BarService.collapse();
        }
    }

    // ── Auto-collapse on Lock ─────────────────────────────────────────────────

    Connections {
        target: LockScreenService

        function onIsLockedChanged(): void {
            if (LockScreenService.isLocked) {
                root.closeCenter();
                root.toasts = [];
            }
        }
    }

    // ── IPC API ───────────────────────────────────────────────────────────────

    property IpcHandler notifIpc: IpcHandler {
        target: "notifications"

        function toggle(): void {
            root.toggleCenter();
        }

        function open(): void {
            root.openCenter();
        }

        function close(): void {
            root.closeCenter();
        }

        function clear(): void {
            root.clearAll();
        }

        function count(): int {
            return root.count;
        }
    }
}
