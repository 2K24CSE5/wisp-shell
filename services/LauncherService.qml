pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configs

Singleton {
    id: root

    property bool isOpen: false
    property string searchQuery: ""
    property string activeCategory: "All"
    property int selectedIndex: 0

    // List of recent app IDs (stored in-memory and can persist)
    property var recentAppIds: []

    // Filtered application list
    property var filteredItems: []

    // Predefined desktop categories
    readonly property var categories: [
        { id: "All", name: "All", icon: "\ue5c3" }, // apps
        { id: "Internet", name: "Internet", icon: "\ue80b" }, // public / web
        { id: "Development", name: "Development", icon: "\ue86f" }, // code
        { id: "AudioVideo", name: "Media", icon: "\ue030" }, // play_circle
        { id: "Office", name: "Office", icon: "\ue85d" }, // assignment / doc
        { id: "Graphics", name: "Graphics", icon: "\ue3b7" }, // palette / brush
        { id: "System", name: "System", icon: "\ue8b8" }, // settings
        { id: "Utility", name: "Utilities", icon: "\ue89a" } // build / tool
    ]

    onIsOpenChanged: {
        if (isOpen) {
            searchQuery = "";
            activeCategory = "All";
            selectedIndex = 0;
            updateFilteredItems();
        }
    }

    onSearchQueryChanged: {
        selectedIndex = 0;
        updateFilteredItems();
    }

    onActiveCategoryChanged: {
        selectedIndex = 0;
        updateFilteredItems();
    }

    // Connect to desktop entries changes if applications list refreshes
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.updateFilteredItems();
        }
    }

    // ── Safe Math Evaluator ──────────────────────────────────────────────────
    function evaluateMath(expression) {
        try {
            // Only allow digits, basic operators, parenthesis, and math functions
            const sanitized = expression.trim();
            if (!/^[\d\s\+\-\*\/\%\^\(\)\.\,eE]+$/.test(sanitized))
                return null;

            // Must contain at least one digit and one operator
            if (!/\d/.test(sanitized) || !/[\+\-\*\/\%\^]/.test(sanitized))
                return null;

            // Replace ^ with ** for exponentiation
            const jsExpr = sanitized.replace(/\^/g, "**");
            const result = Function('"use strict"; return (' + jsExpr + ')')();

            if (typeof result === "number" && !isNaN(result) && isFinite(result)) {
                // Round to maximum 8 decimal places for clean formatting
                return Math.round(result * 100000000) / 100000000;
            }
            return null;
        } catch (e) {
            return null;
        }
    }

    // ── Category Matcher ─────────────────────────────────────────────────────
    function entryMatchesCategory(entry, catId) {
        if (catId === "All") return true;

        const cats = entry.categories || [];
        const catsLower = cats.map(c => c.toLowerCase());

        switch (catId) {
            case "Internet":
                return catsLower.some(c => c.includes("network") || c.includes("web") || c.includes("browser") || c.includes("chat") || c.includes("mail") || c.includes("irc"));
            case "Development":
                return catsLower.some(c => c.includes("development") || c.includes("ide") || c.includes("debugger") || c.includes("git") || c.includes("editor"));
            case "AudioVideo":
                return catsLower.some(c => c.includes("audio") || c.includes("video") || c.includes("multimedia") || c.includes("player") || c.includes("recorder") || c.includes("music"));
            case "Office":
                return catsLower.some(c => c.includes("office") || c.includes("word") || c.includes("spreadsheet") || c.includes("presentation") || c.includes("texteditor") || c.includes("viewer"));
            case "Graphics":
                return catsLower.some(c => c.includes("graphics") || c.includes("image") || c.includes("drawing") || c.includes("photo") || c.includes("scanner"));
            case "System":
                return catsLower.some(c => c.includes("system") || c.includes("settings") || c.includes("monitor") || c.includes("terminal") || c.includes("emulator") || c.includes("filemanager"));
            case "Utility":
                return catsLower.some(c => c.includes("utility") || c.includes("calculator") || c.includes("archive") || c.includes("accessory") || c.includes("tools"));
            default:
                return true;
        }
    }

    // ── Search & Filter Logic ─────────────────────────────────────────────────
    function updateFilteredItems() {
        const query = (root.searchQuery || "").trim();
        const results = [];

        // 1. Direct Shell / Terminal Command execution prefix
        if (query.startsWith(">") || query.startsWith("$")) {
            const cmd = query.substring(1).trim();
            if (cmd.length > 0) {
                results.push({
                    type: "command",
                    id: "cmd:" + cmd,
                    name: "Run: " + cmd,
                    subtitle: "Execute in terminal (Ghostty)",
                    command: cmd,
                    icon: "\ueb8b", // terminal icon
                    isIconFont: true
                });
            }
        }

        // 2. Math calculation check
        const mathResult = evaluateMath(query);
        if (mathResult !== null) {
            results.push({
                type: "calculator",
                id: "calc:" + query,
                name: String(mathResult),
                subtitle: "= " + query + " (Press Enter to copy result)",
                calcValue: String(mathResult),
                icon: "\uea5f", // calculate icon
                isIconFont: true
            });
        }

        // 3. Scan and score desktop applications
        const rawApps = DesktopEntries.applications.values || [];
        const seenIds = new Set();
        const scoredApps = [];
        const queryLower = query.toLowerCase();

        for (let i = 0; i < rawApps.length; i++) {
            const entry = rawApps[i];
            if (!entry || entry.noDisplay || !entry.name)
                continue;

            // Deduplicate by ID
            if (seenIds.has(entry.id))
                continue;
            seenIds.add(entry.id);

            // Category filter check
            if (!entryMatchesCategory(entry, root.activeCategory))
                continue;

            if (queryLower.length === 0) {
                // No query: sort alphabetically (prioritizing recent apps)
                const isRecent = root.recentAppIds.indexOf(entry.id) !== -1;
                scoredApps.push({
                    entry: entry,
                    score: isRecent ? 1000 : 0
                });
            } else {
                const name = (entry.name || "").toLowerCase();
                const genericName = (entry.genericName || "").toLowerCase();
                const comment = (entry.comment || "").toLowerCase();
                const id = (entry.id || "").toLowerCase();
                const exec = (entry.execString || "").toLowerCase();

                let score = 0;

                // Name matches
                if (name === queryLower) {
                    score += 1000;
                } else if (name.startsWith(queryLower)) {
                    score += 500;
                } else if (name.includes(" " + queryLower)) {
                    score += 350;
                } else if (name.includes(queryLower)) {
                    score += 200;
                }

                // ID / Exec matches
                if (id.startsWith(queryLower)) {
                    score += 150;
                } else if (exec.includes(queryLower)) {
                    score += 80;
                }

                // Generic name / category match
                if (genericName.includes(queryLower)) {
                    score += 120;
                }

                // Comment / Description match
                if (comment.includes(queryLower)) {
                    score += 50;
                }

                // Keywords match
                const kws = entry.keywords || [];
                for (let k = 0; k < kws.length; k++) {
                    if (kws[k].toLowerCase().includes(queryLower)) {
                        score += 60;
                        break;
                    }
                }

                if (score > 0) {
                    // Boost if recently used
                    if (root.recentAppIds.indexOf(entry.id) !== -1) {
                        score += 100;
                    }
                    scoredApps.push({
                        entry: entry,
                        score: score
                    });
                }
            }
        }

        // Sort scored applications
        if (queryLower.length === 0) {
            scoredApps.sort((a, b) => {
                if (a.score !== b.score) return b.score - a.score;
                return (a.entry.name || "").localeCompare(b.entry.name || "");
            });
        } else {
            scoredApps.sort((a, b) => {
                if (b.score !== a.score) return b.score - a.score;
                return (a.entry.name || "").localeCompare(b.entry.name || "");
            });
        }

        // Map scored apps to result item wrappers
        for (let j = 0; j < scoredApps.length; j++) {
            const e = scoredApps[j].entry;
            results.push({
                type: "app",
                id: e.id,
                name: e.name,
                subtitle: e.genericName || e.comment || (e.categories ? e.categories.slice(0, 3).join(" • ") : ""),
                entry: e,
                icon: e.icon || "application-x-executable",
                isIconFont: false
            });
        }

        root.filteredItems = results;
        if (root.selectedIndex >= results.length) {
            root.selectedIndex = Math.max(0, results.length - 1);
        }
    }

    // ── Navigation & Actions ──────────────────────────────────────────────────
    function selectNext() {
        if (root.filteredItems.length === 0) return;
        root.selectedIndex = (root.selectedIndex + 1) % root.filteredItems.length;
    }

    function selectPrev() {
        if (root.filteredItems.length === 0) return;
        root.selectedIndex = (root.selectedIndex - 1 + root.filteredItems.length) % root.filteredItems.length;
    }

    function launchSelected() {
        if (root.filteredItems.length === 0) return;
        const item = root.filteredItems[root.selectedIndex];
        if (item) {
            root.launchItem(item);
        }
    }

    function launchItem(item) {
        if (!item) return;

        if (item.type === "calculator") {
            // Copy calculation result to clipboard via wl-copy
            Quickshell.execDetached(["sh", "-c", "printf '%s' '" + item.calcValue + "' | wl-copy"]);
            root.close();
            return;
        }

        if (item.type === "command") {
            // Execute command in Ghostty terminal
            Quickshell.execDetached(["ghostty", "-e", "sh", "-c", item.command + "; echo; echo 'Press Enter to exit...'; read line"]);
            root.close();
            return;
        }

        if (item.type === "app" && item.entry) {
            // Add to recent apps (keep top 10 unique)
            const recents = root.recentAppIds.filter(id => id !== item.id);
            recents.unshift(item.id);
            root.recentAppIds = recents.slice(0, 10);

            // Launch app
            item.entry.execute();
            root.close();
        }
    }

    // ── Open / Close / Toggle ─────────────────────────────────────────────────
    function open() {
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        if (root.isOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    // ── IPC Handler ───────────────────────────────────────────────────────────
    property IpcHandler launcherIpc: IpcHandler {
        target: "launcher"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }

        function isOpen(): bool {
            return root.isOpen;
        }
    }
}
