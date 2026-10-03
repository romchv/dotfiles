import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// One bar per screen, along the top edge. `qs ipc call bar toggle` hides/shows all of them.
Scope {
    id: root

    property bool shown: true

    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.shown = !root.shown;
        }
    }

    IpcHandler {
        target: "claude"

        function toggle(): void {
            Panels.toggle("claude");
        }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            Panels.toggle("bluetooth");
        }
    }

    IpcHandler {
        target: "audio"

        function toggle(): void {
            Panels.toggle("audio");
        }
    }

    IpcHandler {
        target: "wifi"

        function toggle(): void {
            Panels.toggle("wifi");
        }
    }

    IpcHandler {
        target: "battery"

        function toggle(): void {
            Panels.toggle("battery");
        }
    }

    // Lives here because the bar shows the night light state.
    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            NightLight.toggle();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property ShellScreen modelData

            screen: modelData
            visible: root.shown
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Style.barHeight
            color: Style.alpha(Style.bar.background, Style.bar.backgroundAlpha)

            Row {
                anchors.left: parent.left
                height: parent.height

                BarButton {
                    text: "󰀻" // apps grid
                    size: Style.font.icon
                    onClicked: Panels.toggle("launcher", bar.modelData.name)
                }

                Workspaces {
                    screen: bar.modelData
                    height: parent.height
                }
            }

            // Status toggles sit beside the clock without pushing it off center.
            Row {
                anchors.right: center.left
                height: parent.height

                BarButton {
                    visible: Notifications.dnd
                    text: "󰂛"
                    tooltip: "Do Not Disturb (click to turn off)"
                    onClicked: Notifications.dnd = false
                }

                NightLightMenu {
                    screen: bar.modelData
                }
            }

            Row {
                id: center

                anchors.centerIn: parent
                height: parent.height

                Clock {}

                BarButton {
                    text: Keyboard.label
                    size: Style.font.bodySmall
                    label.opacity: 0.7
                    onClicked: Keyboard.next()
                }
            }

            Row {
                anchors.right: parent.right
                height: parent.height

                Tray {
                    height: parent.height
                }

                ClaudeLimits {
                    screen: bar.modelData
                }

                BluetoothMenu {
                    screen: bar.modelData
                }

                WifiMenu {
                    screen: bar.modelData
                }

                AudioMenu {
                    screen: bar.modelData
                }

                BarButton {
                    text: "󰍛"
                    onClicked: Launch.tui("btop")
                }

                BatteryMenu {
                    screen: bar.modelData
                }

                Item {
                    width: Style.space.sm
                    height: 1
                }
            }
        }
    }
}
