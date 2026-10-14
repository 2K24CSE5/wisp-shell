import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.configs
import qs.services

PopupWindow {
    id: root

    property var opener: null
    property var trayItem: null
    property Item anchorItem: null

    property real anchorX: 0
    property real anchorY: 0

    visible: false
    color: "transparent"
    implicitWidth: menuCard.implicitWidth
    implicitHeight: menuCard.implicitHeight

    anchor {
        window: root.anchorItem ? root.anchorItem.QsWindow.window : null
        rect {
            x: root.anchorX
            y: root.anchorY
            width: 0
            height: 0
        }
        edges: Edges.Bottom
        gravity: Edges.Bottom
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: TrayService.closeMenu()
    }

    Rectangle {
        id: menuCard
        implicitWidth: Math.max(180, itemsCol.implicitWidth + 20)
        implicitHeight: itemsCol.implicitHeight + 16
        radius: Config.radius
        color: Color.background
        border.width: 1
        border.color: Color.overlay
        focus: true

        Component.onCompleted: menuCard.forceActiveFocus()

        onActiveFocusChanged: {
            if (!activeFocus && root.visible) {
                TrayService.closeMenu();
            }
        }

        Keys.onEscapePressed: event => {
            TrayService.closeMenu();
            event.accepted = true;
        }

        Column {
            id: itemsCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            width: 175
            spacing: 2

            // Header with App Title
            Item {
                width: parent.width
                implicitHeight: 20

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    text: (root.trayItem && (root.trayItem.title || root.trayItem.id)) || "Tray Item"
                    font.family: Config.textFont
                    font.pixelSize: 11
                    font.bold: true
                    color: Color.muted
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Color.overlay
            }

            Item {
                width: parent.width
                height: 2
            }

            // Fallback when DBus Menu is not provided
            Column {
                id: fallbackCol
                width: parent.width
                spacing: 2
                visible: !root.opener || !root.opener.children || root.opener.children.length === 0

                Rectangle {
                    width: parent.width
                    implicitHeight: 28
                    radius: Math.max(2, (Config.radius ?? 8) - 2)
                    color: fbOpenMouse.containsMouse ? Color.overlay : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\ue5d8"
                            font.family: Config.iconFont
                            font.pixelSize: 14
                            color: Color.text
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Open / Restore"
                            font.family: Config.textFont
                            font.pixelSize: 11
                            color: Color.text
                        }
                    }

                    MouseArea {
                        id: fbOpenMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const item = root.trayItem;
                            TrayService.closeMenu();
                            if (item)
                                item.activate();
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: 28
                    radius: Math.max(2, (Config.radius ?? 8) - 2)
                    color: fbSecMouse.containsMouse ? Color.overlay : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\ue5d2"
                            font.family: Config.iconFont
                            font.pixelSize: 14
                            color: Color.text
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Secondary Action"
                            font.family: Config.textFont
                            font.pixelSize: 11
                            color: Color.text
                        }
                    }

                    MouseArea {
                        id: fbSecMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const item = root.trayItem;
                            TrayService.closeMenu();
                            if (item)
                                item.secondaryActivate();
                        }
                    }
                }
            }

            // DBus Menu Entries
            Repeater {
                model: (root.opener && root.opener.children) ? root.opener.children : null

                delegate: Rectangle {
                    id: rowItem
                    required property QsMenuEntry modelData

                    readonly property bool isSeparator: Boolean(modelData.isSeparator)
                    readonly property bool isActionable: !isSeparator && Boolean(modelData.enabled)
                    readonly property string cleanLabel: (modelData.text || "").replace(/&/g, "").trim()
                    readonly property bool isExitAction: /quit|exit|close/i.test(cleanLabel)

                    width: itemsCol.width
                    implicitHeight: isSeparator ? 6 : (cleanLabel.length > 0 ? 28 : 0)
                    visible: isSeparator || cleanLabel.length > 0
                    radius: Math.max(2, (Config.radius ?? 8) - 2)
                    color: (rowItem.isActionable && mouseArea.containsMouse) ? Color.overlay : "transparent"

                    Rectangle {
                        visible: rowItem.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 4
                        height: 1
                        color: Color.overlay
                    }

                    Row {
                        visible: !rowItem.isSeparator
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        opacity: rowItem.isActionable ? 1.0 : 0.4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Boolean(rowItem.modelData.checkState !== undefined && rowItem.modelData.checkState !== Qt.Unchecked) || rowItem.isExitAction
                            text: {
                                if (rowItem.modelData.checkState === Qt.Checked)
                                    return "\ue5ca";
                                if (rowItem.isExitAction)
                                    return "\ue5cd";
                                return "";
                            }
                            font.family: Config.iconFont
                            font.pixelSize: 13
                            color: rowItem.isExitAction ? (Color.error ?? "#ffb4ab") : Color.primary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - (parent.spacing + 16)
                            text: rowItem.cleanLabel
                            font.family: Config.textFont
                            font.pixelSize: 11
                            color: rowItem.isExitAction ? (Color.error ?? "#ffb4ab") : Color.text
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Boolean(rowItem.modelData.hasChildren)
                            text: "\ue5cc"
                            font.family: Config.iconFont
                            font.pixelSize: 13
                            color: Color.muted
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        enabled: rowItem.isActionable
                        hoverEnabled: rowItem.isActionable
                        cursorShape: rowItem.isActionable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            const entry = rowItem.modelData;
                            TrayService.closeMenu();
                            entry.triggered();
                        }
                    }
                }
            }
        }
    }

    function openFor(targetItem, trayModelItem, menuOpener) {
        if (root.visible && root.trayItem === trayModelItem) {
            TrayService.closeMenu();
            return;
        }

        root.anchorItem = targetItem;
        root.trayItem = trayModelItem;
        root.opener = menuOpener;

        if (targetItem && targetItem.QsWindow && targetItem.QsWindow.window) {
            const winContent = targetItem.QsWindow.window.contentItem;
            const pt = targetItem.mapToItem(winContent, 0, 0);
            root.anchorX = pt.x - (menuCard.implicitWidth / 2) + (targetItem.width / 2);
            root.anchorY = pt.y + targetItem.height + 6;
        }

        root.visible = true;
        menuCard.forceActiveFocus();
    }
}
