import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.configs
import qs.services
import qs.components

Scope {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: greeterWindow
            required property var modelData
            screen: modelData

            color: Color.background
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "greetd-greeter"

            // Wallpaper Background
            Image {
                anchors.fill: parent
                source: "file://" + Config.configDir + "/wallpaper.jpg"
                fillMode: Image.PreserveAspectCrop
                visible: true
                cache: false
                asynchronous: true
                opacity: 0.4
            }

            // Top Bar: Session Chooser
            RowLayout {
                z: 1
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 24
                }
                spacing: 8

                Text {
                    text: "Session:"
                    font.family: Config.textFont
                    font.pixelSize: 13
                    color: Color.muted
                }

                Button {
                    variant: "secondary"
                    buttonHeight: 34
                    text: GreetdService.isLoadingSessions ? "Loading sessions..." : (GreetdService.selectedSession ? GreetdService.selectedSession.name : "No sessions found")
                    leadingIcon: "\uef55"
                    enabled: !GreetdService.isLoadingSessions && GreetdService.availableSessions.length > 0
                    onClicked: {
                        GreetdService.selectSession((GreetdService.selectedSessionIndex + 1) % GreetdService.availableSessions.length);
                    }
                }
            }

            // Center Panel: Clock & Credentials
            ColumnLayout {
                id: centerPanel
                z: 1
                anchors.centerIn: parent
                width: 320
                spacing: 20

                // Clock
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2

                    Text {
                        text: GreetdService.currentTime
                        font.family: Config.textFont
                        font.pixelSize: 56
                        font.bold: true
                        color: Color.text
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: GreetdService.currentDate
                        font.family: Config.textFont
                        font.pixelSize: 14
                        color: Color.muted
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item {
                    Layout.preferredHeight: 12
                }

                // Avatar Icon Frame
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 72
                    height: 72
                    radius: width / 2
                    color: Color.surface
                    border.color: Color.overlay
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\ue7fd"
                        font.family: Config.iconFont
                        font.pixelSize: 36
                        color: Color.primary
                    }
                }

                // Inputs
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Input {
                        id: userInput
                        Layout.fillWidth: true
                        inputHeight: 42
                        leadingIcon: "\ue7fd"
                        placeholderText: "Username"
                        text: GreetdService.defaultUsername
                        onAccepted: passInput.forceActiveFocus()
                    }

                    Input {
                        id: passInput
                        Layout.fillWidth: true
                        inputHeight: 42
                        leadingIcon: "\ue897"
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        enabled: !GreetdService.isAuthenticating
                        onAccepted: submit()

                        function submit() {
                            if (userInput.text.length > 0 && passInput.text.length > 0) {
                                GreetdService.login(userInput.text, passInput.text);
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        buttonHeight: 40
                        text: GreetdService.isAuthenticating ? "Logging in..." : "Login"
                        leadingIcon: "\ue898"
                        enabled: userInput.text.length > 0 && passInput.text.length > 0 && !GreetdService.isAuthenticating
                        onClicked: passInput.submit()
                    }

                    Text {
                        visible: GreetdService.statusMessage.length > 0
                        text: GreetdService.statusMessage
                        font.family: Config.textFont
                        font.pixelSize: 12
                        color: GreetdService.statusMessage.toLowerCase().includes("failed") || GreetdService.statusMessage.toLowerCase().includes("error") || GreetdService.statusMessage.toLowerCase().includes("failure") ? Color.error : Color.muted
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                    }
                }
            }

            // Bottom Actions: Power controls
            RowLayout {
                z: 1
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: 28
                }
                spacing: 12

                Button {
                    variant: "ghost"
                    leadingIcon: "\ue1b8" // Suspend
                    buttonHeight: 38
                    horizontalPadding: 12
                    onClicked: GreetdService.suspend()
                }

                Button {
                    variant: "ghost"
                    leadingIcon: "\ue5d5" // Reboot
                    buttonHeight: 38
                    horizontalPadding: 12
                    onClicked: GreetdService.reboot()
                }

                Button {
                    variant: "ghost"
                    leadingIcon: "\ue8ac" // Power off
                    buttonHeight: 38
                    horizontalPadding: 12
                    onClicked: GreetdService.powerOff()
                }
            }

            Component.onCompleted: passInput.forceActiveFocus()

            Connections {
                target: GreetdService
                function onLoginFailed(): void {
                    passInput.text = "";
                    passInput.forceActiveFocus();
                }
            }
        }
    }
}
