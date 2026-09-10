import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.configs

Rectangle {
    id: root

    implicitWidth: trayRow.implicitWidth + 20
    implicitHeight: 34

    visible: SystemTray.items.values.length > 0

    radius: 0
    topLeftRadius: Config.radius
    bottomLeftRadius: Config.radius
    topRightRadius: 4
    bottomRightRadius: 4

    color: Color.background

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items.values

            delegate: Item {
                id: trayItemDelegate
                required property SystemTrayItem modelData

                implicitWidth: 16
                implicitHeight: 16

                readonly property bool isSymbolic: {
                    const iconPath = modelData.icon ? modelData.icon.toString().toLowerCase() : "";
                    return iconPath.includes("-symbolic") || iconPath.includes("symbolic");
                }

                IconImage {
                    id: iconImg
                    anchors.fill: parent
                    source: modelData.icon

                    layer.enabled: trayItemDelegate.isSymbolic
                    layer.effect: MultiEffect {
                        brightness: 1.0
                        colorization: 1.0
                        colorizationColor: Color.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.hasMenu) {
                                modelData.displayMenu();
                            } else {
                                modelData.secondaryActivate();
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
