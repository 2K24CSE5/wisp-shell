pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray

QtObject {
    id: root

    property bool expanded: false

    readonly property var items: SystemTray.items.values
    readonly property int count: items.length
    readonly property bool hasItems: count > 0

    // Shared opener to avoid multi-item DBus listener bloat
    readonly property QsMenuOpener menuOpener: QsMenuOpener {
        id: sharedMenuOpener
    }

    property Item activeMenuTarget: null
    property SystemTrayItem activeMenuItem: null

    signal menuRequested(Item targetItem, SystemTrayItem trayItem, QsMenuOpener opener)
    signal menuCloseRequested

    // Collapse automatically when all tray icons disappear
    onHasItemsChanged: {
        if (!hasItems && expanded) {
            closeMenu();
            expanded = false;
        }
    }

    function toggleExpanded(): void {
        if (expanded) {
            closeMenu();
        }
        expanded = !expanded;
    }

    function setExpanded(val: bool): void {
        if (!val && expanded) {
            closeMenu();
        }
        expanded = val;
    }

    function activateItem(item: SystemTrayItem): void {
        if (item) {
            item.activate();
        }
    }

    function secondaryActivateItem(item: SystemTrayItem): void {
        if (item) {
            item.secondaryActivate();
        }
    }

    function openMenuForItem(targetItem: Item, item: SystemTrayItem): void {
        if (!item)
            return;

        activeMenuTarget = targetItem;
        activeMenuItem = item;
        sharedMenuOpener.menu = item.menu;
        menuRequested(targetItem, item, sharedMenuOpener);
    }

    // Release DBus menu bindings and dereference objects to prevent leaks
    function closeMenu(): void {
        menuCloseRequested();
        sharedMenuOpener.menu = null;
        activeMenuItem = null;
        activeMenuTarget = null;
    }

    function isSymbolic(iconSource: var): bool {
        if (!iconSource)
            return false;
        const iconStr = iconSource.toString().toLowerCase();
        return iconStr.includes("-symbolic") || iconStr.includes("symbolic");
    }

    property IpcHandler trayIpc: IpcHandler {
        target: "tray"

        function toggle(): void {
            root.toggleExpanded();
        }

        function expand(): void {
            root.setExpanded(true);
        }

        function collapse(): void {
            root.setExpanded(false);
        }

        function isExpanded(): bool {
            return root.expanded;
        }

        function getCount(): int {
            return root.count;
        }
    }
}
