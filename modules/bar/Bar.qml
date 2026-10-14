import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.configs
import qs.services
import qs.modules.notifications

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: 42
    implicitHeight: 650
    color: "transparent"
    visible: !LockScreenService.isLocked

    mask: Region {
        item: barSurface
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
            if (BarService.isExpanded) {
                BarService.collapse();
                event.accepted = true;
            }
        }

        readonly property bool hasToast: NotificationService.toasts.length > 0 && !BarService.isExpanded
        readonly property real toastHeight: hasToast ? (toastArea.implicitHeight + 8) : 0
        readonly property real collapsedWidth: topRow.implicitWidth + 6
        readonly property real targetExpandedWidth: {
            const tab = BarService.activeTab !== "" ? BarService.activeTab : BarService.lastActiveTab;
            let viewWidth = 0;
            if (tab === "clock")
                viewWidth = clockView.implicitWidth;
            else if (tab === "quick")
                viewWidth = quickView.implicitWidth;
            else if (tab === "battery")
                viewWidth = batteryView.implicitWidth;
            else if (tab === "mirror")
                viewWidth = mirrorView.implicitWidth;
            else if (tab === "notifications")
                viewWidth = notificationView.implicitWidth;
            // 16 = drawerContainer left+right margins (8+8)
            return Math.max(collapsedWidth, viewWidth + 16);
        }

        width: {
            if (BarService.isExpanded)
                return Math.min(barWindow.width - 16, targetExpandedWidth);
            if (hasToast)
                return Math.min(barWindow.width - 16, Math.max(collapsedWidth, 380));
            return Math.min(barWindow.width - 16, collapsedWidth);
        }

        height: {
            if (BarService.isExpanded)
                return topRow.height + 20 + drawerContainer.implicitHeight;
            if (hasToast)
                return topRow.height + 12 + toastHeight;
            return topRow.height + 8;
        }

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
            height: 32
            spacing: 2

            // 1. Workspaces
            Workspaces {}

            // 2. Center Clock & Date Button
            Rectangle {
                id: clockBtn
                implicitWidth: clockRow.implicitWidth + 16
                implicitHeight: 32
                radius: 4
                color: {
                    if (BarService.activeTab === "clock")
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
                            color: (BarService.activeTab === "clock") ? Color.background : Color.primary
                            lineHeight: 1.0
                        }

                        Text {
                            text: DateTimeService.currentMonthDate
                            font.family: Config.textFont
                            font.pixelSize: 9
                            color: (BarService.activeTab === "clock") ? Color.background : Color.text
                            lineHeight: 1.0
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 11
                        color: (BarService.activeTab === "clock") ? (Color.background + "66") : Color.subtle
                        opacity: 0.8
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: DateTimeService.currentTime
                        font.family: Config.textFont
                        font.pixelSize: 13
                        font.bold: true
                        color: (BarService.activeTab === "clock") ? Color.background : Color.text
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarService.toggleTab("clock")
                }
            }

            // 3. System Tray
            Tray {}

            // Notification Button
            Rectangle {
                id: notifBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 4
                color: {
                    if (BarService.activeTab === "notifications")
                        return Color.primary;
                    if (notifMouse.containsMouse)
                        return Color.overlay;
                    return Color.surface;
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: NotificationService.count > 0 ? "\ue7f4" : "\ue7f5"
                    font.family: Config.iconFont
                    font.pixelSize: 16
                    color: (BarService.activeTab === "notifications") ? Color.background : (NotificationService.count > 0 ? Color.primary : Color.text)
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarService.toggleTab("notifications")
                }
            }

            // 4. Mirror Button
            Rectangle {
                id: mirrorBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 4
                color: {
                    if (BarService.activeTab === "mirror")
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
                    if (BarService.activeTab === "mirror")
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
                            BarService.toggleTab("mirror");
                        }
                    }
                }
            }

            // 5. Battery Button
            Rectangle {
                id: batBtn
                visible: BatteryService.hasBattery
                implicitWidth: batCol.implicitWidth + 14
                implicitHeight: 32
                radius: 4
                color: {
                    if (BarService.activeTab === "battery")
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
                    if (BarService.activeTab === "battery")
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
                        color: (BarService.activeTab === "battery") ? Color.background : Color.text
                        lineHeight: 1.0
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarService.toggleTab("battery")
                }
            }

            // 6. Quick Controls Button (Network + Bluetooth)
            Rectangle {
                id: quickBtn
                implicitWidth: quickRow.implicitWidth + 14
                implicitHeight: 32
                topLeftRadius: 4
                bottomLeftRadius: 4
                topRightRadius: Config.radius
                bottomRightRadius: Config.radius
                color: {
                    if (BarService.activeTab === "quick")
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
                            if (BarService.activeTab === "quick")
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
                            if (BarService.activeTab === "quick")
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
                    onClicked: BarService.toggleTab("quick")
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

            readonly property string currentTab: BarService.activeTab !== "" ? BarService.activeTab : BarService.lastActiveTab

            implicitHeight: {
                if (currentTab === "clock")
                    return clockView.implicitHeight;
                if (currentTab === "quick")
                    return quickView.implicitHeight;
                if (currentTab === "battery")
                    return batteryView.implicitHeight;
                if (currentTab === "mirror")
                    return mirrorView.implicitHeight;
                if (currentTab === "notifications")
                    return notificationView.implicitHeight;
                return 0;
            }

            implicitWidth: {
                if (currentTab === "clock")
                    return clockView.implicitWidth;
                if (currentTab === "quick")
                    return quickView.implicitWidth;
                if (currentTab === "battery")
                    return batteryView.implicitWidth;
                if (currentTab === "mirror")
                    return mirrorView.implicitWidth;
                if (currentTab === "notifications")
                    return notificationView.implicitWidth;
                return 0;
            }

            visible: opacity > 0.001
            opacity: BarService.isExpanded ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: BarService.isExpanded ? 130 : 80
                    easing.type: Easing.OutCubic
                }
            }

            ClockView {
                id: clockView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "clock"
                onCollapseRequested: BarService.collapse()
            }

            QuickView {
                id: quickView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "quick"
                onCollapseRequested: BarService.collapse()
            }

            BatteryView {
                id: batteryView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "battery"
                onCollapseRequested: BarService.collapse()
            }

            MirrorView {
                id: mirrorView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "mirror"
                onCollapseRequested: BarService.collapse()
            }

            NotificationView {
                id: notificationView
                anchors.fill: parent
                visible: drawerContainer.currentTab === "notifications"
                onCollapseRequested: BarService.collapse()
            }
        }

        // Active Toast Popup Container (Integrated in Bar)
        ColumnLayout {
            id: toastArea
            anchors {
                top: topRow.bottom
                topMargin: 8
                left: parent.left
                right: parent.right
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 6
            visible: barSurface.hasToast
            opacity: barSurface.hasToast ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: barSurface.hasToast ? NotificationService.toasts : []

                delegate: Rectangle {
                    id: toastCard
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: toastItem.implicitHeight + 14
                    radius: Math.max(4, Config.radius - 4)
                    color: Color.surface

                    NotificationItem {
                        id: toastItem
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: 8
                        }
                        itemData: toastCard.modelData
                        isToast: true
                    }
                }
            }
        }
    }
}
