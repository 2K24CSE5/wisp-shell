import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.configs
import qs.components
import qs.services

ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: 16

    // State for Wi-Fi inline password prompt & hidden network form
    property string selectedPromptSsid: ""
    property string wifiPasswordInput: ""
    property bool showWifiPassword: false

    property bool showHiddenNetworkForm: false
    property string hiddenSsidInput: ""
    property string hiddenPasswordInput: ""
    property bool hiddenSecurityIsWpa: true
    property bool showHiddenPassword: false

    property string ssidSearchQuery: ""
    property string copiedKey: ""

    Timer {
        id: copyFeedbackTimer
        interval: 1800
        onTriggered: root.copiedKey = ""
    }

    function triggerCopy(key: string, text: string): void {
        if (!text)
            return;
        NetworkService.copyToClipboard(text);
        root.copiedKey = key;
        copyFeedbackTimer.restart();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 1: Status & Overview Banner
    // ─────────────────────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: "Connection Status"
        iconText: "\ue88e"

        // Prominent Status Hero Box
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: bannerRow.implicitHeight + 24
            radius: Config.radius
            color: Color.overlay
            border.width: 1
            border.color: (NetworkService.wifiConnected || NetworkService.ethernetConnected) ? Qt.alpha(Color.primary, 0.3) : Qt.alpha(Color.muted, 0.2)

            RowLayout {
                id: bannerRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 14

                // Network Icon Badge
                Rectangle {
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: width / 2
                    color: (NetworkService.wifiConnected || NetworkService.ethernetConnected) ? Qt.alpha(Color.primary, 0.15) : Qt.alpha(Color.muted, 0.15)
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        font.family: Config.iconFont
                        font.pixelSize: 22
                        color: (NetworkService.wifiConnected || NetworkService.ethernetConnected) ? Color.primary : Color.muted
                        text: {
                            if (NetworkService.ethernetConnected)
                                return "\ue868"; // settings_ethernet
                            if (NetworkService.wifiConnected)
                                return "\ue63e"; // wifi
                            if (NetworkService.wifiEnabled)
                                return "\ue63f"; // wifi_find
                            return "\ue648"; // wifi_off
                        }
                    }
                }

                // Status Information
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    RowLayout {
                        spacing: 8
                        Text {
                            font.family: Config.textFont
                            font.pixelSize: 15
                            font.bold: true
                            color: Color.text
                            text: {
                                if (NetworkService.ethernetConnected)
                                    return "Connected via Ethernet";
                                if (NetworkService.wifiConnected)
                                    return "Connected to " + NetworkService.connectedWifiSsid;
                                if (!NetworkService.networkingEnabled)
                                    return "Airplane Mode Active";
                                return "Not Connected";
                            }
                        }

                        // Status Pill
                        Rectangle {
                            implicitWidth: statusText.implicitWidth + 12
                            implicitHeight: 20
                            radius: 10
                            color: {
                                if (NetworkService.connectivity === "full" || NetworkService.wifiConnected || NetworkService.ethernetConnected)
                                    return Qt.alpha(Color.primary, 0.2);
                                return Qt.alpha(Color.muted, 0.2);
                            }

                            Text {
                                id: statusText
                                anchors.centerIn: parent
                                font.family: Config.textFont
                                font.pixelSize: 10
                                font.bold: true
                                color: (NetworkService.connectivity === "full" || NetworkService.wifiConnected || NetworkService.ethernetConnected) ? Color.primary : Color.muted
                                text: {
                                    if (NetworkService.connectivity === "full")
                                        return "ONLINE";
                                    if (NetworkService.connectivity === "limited")
                                        return "LIMITED";
                                    return "OFFLINE";
                                }
                            }
                        }
                    }

                    Text {
                        font.family: Config.textFont
                        font.pixelSize: 11
                        color: Color.muted
                        Layout.fillWidth: true
                        text: {
                            const activeIp = NetworkService.wifiIp4 || NetworkService.ethernetIp4;
                            const gateway = NetworkService.wifiGateway || NetworkService.ethernetGateway;
                            if (activeIp) {
                                return "IPv4: " + activeIp.split("/")[0] + (gateway ? " • Gateway: " + gateway : "");
                            }
                            return "No active network interface assigned.";
                        }
                    }
                }

                // Ping Diagnostic Pill / Button
                Rectangle {
                    implicitWidth: pingContentRow.implicitWidth + 16
                    implicitHeight: 34
                    radius: Config.radius
                    color: Color.surface
                    border.width: 1
                    border.color: pingMouse.containsMouse ? Color.primary : Color.overlay
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        id: pingContentRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            font.family: Config.iconFont
                            font.pixelSize: 14
                            color: NetworkService.isPinging ? Color.primary : Color.muted
                            text: "\ue164" // speed / flag
                        }

                        Text {
                            font.family: Config.textFont
                            font.pixelSize: 11
                            font.bold: true
                            color: Color.text
                            text: NetworkService.isPinging ? "Testing..." : (NetworkService.pingLatency !== "--" ? NetworkService.pingLatency : "Ping")
                        }
                    }

                    MouseArea {
                        id: pingMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.testPing()
                    }
                }
            }
        }

        // Airplane Mode CardRow
        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue195" // airplanemode_active
            title: "Airplane mode"
            subtitle: "Turn off all wireless radios and network connectivity"

            Toggle {
                checked: !NetworkService.networkingEnabled
                leftText: "Off"
                rightText: "On"
                onToggled: checked => NetworkService.toggleNetworking()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 2: Wi-Fi Management
    // ─────────────────────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: "Wi-Fi"
        iconText: "\ue63e"

        // Master Wi-Fi Power Switch
        CardRow {
            Layout.fillWidth: true
            leadingIcon: NetworkService.wifiEnabled ? "\ue63e" : "\ue648"
            title: "Wi-Fi adapter"
            subtitle: NetworkService.wifiEnabled ? (NetworkService.wifiConnected ? "Connected to " + NetworkService.connectedWifiSsid : "Enabled") : "Disabled"

            RowLayout {
                spacing: 8

                Button {
                    visible: NetworkService.wifiEnabled
                    variant: "secondary"
                    buttonHeight: 34
                    leadingIcon: "\ue5d5" // refresh
                    text: NetworkService.isScanning ? "Scanning..." : "Rescan"
                    enabled: !NetworkService.isScanning
                    onClicked: NetworkService.scanWifi()
                }

                Toggle {
                    checked: NetworkService.wifiEnabled
                    leftText: "Off"
                    rightText: "On"
                    onToggled: checked => NetworkService.toggleWifiRadio()
                }
            }
        }

        // Error message callout (if any connection attempt failed)
        Rectangle {
            visible: NetworkService.lastError.length > 0
            Layout.fillWidth: true
            implicitHeight: errorRow.implicitHeight + 16
            radius: Config.radius
            color: Qt.alpha(Color.error || "#ef4444", 0.12)
            border.width: 1
            border.color: Qt.alpha(Color.error || "#ef4444", 0.3)

            RowLayout {
                id: errorRow
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "\ue000" // warning/error icon
                    font.family: Config.iconFont
                    font.pixelSize: 18
                    color: Color.error || "#ef4444"
                }

                Text {
                    Layout.fillWidth: true
                    text: NetworkService.lastError
                    font.family: Config.textFont
                    font.pixelSize: 12
                    color: Color.text
                    wrapMode: Text.WordWrap
                }

                Button {
                    variant: "ghost"
                    buttonHeight: 28
                    leadingIcon: "\ue5cd"
                    onClicked: NetworkService.clearError()
                }
            }
        }

        // Wi-Fi Disabled Placeholder
        Rectangle {
            visible: !NetworkService.wifiEnabled
            Layout.fillWidth: true
            implicitHeight: 90
            radius: Config.radius
            color: Color.overlay

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Wi-Fi is currently disabled"
                    font.family: Config.textFont
                    font.pixelSize: 12
                    color: Color.muted
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    variant: "primary"
                    buttonHeight: 32
                    text: "Turn On Wi-Fi"
                    onClicked: NetworkService.toggleWifiRadio()
                }
            }
        }

        // Active Connected Network Highlight Box
        Rectangle {
            visible: NetworkService.wifiEnabled && NetworkService.wifiConnected
            Layout.fillWidth: true
            implicitHeight: activeWifiCol.implicitHeight + 20
            radius: Config.radius
            color: Color.overlay
            border.width: 1
            border.color: Qt.alpha(Color.primary, 0.4)

            ColumnLayout {
                id: activeWifiCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "\ue63e"
                        font.family: Config.iconFont
                        font.pixelSize: 18
                        color: Color.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 6
                            Text {
                                text: NetworkService.connectedWifiSsid
                                font.family: Config.textFont
                                font.pixelSize: 13
                                font.bold: true
                                color: Color.text
                            }

                            Rectangle {
                                implicitWidth: 64
                                implicitHeight: 18
                                radius: 9
                                color: Qt.alpha(Color.primary, 0.2)

                                Text {
                                    anchors.centerIn: parent
                                    text: "Connected"
                                    font.family: Config.textFont
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Color.primary
                                }
                            }
                        }

                        Text {
                            text: {
                                const details = [];
                                if (NetworkService.connectedWifiSignal > 0)
                                    details.push(NetworkService.connectedWifiSignal + "% Signal");
                                if (NetworkService.connectedWifiFreq)
                                    details.push(NetworkService.connectedWifiFreq);
                                if (NetworkService.connectedWifiRate)
                                    details.push(NetworkService.connectedWifiRate);
                                if (NetworkService.connectedWifiSecurity)
                                    details.push(NetworkService.connectedWifiSecurity);
                                return details.join(" • ");
                            }
                            font.family: Config.textFont
                            font.pixelSize: 11
                            color: Color.muted
                        }
                    }

                    Button {
                        variant: "secondary"
                        buttonHeight: 30
                        text: "Disconnect"
                        onClicked: NetworkService.disconnectWifi()
                    }
                }

                // IP Quick info
                Rectangle {
                    visible: NetworkService.wifiIp4.length > 0
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(Color.overlay, 0.8)
                }

                RowLayout {
                    visible: NetworkService.wifiIp4.length > 0
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        font.family: Config.textFont
                        font.pixelSize: 10
                        color: Color.muted
                        text: "IP: " + NetworkService.wifiIp4.split("/")[0]
                    }

                    Text {
                        visible: NetworkService.wifiGateway.length > 0
                        font.family: Config.textFont
                        font.pixelSize: 10
                        color: Color.muted
                        text: "Gateway: " + NetworkService.wifiGateway
                    }

                    Text {
                        visible: NetworkService.wifiHwAddr.length > 0
                        font.family: Config.textFont
                        font.pixelSize: 10
                        color: Color.muted
                        text: "MAC: " + NetworkService.wifiHwAddr
                    }
                }
            }
        }

        // ── Available Networks Header & Search ────────────────────────────────
        ColumnLayout {
            visible: NetworkService.wifiEnabled
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "AVAILABLE NETWORKS (" + filteredWifiList.count + ")"
                    font.family: Config.textFont
                    font.pixelSize: 10
                    font.bold: true
                    color: Color.muted
                    Layout.fillWidth: true
                }
            }

            Input {
                Layout.fillWidth: true
                inputHeight: 36
                leadingIcon: "\ue8b6" // search
                placeholderText: "Search available networks..."
                showClearButton: true
                onTextEdited: root.ssidSearchQuery = text
                onCleared: root.ssidSearchQuery = ""
            }

            // Available Networks Repeater
            ListView {
                id: filteredWifiList
                Layout.fillWidth: true
                implicitHeight: contentHeight
                interactive: false
                clip: true
                spacing: 4

                model: {
                    if (!NetworkService.wifiEnabled)
                        return [];
                    const q = root.ssidSearchQuery.toLowerCase().trim();
                    return NetworkService.accessPoints.filter(ap => {
                        if (!q)
                            return true;
                        return (ap.ssid || "").toLowerCase().includes(q);
                    });
                }

                delegate: Rectangle {
                    id: apDelegateItem
                    required property var modelData

                    readonly property bool isCurrentConnected: modelData.connected === true
                    readonly property bool isSelectedForPrompt: root.selectedPromptSsid === modelData.ssid
                    readonly property bool isConnectingThis: NetworkService.isConnecting && NetworkService.connectingSsid === modelData.ssid

                    width: filteredWifiList.width
                    implicitHeight: isSelectedForPrompt ? promptCol.implicitHeight + 20 : 44
                    radius: Config.radius
                    color: isCurrentConnected ? Qt.alpha(Color.primary, 0.08) : (apMouse.containsMouse ? Color.overlay : "transparent")
                    border.width: 1
                    border.color: isSelectedForPrompt ? Color.primary : (isCurrentConnected ? Qt.alpha(Color.primary, 0.3) : "transparent")

                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }

                    ColumnLayout {
                        id: promptCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        // Main Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Signal Icon
                            Text {
                                text: "\ue63e"
                                font.family: Config.iconFont
                                font.pixelSize: 18
                                color: isCurrentConnected ? Color.primary : Color.text
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Network SSID and Details
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: modelData.ssid || "Hidden Network"
                                        font.family: Config.textFont
                                        font.pixelSize: 12
                                        font.bold: isCurrentConnected
                                        color: isCurrentConnected ? Color.primary : Color.text
                                    }

                                    // Saved badge
                                    Rectangle {
                                        visible: modelData.isSaved === true && !isCurrentConnected
                                        implicitWidth: 42
                                        implicitHeight: 16
                                        radius: 4
                                        color: Color.overlay

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Saved"
                                            font.family: Config.textFont
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Color.muted
                                        }
                                    }

                                    // Band badge (5G / 2.4G)
                                    Rectangle {
                                        visible: modelData.band !== undefined
                                        implicitWidth: 32
                                        implicitHeight: 16
                                        radius: 4
                                        color: Color.overlay

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.band === "5 GHz" ? "5G" : "2.4G"
                                            font.family: Config.textFont
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Color.muted
                                        }
                                    }
                                }

                                Text {
                                    text: (modelData.signal || 0) + "% Signal • " + (modelData.security || "Open")
                                    font.family: Config.textFont
                                    font.pixelSize: 10
                                    color: Color.muted
                                }
                            }

                            // Security lock icon
                            Text {
                                visible: modelData.requiresPassword === true
                                text: "\ue897" // lock
                                font.family: Config.iconFont
                                font.pixelSize: 14
                                color: Color.muted
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Connecting Spinner / Text
                            Text {
                                visible: isConnectingThis
                                text: "Connecting..."
                                font.family: Config.textFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Color.primary
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Connect / Disconnect Action Button
                            Button {
                                visible: !isSelectedForPrompt && !isConnectingThis
                                variant: isCurrentConnected ? "secondary" : (modelData.isSaved ? "secondary" : "ghost")
                                buttonHeight: 28
                                text: isCurrentConnected ? "Disconnect" : "Connect"
                                onClicked: {
                                    if (isCurrentConnected) {
                                        NetworkService.disconnectWifi();
                                    } else if (modelData.isSaved || !modelData.requiresPassword) {
                                        NetworkService.connectWifi(modelData.ssid);
                                    } else {
                                        root.selectedPromptSsid = (root.selectedPromptSsid === modelData.ssid) ? "" : modelData.ssid;
                                        root.wifiPasswordInput = "";
                                        root.showWifiPassword = false;
                                    }
                                }
                            }
                        }

                        // Inline Password Entry Form
                        ColumnLayout {
                            visible: isSelectedForPrompt
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Color.overlay
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Input {
                                    id: inlinePasswordInput
                                    Layout.fillWidth: true
                                    inputHeight: 34
                                    leadingIcon: "\ue2c2" // key
                                    placeholderText: "Enter Wi-Fi password..."
                                    echoMode: root.showWifiPassword ? TextInput.Normal : TextInput.Password
                                    text: root.wifiPasswordInput
                                    onTextEdited: root.wifiPasswordInput = text
                                    onAccepted: {
                                        NetworkService.connectWifiWithPassword(modelData.ssid, root.wifiPasswordInput);
                                        root.selectedPromptSsid = "";
                                    }
                                }

                                Button {
                                    variant: "ghost"
                                    buttonHeight: 34
                                    leadingIcon: root.showWifiPassword ? "\ue8f5" : "\ue8f4" // visibility off / on
                                    onClicked: root.showWifiPassword = !root.showWifiPassword
                                }

                                Button {
                                    variant: "primary"
                                    buttonHeight: 34
                                    text: "Connect"
                                    enabled: root.wifiPasswordInput.length > 0
                                    onClicked: {
                                        NetworkService.connectWifiWithPassword(modelData.ssid, root.wifiPasswordInput);
                                        root.selectedPromptSsid = "";
                                    }
                                }

                                Button {
                                    variant: "ghost"
                                    buttonHeight: 34
                                    text: "Cancel"
                                    onClicked: root.selectedPromptSsid = ""
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: apMouse
                        anchors.fill: parent
                        enabled: !isSelectedForPrompt
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isCurrentConnected) {
                                return;
                            }
                            if (modelData.isSaved || !modelData.requiresPassword) {
                                NetworkService.connectWifi(modelData.ssid);
                            } else {
                                root.selectedPromptSsid = (root.selectedPromptSsid === modelData.ssid) ? "" : modelData.ssid;
                                root.wifiPasswordInput = "";
                                root.showWifiPassword = false;
                            }
                        }
                    }
                }
            }

            Text {
                visible: filteredWifiList.count === 0 && NetworkService.wifiEnabled
                text: NetworkService.isScanning ? "Scanning for available networks..." : "No wireless networks found"
                font.family: Config.textFont
                font.pixelSize: 11
                color: Color.muted
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            // ── Connect to Hidden Network Button / Form ───────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: hiddenCol.implicitHeight + 16
                radius: Config.radius
                color: Color.overlay
                border.width: 1
                border.color: root.showHiddenNetworkForm ? Color.primary : "transparent"

                ColumnLayout {
                    id: hiddenCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    CardRow {
                        Layout.fillWidth: true
                        leadingIcon: "\ue145" // add
                        title: "Connect to hidden network..."
                        subtitle: "Manually configure an unbroadcasted SSID"
                        trailingIcon: root.showHiddenNetworkForm ? "\ue5ce" : "\ue5cf"
                        clickable: true
                        onClicked: root.showHiddenNetworkForm = !root.showHiddenNetworkForm
                    }

                    ColumnLayout {
                        visible: root.showHiddenNetworkForm
                        Layout.fillWidth: true
                        spacing: 8

                        Input {
                            Layout.fillWidth: true
                            inputHeight: 36
                            leadingIcon: "\ue63e"
                            placeholderText: "Network name (SSID)..."
                            text: root.hiddenSsidInput
                            onTextEdited: root.hiddenSsidInput = text
                        }

                        CardRow {
                            Layout.fillWidth: true
                            title: "Security"
                            subtitle: root.hiddenSecurityIsWpa ? "WPA/WPA2/WPA3 Personal" : "Open / None"

                            Toggle {
                                checked: root.hiddenSecurityIsWpa
                                leftText: "Open"
                                rightText: "WPA"
                                onToggled: checked => root.hiddenSecurityIsWpa = checked
                            }
                        }

                        Input {
                            visible: root.hiddenSecurityIsWpa
                            Layout.fillWidth: true
                            inputHeight: 36
                            leadingIcon: "\ue2c2"
                            placeholderText: "Password..."
                            echoMode: root.showHiddenPassword ? TextInput.Normal : TextInput.Password
                            text: root.hiddenPasswordInput
                            onTextEdited: root.hiddenPasswordInput = text
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignRight
                            spacing: 8

                            Button {
                                variant: "ghost"
                                text: "Cancel"
                                onClicked: {
                                    root.showHiddenNetworkForm = false;
                                    root.hiddenSsidInput = "";
                                    root.hiddenPasswordInput = "";
                                }
                            }

                            Button {
                                variant: "primary"
                                text: "Connect"
                                enabled: root.hiddenSsidInput.trim().length > 0
                                onClicked: {
                                    NetworkService.connectHiddenWifi(root.hiddenSsidInput.trim(), root.hiddenPasswordInput, root.hiddenSecurityIsWpa);
                                    root.showHiddenNetworkForm = false;
                                    root.hiddenSsidInput = "";
                                    root.hiddenPasswordInput = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 3: Wired Connection (Ethernet)
    // ─────────────────────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: "Wired Connection (Ethernet)"
        iconText: "\ue868"

        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue868"
            title: NetworkService.ethernetDevice ? ("Interface: " + NetworkService.ethernetDevice) : "Wired adapter"
            subtitle: {
                if (NetworkService.ethernetConnected)
                    return "Connected • " + (NetworkService.ethernetName || "Wired connection");
                if (NetworkService.ethernetState === "unavailable")
                    return "Cable unplugged";
                return "Disconnected";
            }

            Button {
                variant: NetworkService.ethernetConnected ? "secondary" : "ghost"
                buttonHeight: 32
                enabled: NetworkService.ethernetDevice.length > 0 && NetworkService.ethernetState !== "unavailable"
                text: NetworkService.ethernetConnected ? "Disconnect" : "Connect"
                onClicked: {
                    if (NetworkService.ethernetConnected) {
                        NetworkService.disconnectEthernet();
                    } else {
                        NetworkService.connectEthernet();
                    }
                }
            }
        }

        // Ethernet Details Row (when connected or device present)
        ColumnLayout {
            visible: NetworkService.ethernetDevice.length > 0
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Color.overlay
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Text {
                    text: "MAC: " + (NetworkService.ethernetHwAddr || "--")
                    font.family: Config.textFont
                    font.pixelSize: 11
                    color: Color.muted
                }

                Text {
                    visible: NetworkService.ethernetIp4.length > 0
                    text: "IPv4: " + NetworkService.ethernetIp4.split("/")[0]
                    font.family: Config.textFont
                    font.pixelSize: 11
                    color: Color.muted
                }

                Text {
                    visible: NetworkService.ethernetGateway.length > 0
                    text: "Gateway: " + NetworkService.ethernetGateway
                    font.family: Config.textFont
                    font.pixelSize: 11
                    color: Color.muted
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 4: Saved / Known Networks
    // ─────────────────────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: "Saved Networks"
        iconText: "\ue1bc"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            ListView {
                id: savedList
                Layout.fillWidth: true
                implicitHeight: contentHeight
                interactive: false
                clip: true
                spacing: 4

                model: NetworkService.savedConnections.filter(c => c.type === "wifi")

                delegate: Rectangle {
                    required property var modelData
                    width: savedList.width
                    implicitHeight: 46
                    radius: Config.radius
                    color: Color.overlay

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "\ue63e"
                            font.family: Config.iconFont
                            font.pixelSize: 16
                            color: Color.muted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name
                                font.family: Config.textFont
                                font.pixelSize: 12
                                font.bold: true
                                color: Color.text
                            }

                            Text {
                                text: modelData.autoconnect ? "Auto-connect enabled" : "Manual connect only"
                                font.family: Config.textFont
                                font.pixelSize: 10
                                color: Color.muted
                            }
                        }

                        // Auto-connect toggle
                        Toggle {
                            checked: modelData.autoconnect === true
                            leftText: "Manual"
                            rightText: "Auto"
                            onToggled: checked => NetworkService.setAutoconnect(modelData.uuid, checked)
                        }

                        // Forget Network Button
                        Button {
                            variant: "danger"
                            buttonHeight: 30
                            leadingIcon: "\ue872" // trash
                            onClicked: NetworkService.forgetConnection(modelData.uuid)
                        }
                    }
                }
            }

            Text {
                visible: savedList.count === 0
                text: "No saved Wi-Fi profiles found."
                font.family: Config.textFont
                font.pixelSize: 11
                color: Color.muted
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 5: Advanced Technical Details & Hardware
    // ─────────────────────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: "Hardware & IP Details"
        iconText: "\ue8b8"

        // Primary Interface
        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue869" // build/tools
            title: "Active interface"
            subtitle: {
                if (NetworkService.ethernetConnected)
                    return NetworkService.ethernetDevice + " (Ethernet)";
                if (NetworkService.wifiConnected)
                    return NetworkService.wifiDevice + " (Wireless 802.11)";
                return "None";
            }
        }

        // IPv4 Address
        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue1db"
            title: "IPv4 address"
            subtitle: {
                const ip = NetworkService.wifiIp4 || NetworkService.ethernetIp4;
                return ip || "Not assigned";
            }

            Button {
                variant: "secondary"
                buttonHeight: 30
                leadingIcon: root.copiedKey === "ip4" ? "\ue5ca" : "\ue149"
                text: root.copiedKey === "ip4" ? "Copied" : "Copy"
                enabled: Boolean(NetworkService.wifiIp4 || NetworkService.ethernetIp4)
                onClicked: {
                    const ip = (NetworkService.wifiIp4 || NetworkService.ethernetIp4 || "").split("/")[0];
                    root.triggerCopy("ip4", ip);
                }
            }
        }

        // Gateway
        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue879" // router
            title: "Default gateway"
            subtitle: {
                const gw = NetworkService.wifiGateway || NetworkService.ethernetGateway;
                return gw || "Not assigned";
            }

            Button {
                variant: "secondary"
                buttonHeight: 30
                leadingIcon: root.copiedKey === "gw" ? "\ue5ca" : "\ue149"
                text: root.copiedKey === "gw" ? "Copied" : "Copy"
                enabled: Boolean(NetworkService.wifiGateway || NetworkService.ethernetGateway)
                onClicked: {
                    const gw = NetworkService.wifiGateway || NetworkService.ethernetGateway;
                    root.triggerCopy("gw", gw);
                }
            }
        }

        // DNS Server
        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue80d" // share / dns
            title: "DNS servers"
            subtitle: {
                const dns = NetworkService.wifiDns || NetworkService.ethernetDns;
                return dns || "Not assigned";
            }

            Button {
                variant: "secondary"
                buttonHeight: 30
                leadingIcon: root.copiedKey === "dns" ? "\ue5ca" : "\ue149"
                text: root.copiedKey === "dns" ? "Copied" : "Copy"
                enabled: Boolean(NetworkService.wifiDns || NetworkService.ethernetDns)
                onClicked: {
                    const dns = NetworkService.wifiDns || NetworkService.ethernetDns;
                    root.triggerCopy("dns", dns);
                }
            }
        }

        // MAC Address
        CardRow {
            Layout.fillWidth: true
            leadingIcon: "\ue32a" // devices / memory
            title: "Hardware (MAC) address"
            subtitle: {
                const mac = NetworkService.wifiHwAddr || NetworkService.ethernetHwAddr;
                return mac || "Not available";
            }

            Button {
                variant: "secondary"
                buttonHeight: 30
                leadingIcon: root.copiedKey === "mac" ? "\ue5ca" : "\ue149"
                text: root.copiedKey === "mac" ? "Copied" : "Copy"
                enabled: Boolean(NetworkService.wifiHwAddr || NetworkService.ethernetHwAddr)
                onClicked: {
                    const mac = NetworkService.wifiHwAddr || NetworkService.ethernetHwAddr;
                    root.triggerCopy("mac", mac);
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
