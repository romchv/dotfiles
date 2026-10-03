import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
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
                    onClicked: Panels.toggle("launcher")
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

                BarButton {
                    visible: NightLight.enabled
                    text: "\u{F0594}"
                    tooltip: "Night light (click to turn off)"
                    onClicked: NightLight.enabled = false
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

                BarButton {
                    readonly property var adapter: Bluetooth.defaultAdapter
                    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
                    // Devices first: Quickshell can miss the adapter's power-on at boot
                    // and stay at Enabling, though a connected device proves it's on.
                    readonly property bool on: connected.length > 0 || adapter?.enabled || adapter?.state === BluetoothAdapterState.Enabling

                    visible: !!adapter // no bluetooth hardware
                    text: connected.length > 0 ? "󰂱" : on ? "󰂯" : "󰂲"
                    tooltip: connected.length > 0 ? connected.map(d => d.name).join(", ") : on ? "Bluetooth on" : "Bluetooth off"
                    onClicked: Launch.tui("bluetui")
                }

                BarButton {
                    text: Network.icon
                    tooltip: Network.tooltip
                    onClicked: Launch.tui("nmtui")
                }

                BarButton {
                    text: Audio.icon
                    size: Style.font.iconMedium
                    tooltip: Audio.muted ? "Muted" : `Volume ${Math.round(Audio.volume * 100)}%`
                    onClicked: mouse => mouse.button === Qt.RightButton ? Audio.toggleMute() : Launch.tui("wiremix")
                    onScrolled: wheel => Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
                }

                BarButton {
                    text: "󰍛"
                    onClicked: Launch.tui("btop")
                }

                BarButton {
                    visible: Battery.available // laptops only
                    text: Battery.icon
                    size: Style.font.iconMedium - 1
                    tooltip: `${Battery.percent}% · ${Battery.status}`
                    pinned: visible && Panels.current === "battery" && Hyprland.focusedMonitor?.name === bar.modelData.name
                    onDismissed: Panels.close()
                    label.color: Battery.low ? Style.bar.active : (Style.bar.text ?? Style.colors.foreground)
                }

                Item {
                    width: Style.space.sm
                    height: 1
                }
            }
        }
    }
}
