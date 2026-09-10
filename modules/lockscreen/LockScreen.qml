import QtQuick
import QtQuick.Layouts
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
            id: lockWindow
            required property var modelData
            screen: modelData

            visible: LockScreenService.isLocked || LockScreenService.isDimmed
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: LockScreenService.isLocked ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "wisp-lockscreen"

            Region {
                id: emptyRegion
            }

            // Route clicks through to desktop until dimming starts or locked
            mask: (LockScreenService.isLocked || LockScreenService.isDimmed) ? null : emptyRegion

            // Lock screen contents (wallpaper, clock, password input)
            Item {
                id: lockContent
                anchors.fill: parent
                visible: LockScreenService.isLocked
                opacity: LockScreenService.isLocked ? 1.0 : 0.0

                Image {
                    anchors.fill: parent
                    source: "file://" + Config.configDir + "/wallpaper.jpg"
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    opacity: 1
                }

                ColumnLayout {
                    z: 1
                    anchors.centerIn: parent
                    width: 320
                    spacing: 20

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        Text {
                            text: LockScreenService.currentTime
                            font.family: Config.textFont
                            font.pixelSize: 56
                            font.bold: true
                            color: Color.text
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: LockScreenService.currentDate
                            font.family: Config.textFont
                            font.pixelSize: 14
                            color: Color.muted
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Item {
                        Layout.preferredHeight: 12
                    }

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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Input {
                            id: passwordInput
                            Layout.fillWidth: true
                            inputHeight: 42
                            leadingIcon: "\ue897"
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            enabled: !LockScreenService.isAuthenticating
                            onAccepted: submit()

                            function submit(): void {
                                if (text.length > 0)
                                    LockScreenService.unlock(text);
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            buttonHeight: 40
                            text: LockScreenService.isAuthenticating ? "Unlocking..." : "Unlock"
                            leadingIcon: "\ue898"
                            enabled: passwordInput.text.length > 0 && !LockScreenService.isAuthenticating
                            onClicked: passwordInput.submit()
                        }

                        Text {
                            visible: LockScreenService.statusMessage.length > 0
                            text: LockScreenService.statusMessage
                            font.family: Config.textFont
                            font.pixelSize: 12
                            color: LockScreenService.statusMessage === "Incorrect password" ? Color.error : Color.muted
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 4
                        }
                    }
                }

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
                        leadingIcon: "\ue1b8"
                        buttonHeight: 38
                        horizontalPadding: 12
                        onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                    }

                    Button {
                        variant: "ghost"
                        leadingIcon: "\ue8ac"
                        buttonHeight: 38
                        horizontalPadding: 12
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }
            }

            // Smooth blackout curtain
            Rectangle {
                id: fadeCurtain
                anchors.fill: parent
                color: "#000000"
                z: 999
                opacity: 0.0

                NumberAnimation {
                    id: fadeAnim
                    target: fadeCurtain
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: LockScreenService.fadeTime
                    easing.type: Easing.InOutQuad
                }
            }

            // Active input canceller during fade
            MouseArea {
                id: cancellerArea
                anchors.fill: parent
                z: 1000
                enabled: LockScreenService.isDimmed && !LockScreenService.isLocked
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons

                property bool armed: false
                property real initialX: -1
                property real initialY: -1

                // Grace window to ignore synthetic cursor events during surface mapping
                Timer {
                    id: armTimer
                    interval: 200
                    repeat: false
                    onTriggered: {
                        cancellerArea.armed = true;
                    }
                }

                onPressed: {
                    fadeAnim.stop();
                    fadeCurtain.opacity = 0.0;
                    LockScreenService.wakeScreen();
                }

                onPositionChanged: mouse => {
                    if (!cancellerArea.armed)
                        return;

                    if (initialX < 0) {
                        initialX = mouse.x;
                        initialY = mouse.y;
                        return;
                    }

                    // Intentional movement (> 15px) cancels the fade
                    if (Math.hypot(mouse.x - initialX, mouse.y - initialY) > 15) {
                        fadeAnim.stop();
                        fadeCurtain.opacity = 0.0;
                        LockScreenService.wakeScreen();
                    }
                }
            }

            Connections {
                target: LockScreenService
                function onIsDimmedChanged(): void {
                    if (LockScreenService.isDimmed) {
                        fadeCurtain.opacity = 0.0;
                        fadeAnim.restart();
                        cancellerArea.armed = false;
                        cancellerArea.initialX = -1;
                        cancellerArea.initialY = -1;
                        armTimer.restart();
                    } else {
                        fadeAnim.stop();
                        fadeCurtain.opacity = 0.0;
                        armTimer.stop();
                        cancellerArea.armed = false;
                    }
                }

                function onIsLockedChanged(): void {
                    if (LockScreenService.isLocked) {
                        passwordInput.text = "";
                        passwordInput.forceActiveFocus();
                    }
                }
            }

            onVisibleChanged: {
                if (visible && LockScreenService.isLocked) {
                    passwordInput.text = "";
                    passwordInput.forceActiveFocus();
                }
            }
        }
    }
}
