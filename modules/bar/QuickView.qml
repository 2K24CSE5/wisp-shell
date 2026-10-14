import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.configs
import qs.services
import qs.components

Item {
    id: root

    signal collapseRequested()

    property bool drawerExpanded: false
    property bool isWifiView: true

    implicitHeight: contentCol.implicitHeight + 12

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 6
        spacing: 12

        // Header Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            WispIcon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                iconColor: Color.text
            }

            Text {
                text: "Quick Settings"
                font.family: Config.textFont
                font.pixelSize: 13
                font.bold: true
                color: Color.text
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            CloseButton {
                size: 26
                iconSize: 16
                Layout.alignment: Qt.AlignVCenter
                onClicked: root.collapseRequested()
            }
        }

        // QuickTile Controls Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Wi-Fi Pill Group
            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                QuickTile {
                    Layout.fillWidth: true
                    title: NetworkService.ethernetConnected ? "Ethernet" : "Wi-Fi"
                    statusText: {
                        if (NetworkService.ethernetConnected)
                            return "Connected";
                        if (NetworkService.wifiConnected)
                            return NetworkService.connectedWifiSsid || "Connected";
                        return NetworkService.wifiEnabled ? "Disconnected" : "Off";
                    }
                    iconText: NetworkService.ethernetConnected ? "settings_ethernet" : (NetworkService.wifiConnected ? "wifi" : (NetworkService.wifiEnabled ? "wifi_find" : "wifi_off"))
                    active: NetworkService.ethernetConnected || NetworkService.wifiEnabled
                    onClicked: NetworkService.toggleWifiRadio()
                }

                QuickTileButton {
                    active: NetworkService.ethernetConnected || NetworkService.wifiEnabled
                    expanded: root.drawerExpanded && root.isWifiView
                    onClicked: {
                        if (root.drawerExpanded && root.isWifiView) {
                            root.drawerExpanded = false;
                        } else {
                            root.isWifiView = true;
                            root.drawerExpanded = true;
                            if (!NetworkService.wifiEnabled) {
                                NetworkService.toggleWifiRadio();
                            }
                            NetworkService.scanWifi();
                        }
                    }
                }
            }

            // Hairline Separator
            Rectangle {
                implicitWidth: 1
                implicitHeight: 24
                color: Color.overlay
                opacity: 0.8
                Layout.alignment: Qt.AlignVCenter
            }

            // Bluetooth Pill Group
            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                QuickTile {
                    Layout.fillWidth: true
                    title: "Bluetooth"
                    statusText: {
                        if (!BluetoothService.enabled)
                            return "Off";
                        if (BluetoothService.connected) {
                            const name = BluetoothService.connectedDeviceName || "Connected";
                            return (BluetoothService.connectedDeviceBattery >= 0) ? name + " (" + BluetoothService.connectedDeviceBattery + "%)" : name;
                        }
                        return "Disconnected";
                    }
                    iconText: BluetoothService.connected ? "bluetooth_connected" : (BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled")
                    active: BluetoothService.enabled
                    onClicked: BluetoothService.togglePower()
                }

                QuickTileButton {
                    active: BluetoothService.enabled
                    expanded: root.drawerExpanded && !root.isWifiView
                    onClicked: {
                        if (root.drawerExpanded && !root.isWifiView) {
                            root.drawerExpanded = false;
                        } else {
                            root.isWifiView = false;
                            root.drawerExpanded = true;
                            if (!BluetoothService.enabled) {
                                BluetoothService.togglePower();
                            }
                            BluetoothService.scan();
                        }
                    }
                }
            }
        }

        // Expandable Drawer for Networks & Devices
        Rectangle {
            id: drawerBox
            Layout.fillWidth: true
            Layout.preferredHeight: root.drawerExpanded ? 190 : 0
            clip: true
            radius: Math.max(4, Config.radius - 4)
            color: Color.surface
            border.width: 1
            border.color: Color.overlay
            visible: Layout.preferredHeight > 0

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.isWifiView ? "AVAILABLE NETWORKS" : "PAIRED & NEARBY DEVICES"
                        font.family: Config.textFont
                        font.pixelSize: 9
                        font.bold: true
                        color: Color.muted
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.isWifiView ? "\ue63e" : "\ue1a7"
                        font.family: Config.iconFont
                        font.pixelSize: 14
                        color: Color.muted
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    StackLayout {
                        anchors.fill: parent
                        currentIndex: root.isWifiView ? 0 : 1

                        // Wi-Fi List
                        ListView {
                            id: wifiList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            model: root.drawerExpanded && root.isWifiView ? NetworkService.accessPoints : null
                            delegate: CardRow {
                                required property var modelData
                                width: wifiList.width
                                clickable: true
                                rowHeight: 34
                                title: modelData.ssid ?? "Unknown Network"
                                subtitle: modelData.connected ? "Connected" : ""
                                leadingIcon: "\ue63e"
                                trailingIcon: (modelData.requiresPassword ?? false) ? "\ue897" : ""
                                textColor: modelData.connected ? Color.primary : Color.text
                                onClicked: {
                                    if (modelData.connected) {
                                        NetworkService.disconnectWifi();
                                    } else {
                                        NetworkService.connectWifi(modelData.ssid);
                                    }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: wifiList.count === 0
                                text: NetworkService.wifiEnabled ? "Scanning for networks..." : "Wi-Fi is off"
                                font.family: Config.textFont
                                font.pixelSize: 11
                                color: Color.muted
                            }
                        }

                        // Bluetooth List
                        ListView {
                            id: btList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            model: root.drawerExpanded && !root.isWifiView ? BluetoothService.devices : null
                            delegate: CardRow {
                                required property var modelData
                                width: btList.width
                                clickable: true
                                rowHeight: 34
                                title: modelData.name ?? "Unknown Device"
                                subtitle: {
                                    if (modelData.connected) {
                                        return (modelData.battery !== undefined && modelData.battery >= 0) ? "Connected • " + modelData.battery + "%" : "Connected";
                                    }
                                    return modelData.paired ? "Paired" : "";
                                }
                                leadingIcon: modelData.connected ? "\ue1a8" : "\ue1a7"
                                trailingIcon: modelData.connected ? "\ue5ca" : ""
                                textColor: modelData.connected ? Color.primary : Color.text
                                onClicked: {
                                    if (modelData.connected) {
                                        BluetoothService.disconnectDevice(modelData.address);
                                    } else {
                                        BluetoothService.connectDevice(modelData.address);
                                    }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: btList.count === 0
                                text: BluetoothService.enabled ? "No devices found" : "Bluetooth is off"
                                font.family: Config.textFont
                                font.pixelSize: 11
                                color: Color.muted
                            }
                        }
                    }
                }
            }
        }

        // Compact Horizontal Sliders
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Volume
            QuickSlider {
                Layout.fillWidth: true
                iconText: AudioService.isMuted || AudioService.volume === 0 ? "\ue04f" : (AudioService.volume > 0.5 ? "\ue050" : "\ue04d")
                value: AudioService.volume
                onMoved: val => AudioService.setVolume(val)
            }

            Rectangle {
                implicitWidth: 1
                implicitHeight: 22
                color: Color.overlay
                opacity: 0.8
                Layout.alignment: Qt.AlignVCenter
            }

            // Brightness
            QuickSlider {
                Layout.fillWidth: true
                iconText: BrightnessService.brightness > 0.5 ? "\ue518" : "\ue51a"
                value: BrightnessService.brightness
                onMoved: val => BrightnessService.setBrightness(val)
            }
        }
    }
}
