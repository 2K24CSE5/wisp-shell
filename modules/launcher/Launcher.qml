import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.configs
import qs.services
import qs.components

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: launcherWindow
            required property var modelData
            screen: modelData

            visible: LauncherService.isOpen
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: LauncherService.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "wisp-launcher"

            // Fullscreen Dimmed Backdrop
            Rectangle {
                anchors.fill: parent
                color: "#66000000"
                opacity: LauncherService.isOpen ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: LauncherService.close()
                }
            }

            // Launcher Modal Card
            Rectangle {
                id: launcherCard
                width: Math.min(620, parent.width - 32)
                height: Math.min(540, parent.height - 48)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -20

                radius: Config.radius
                color: Color.background
                border.width: 1
                border.color: Color.overlay
                clip: true

                // Scale & Fade Animation
                scale: LauncherService.isOpen ? 1.0 : 0.96
                opacity: LauncherService.isOpen ? 1.0 : 0.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                // Prevent backdrop clicks inside the card
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // ── Search Input Box ──────────────────────────────────────
                    Rectangle {
                        id: searchBox
                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: Math.max(4, Config.radius - 2)
                        color: Color.surface
                        border.width: searchInput.activeFocus ? 1.5 : 1
                        border.color: searchInput.activeFocus ? Color.primary : Color.overlay

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Search Leading Icon
                            Text {
                                text: "\ue8b6" // search icon
                                font.family: Config.iconFont
                                font.pixelSize: 20
                                color: searchInput.activeFocus ? Color.primary : Color.muted
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }

                            // Search Text Input
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TextInput {
                                    id: searchInput
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Config.textFont
                                    font.pixelSize: 14
                                    color: Color.text
                                    selectByMouse: true
                                    selectionColor: Color.primary
                                    selectedTextColor: Color.background
                                    clip: true

                                    text: LauncherService.searchQuery

                                    onTextEdited: {
                                        LauncherService.searchQuery = text;
                                    }

                                    Keys.onDownPressed: event => {
                                        LauncherService.selectNext();
                                        event.accepted = true;
                                    }

                                    Keys.onUpPressed: event => {
                                        LauncherService.selectPrev();
                                        event.accepted = true;
                                    }

                                    Keys.onReturnPressed: event => {
                                        LauncherService.launchSelected();
                                        event.accepted = true;
                                    }

                                    Keys.onEnterPressed: event => {
                                        LauncherService.launchSelected();
                                        event.accepted = true;
                                    }

                                    Keys.onEscapePressed: event => {
                                        LauncherService.close();
                                        event.accepted = true;
                                    }

                                    Keys.onTabPressed: event => {
                                        // Cycle through categories
                                        const cats = LauncherService.categories;
                                        const currIdx = cats.findIndex(c => c.id === LauncherService.activeCategory);
                                        const nextIdx = (currIdx + 1) % cats.length;
                                        LauncherService.activeCategory = cats[nextIdx].id;
                                        event.accepted = true;
                                    }
                                }

                                // Placeholder
                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Search applications, math (e.g. 15*8), or command (> htop)..."
                                    font.family: Config.textFont
                                    font.pixelSize: 13
                                    color: Color.muted
                                    visible: !searchInput.text && !searchInput.inputMethodComposing
                                    elide: Text.ElideRight
                                }
                            }

                            // Clear Button
                            Rectangle {
                                visible: searchInput.text.length > 0
                                implicitWidth: 24
                                implicitHeight: 24
                                radius: 12
                                color: clearMouse.containsMouse ? Color.overlay : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ue5cd" // close icon
                                    font.family: Config.iconFont
                                    font.pixelSize: 16
                                    color: Color.muted
                                }

                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = "";
                                        LauncherService.searchQuery = "";
                                        searchInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    // ── Category Pills Row ────────────────────────────────────
                    ScrollView {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                        RowLayout {
                            spacing: 6

                            Repeater {
                                model: LauncherService.categories

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isSelected: LauncherService.activeCategory === modelData.id

                                    implicitWidth: catRow.implicitWidth + 16
                                    implicitHeight: 28
                                    radius: 14
                                    color: isSelected ? Color.primary : (catMouse.containsMouse ? Color.overlay : Color.surface)
                                    border.width: 1
                                    border.color: isSelected ? Color.primary : Color.overlay

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }

                                    RowLayout {
                                        id: catRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            text: modelData.icon
                                            font.family: Config.iconFont
                                            font.pixelSize: 13
                                            color: isSelected ? Color.background : (catMouse.containsMouse ? Color.text : Color.muted)
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: Config.textFont
                                            font.pixelSize: 11
                                            font.bold: isSelected
                                            color: isSelected ? Color.background : (catMouse.containsMouse ? Color.text : Color.muted)
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        id: catMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            LauncherService.activeCategory = modelData.id;
                                            searchInput.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Hairline separator
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Color.overlay
                    }

                    // ── Applications List View ────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: appListView
                            anchors.fill: parent
                            spacing: 4
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            model: LauncherService.filteredItems

                            delegate: Rectangle {
                                id: rowItem
                                required property var modelData
                                required property int index

                                readonly property bool isSelected: index === LauncherService.selectedIndex

                                width: appListView.width
                                implicitHeight: 48
                                radius: Math.max(4, Config.radius - 4)

                                color: {
                                    if (isSelected) return Color.overlay;
                                    if (itemMouse.containsMouse) return Color.surface;
                                    return "transparent";
                                }

                                border.width: isSelected ? 1.5 : 0
                                border.color: isSelected ? Color.primary : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    // Application Icon / Type Icon
                                    Rectangle {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        radius: 6
                                        color: isSelected ? Color.surface : Color.overlay
                                        Layout.alignment: Qt.AlignVCenter

                                        // Icon font for Calculator or Terminal commands
                                        Text {
                                            anchors.centerIn: parent
                                            visible: Boolean(modelData.isIconFont)
                                            text: modelData.icon || ""
                                            font.family: Config.iconFont
                                            font.pixelSize: 18
                                            color: Color.primary
                                        }

                                        // Application icon using Quickshell.Widgets.IconImage
                                        IconImage {
                                            id: appIcon
                                            anchors.centerIn: parent
                                            width: 24
                                            height: 24
                                            visible: !modelData.isIconFont
                                            source: Quickshell.iconPath(modelData.icon || "application-x-executable", "application-x-executable")
                                        }

                                        // Fallback if app icon cannot be resolved
                                        Text {
                                            anchors.centerIn: parent
                                            visible: !modelData.isIconFont && appIcon.status !== Image.Ready
                                            text: "\ue8af" // default apps icon
                                            font.family: Config.iconFont
                                            font.pixelSize: 18
                                            color: Color.muted
                                        }
                                    }

                                    // Title & Subtitle Labels
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: modelData.name || ""
                                            font.family: Config.textFont
                                            font.pixelSize: 13
                                            font.bold: isSelected
                                            color: isSelected ? Color.primary : Color.text
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            visible: Boolean(modelData.subtitle && modelData.subtitle.length > 0)
                                            text: modelData.subtitle || ""
                                            font.family: Config.textFont
                                            font.pixelSize: 11
                                            color: Color.muted
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Selected Enter Indicator Badge
                                    Rectangle {
                                        visible: isSelected
                                        implicitWidth: 22
                                        implicitHeight: 20
                                        radius: 4
                                        color: Color.primary
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\ue315" // keyboard_arrow_right or return
                                            font.family: Config.iconFont
                                            font.pixelSize: 14
                                            color: Color.background
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        LauncherService.selectedIndex = index;
                                    }
                                    onClicked: {
                                        LauncherService.launchItem(modelData);
                                    }
                                }
                            }

                            // Keep selected item visible while navigating
                            Connections {
                                target: LauncherService
                                function onSelectedIndexChanged() {
                                    if (LauncherService.selectedIndex >= 0 && LauncherService.selectedIndex < appListView.count) {
                                        appListView.positionViewAtIndex(LauncherService.selectedIndex, ListView.Contain);
                                    }
                                }
                            }
                        }

                        // Empty State Display
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: LauncherService.filteredItems.length === 0
                            spacing: 8

                            Text {
                                text: "\ue8b6"
                                font.family: Config.iconFont
                                font.pixelSize: 36
                                color: Color.muted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "No applications found"
                                font.family: Config.textFont
                                font.pixelSize: 14
                                font.bold: true
                                color: Color.text
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: LauncherService.searchQuery.length > 0
                                    ? "No matches for \"" + LauncherService.searchQuery + "\""
                                    : "No applications in this category"
                                font.family: Config.textFont
                                font.pixelSize: 11
                                color: Color.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // ── Bottom Keyboard Hints Bar ─────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Keyboard shortcuts hints
                            RowLayout {
                                spacing: 14
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        implicitWidth: 32
                                        implicitHeight: 18
                                        radius: 3
                                        color: Color.surface
                                        border.width: 1
                                        border.color: Color.overlay
                                        Text {
                                            anchors.centerIn: parent
                                            text: "↑ / ↓"
                                            font.family: "monospace"
                                            font.pixelSize: 10
                                            color: Color.muted
                                        }
                                    }
                                    Text {
                                        text: "Navigate"
                                        font.family: Config.textFont
                                        font.pixelSize: 10
                                        color: Color.muted
                                    }
                                }

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        implicitWidth: 38
                                        implicitHeight: 18
                                        radius: 3
                                        color: Color.surface
                                        border.width: 1
                                        border.color: Color.overlay
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Enter"
                                            font.family: "monospace"
                                            font.pixelSize: 10
                                            color: Color.muted
                                        }
                                    }
                                    Text {
                                        text: "Launch"
                                        font.family: Config.textFont
                                        font.pixelSize: 10
                                        color: Color.muted
                                    }
                                }

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        implicitWidth: 30
                                        implicitHeight: 18
                                        radius: 3
                                        color: Color.surface
                                        border.width: 1
                                        border.color: Color.overlay
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Tab"
                                            font.family: "monospace"
                                            font.pixelSize: 10
                                            color: Color.muted
                                        }
                                    }
                                    Text {
                                        text: "Category"
                                        font.family: Config.textFont
                                        font.pixelSize: 10
                                        color: Color.muted
                                    }
                                }

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        implicitWidth: 28
                                        implicitHeight: 18
                                        radius: 3
                                        color: Color.surface
                                        border.width: 1
                                        border.color: Color.overlay
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Esc"
                                            font.family: "monospace"
                                            font.pixelSize: 10
                                            color: Color.muted
                                        }
                                    }
                                    Text {
                                        text: "Close"
                                        font.family: Config.textFont
                                        font.pixelSize: 10
                                        color: Color.muted
                                    }
                                }
                            }

                            // App Count Badge
                            Text {
                                text: LauncherService.filteredItems.length + " items"
                                font.family: Config.textFont
                                font.pixelSize: 10
                                color: Color.muted
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }
                }
            }

            // Auto-focus search input whenever launcher becomes visible
            Connections {
                target: LauncherService
                function onIsOpenChanged() {
                    if (LauncherService.isOpen) {
                        searchInput.forceActiveFocus();
                    }
                }
            }
        }
    }
}
