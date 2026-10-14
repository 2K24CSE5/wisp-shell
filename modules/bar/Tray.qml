import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.configs
import qs.services

Rectangle {
    id: root

    readonly property bool expanded: TrayService.expanded

    implicitWidth: expanded ? Math.max(28, contentRow.implicitWidth + 12) : 28
    implicitHeight: 28
    radius: Math.max(2, Config.radius - 2)
    color: (!root.expanded && toggleMouse.containsMouse) ? Color.overlay : Color.surface
    visible: TrayService.hasItems

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: menuLoader
        active: false
        sourceComponent: TrayMenu {}

        property var pendingTarget: null
        property var pendingItem: null
        property var pendingOpener: null

        onLoaded: {
            if (pendingTarget && pendingItem && pendingOpener && item) {
                item.openFor(pendingTarget, pendingItem, pendingOpener);
                pendingTarget = null;
                pendingItem = null;
                pendingOpener = null;
            }
        }

        Connections {
            target: TrayService
            function onMenuRequested(targetItem, item, menuOpener) {
                if (!menuLoader.active) {
                    menuLoader.pendingTarget = targetItem;
                    menuLoader.pendingItem = item;
                    menuLoader.pendingOpener = menuOpener;
                    menuLoader.active = true;
                } else if (menuLoader.item) {
                    menuLoader.item.openFor(targetItem, item, menuOpener);
                }
            }
            function onMenuCloseRequested() {
                if (menuLoader.item) {
                    menuLoader.item.visible = false;
                }
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 3

        Item {
            id: trayDrawer
            implicitHeight: 22
            implicitWidth: 0
            clip: true

            RowLayout {
                id: trayItemsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                opacity: 0.0

                Repeater {
                    model: TrayService.items

                    delegate: Rectangle {
                        id: trayItemDelegate
                        required property SystemTrayItem modelData

                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 4
                        color: itemMouse.containsMouse ? Color.overlay : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        readonly property bool isSymbolic: TrayService.isSymbolic(modelData.icon)

                        IconImage {
                            id: iconImg
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: trayItemDelegate.modelData.icon

                            layer.enabled: trayItemDelegate.isSymbolic
                            layer.effect: MultiEffect {
                                brightness: 1.0
                                colorization: 1.0
                                colorizationColor: Color.text
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    TrayService.activateItem(trayItemDelegate.modelData);
                                } else if (mouse.button === Qt.RightButton) {
                                    TrayService.openMenuForItem(trayItemDelegate, trayItemDelegate.modelData);
                                } else if (mouse.button === Qt.MiddleButton) {
                                    TrayService.secondaryActivateItem(trayItemDelegate.modelData);
                                }
                            }
                        }
                    }
                }
            }

            states: [
                State {
                    name: "expanded"
                    when: root.expanded
                    PropertyChanges {
                        target: trayDrawer
                        implicitWidth: trayItemsRow.implicitWidth
                    }
                    PropertyChanges {
                        target: trayItemsRow
                        opacity: 1.0
                    }
                },
                State {
                    name: "collapsed"
                    when: !root.expanded
                    PropertyChanges {
                        target: trayDrawer
                        implicitWidth: 0
                    }
                    PropertyChanges {
                        target: trayItemsRow
                        opacity: 0.0
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "collapsed"
                    to: "expanded"
                    SequentialAnimation {
                        NumberAnimation {
                            target: trayDrawer
                            property: "implicitWidth"
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: trayItemsRow
                            property: "opacity"
                            duration: 80
                            easing.type: Easing.Linear
                        }
                    }
                },
                Transition {
                    from: "expanded"
                    to: "collapsed"
                    SequentialAnimation {
                        NumberAnimation {
                            target: trayItemsRow
                            property: "opacity"
                            duration: 40
                            easing.type: Easing.Linear
                        }
                        NumberAnimation {
                            target: trayDrawer
                            property: "implicitWidth"
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            ]
        }

        Rectangle {
            visible: root.expanded
            implicitWidth: 1
            implicitHeight: 10
            color: Color.overlay
            opacity: root.expanded ? 0.7 : 0.0
            Layout.alignment: Qt.AlignVCenter

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }
        }

        Item {
            id: toggleBtn
            implicitWidth: 18
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: triggerIcon
                anchors.centerIn: parent
                text: root.expanded ? "\ue5cd" : "\ue5cb" // close vs chevron_left
                font.family: Config.iconFont
                font.pixelSize: root.expanded ? 14 : 16
                color: root.expanded ? Color.primary : (toggleMouse.containsMouse ? Color.text : Color.muted)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }
            }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: TrayService.toggleExpanded()
            }
        }
    }
}
