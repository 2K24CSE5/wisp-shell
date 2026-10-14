import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.configs
import qs.services

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: 42
    implicitHeight: 600
    color: "transparent"
    visible: !LockScreenService.isLocked

    mask: Region {
        item: barSurface
    }

    property string activeTab: ""
    property string lastActiveTab: "quick"
    readonly property bool isExpanded: activeTab !== ""

    onActiveTabChanged: {
        if (activeTab !== "") {
            lastActiveTab = activeTab;
        }
    }

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
            }
        }
    }

    function collapse(): void {
        activeTab = "";
    }

    Connections {
        target: LockScreenService
        function onIsLockedChanged(): void {
            if (LockScreenService.isLocked) {
                barWindow.collapse();
            }
        }
        function onIsDimmedChanged(): void {
            if (LockScreenService.isDimmed) {
                barWindow.collapse();
            }
        }
    }

    property IpcHandler barIpc: IpcHandler {
        target: "bar"
        function toggle(tab: string): void {
            barWindow.toggleTab(tab || "quick");
        }
        function collapse(): void {
            barWindow.collapse();
        }
        function isExpanded(): bool {
            return barWindow.isExpanded;
        }
    }

    Rectangle {
        id: barSurface

        anchors {
            top: parent.top
            topMargin: 4
            horizontalCenter: parent.horizontalCenter
        }

        radius: Config.radius
        color: Color.background
        border.width: 1
        border.color: Color.overlay
        clip: true

        focus: true
        Keys.onEscapePressed: event => {
            if (barWindow.isExpanded) {
                barWindow.collapse();
                event.accepted = true;
            }
        }

        readonly property real collapsedWidth: topRow.implicitWidth + 16
        readonly property real targetExpandedWidth: {
            const tab = barWindow.activeTab !== "" ? barWindow.activeTab : barWindow.lastActiveTab;
            if (tab === "clock")
                return Math.max(collapsedWidth, 380);
            if (tab === "quick")
                return Math.max(collapsedWidth, 420);
            if (tab === "battery")
                return Math.max(collapsedWidth, 360);
            if (tab === "mirror")
                return Math.max(collapsedWidth, 380);
            return collapsedWidth;
        }

        width: Math.min(barWindow.width - 16, barWindow.isExpanded ? targetExpandedWidth : collapsedWidth)
        height: barWindow.isExpanded ? (topRow.height + 20 + drawerContainer.implicitHeight) : (topRow.height + 8)

        Behavior on width {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        // Top Status Bar Content Row
        RowLayout {
            id: topRow

            anchors {
                top: parent.top
                topMargin: 4
                horizontalCenter: parent.horizontalCenter
            }
            height: 28
            spacing: 6

            // 1. Workspaces
            Workspaces {}

            // 2. Center Clock & Date Button
            Rectangle {
                id: clockBtn
                implicitWidth: clockRow.implicitWidth + 16
                implicitHeight: 28
                radius: Math.max(2, Config.radius - 2)
                color: {
                    if (barWindow.activeTab === "clock")
                        return Color.primary;
                    if (clockMouse.containsMouse)
                        return Color.overlay;
                    return Color.surface;
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                RowLayout {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 8

                    ColumnLayout {
                        spacing: -1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: DateTimeService.currentDay
                            font.family: Config.textFont
                            font.pixelSize: 8
                            font.bold: true
                            color: (barWindow.activeTab === "clock") ? Color.background : Color.primary
                            lineHeight: 1.0
                        }

                        Text {
                            text: DateTimeService.currentMonthDate
                            font.family: Config.textFont
                            font.pixelSize: 9
                            color: (barWindow.activeTab === "clock") ? Color.background : Color.text
                            lineHeight: 1.0
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 11
                        color: (barWindow.activeTab === "clock") ? (Color.background + "66") : Color.overlay
                        opacity: 0.8
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: DateTimeService.currentTime
                        font.family: Config.textFont
                        font.pixelSize: 13
                        font.bold: true
                        color: (barWindow.activeTab === "clock") ? Color.background : Color.text
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleTab("clock")
                }
            }

            // 3. System Tray
            Tray {}

            // 4. Mirror Button
            Rectangle {
                id: mirrorBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: Math.max(2, Config.radius - 2)
                color: {
                    if (barWindow.activeTab === "mirror")
                        return Color.primary;
                    if (mirrorMouse.containsMouse)
                        return Color.overlay;
                    return Color.surface;
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                readonly property color accentColor: {
                    if (barWindow.activeTab === "mirror")
                        return Color.background;
                    if (MirrorService.isMirroring)
                        return Color.primary;
                    if (!MirrorService.hasWlMirror)
                        return Color.error ?? "#eb6f92";
                    if (MirrorService.hasExternalDisplay)
                        return Color.primary;
                    return Color.muted;
                }

                Text {
                    anchors.centerIn: parent
                    text: MirrorService.isMirroring ? "\ue308" : "\ue307"
                    font.family: Config.iconFont
                    font.pixelSize: 16
                    color: mirrorBtn.accentColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                    id: mirrorMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            MirrorService.toggleMirroring();
                        } else {
                            barWindow.toggleTab("mirror");
                        }
                    }
                }
            }

            // 5. Battery Button
            Rectangle {
                id: batBtn
                visible: BatteryService.hasBattery
                implicitWidth: batCol.implicitWidth + 14
                implicitHeight: 28
                radius: Math.max(2, Config.radius - 2)
                color: {
                    if (barWindow.activeTab === "battery")
                        return Color.primary;
                    if (batMouse.containsMouse)
                        return Color.overlay;
                    return Color.surface;
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                readonly property color accentColor: {
                    if (barWindow.activeTab === "battery")
                        return Color.background;
                    if (BatteryService.isCharging)
                        return Color.primary;
                    if (BatteryService.percentage <= 20)
                        return Color.error ?? "#eb6f92";
                    if (BatteryService.percentage <= 35)
                        return Color.warning ?? "#f6c177";
                    return Color.primary;
                }

                ColumnLayout {
                    id: batCol
                    anchors.centerIn: parent
                    spacing: -2

                    RowLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            visible: BatteryService.isCharging
                            text: "\ue3e7" // lightning
                            font.family: Config.iconFont
                            font.pixelSize: 9
                            color: batBtn.accentColor
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: BatteryService.isCharging ? "PWR" : "BAT"
                            font.family: Config.textFont
                            font.pixelSize: 8
                            font.bold: true
                            color: batBtn.accentColor
                            lineHeight: 1.0
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        text: BatteryService.percentage + "%"
                        font.family: Config.textFont
                        font.pixelSize: 11
                        font.bold: true
                        color: (barWindow.activeTab === "battery") ? Color.background : Color.text
                        lineHeight: 1.0
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleTab("battery")
                }
            }

            // 6. Quick Controls Button (Network + Bluetooth)
            Rectangle {
                id: quickBtn
                implicitWidth: quickRow.implicitWidth + 14
                implicitHeight: 28
                radius: Math.max(2, Config.radius - 2)
                color: {
                    if (barWindow.activeTab === "quick")
                        return Color.primary;
                    if (quickMouse.containsMouse)
                        return Color.overlay;
                    return Color.surface;
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                RowLayout {
                    id: quickRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        font.family: Config.iconFont
                        font.pixelSize: 15
                        text: {
                            if (NetworkService.ethernetConnected)
                                return "\ue868"; // settings_ethernet
                            if (NetworkService.wifiConnected)
                                return "\ue63e"; // wifi
                            if (NetworkService.wifiEnabled)
                                return "\ue63f"; // wifi_find
                            return "\ue648"; // wifi_off
                        }
                        color: {
                            if (barWindow.activeTab === "quick")
                                return Color.background;
                            if (NetworkService.ethernetConnected || NetworkService.wifiConnected)
                                return Color.primary;
                            return Color.muted;
                        }
                    }

                    Text {
                        font.family: Config.iconFont
                        font.pixelSize: 15
                        text: {
                            if (BluetoothService.connected)
                                return "\ue1a8"; // bluetooth_connected
                            if (BluetoothService.enabled)
                                return "\ue1a7"; // bluetooth
                            return "\ue1a9"; // bluetooth_disabled
                        }
                        color: {
                            if (barWindow.activeTab === "quick")
                                return Color.background;
                            if (!BluetoothService.enabled)
                                return Color.muted;
                            return BluetoothService.connected ? Color.primary : Color.text;
                        }
                    }
                }

                MouseArea {
                    id: quickMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleTab("quick")
                }
            }
        }

        // Expanded Drawer Container
        Item {
            id: drawerContainer
            anchors {
                top: topRow.bottom
                topMargin: 8
                left: parent.left
                right: parent.right
                leftMargin: 8
                rightMargin: 8
            }
            height: implicitHeight

            readonly property string currentTab: barWindow.activeTab !== "" ? barWindow.activeTab : barWindow.lastActiveTab

            implicitHeight: {
                if (currentTab === "clock")
                    return clockView.implicitHeight;
                if (currentTab === "quick")
                    return quickView.implicitHeight;
                if (currentTab === "battery")
                    return batteryView.implicitHeight;
                if (currentTab === "mirror")
                    return mirrorView.implicitHeight;
                return 0;
            }
            visible: opacity > 0.001
            opacity: barWindow.isExpanded ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: barWindow.isExpanded ? 130 : 80
                    easing.type: Easing.OutCubic
                }
            }

            ClockView {
                id: clockView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "clock"
                onCollapseRequested: barWindow.collapse()
            }

            QuickView {
                id: quickView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "quick"
                onCollapseRequested: barWindow.collapse()
            }

            BatteryView {
                id: batteryView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "battery"
                onCollapseRequested: barWindow.collapse()
            }

            MirrorView {
                id: mirrorView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "mirror"
                onCollapseRequested: barWindow.collapse()
            }
        }
    }
}
