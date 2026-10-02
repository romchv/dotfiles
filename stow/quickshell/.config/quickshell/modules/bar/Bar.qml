import QtQuick
import Quickshell
import Quickshell.Bluetooth
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

            Row {
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

                BarButton {
                    visible: Notifications.dnd
                    text: "󰂛"
                    tooltip: "Do Not Disturb (click to turn off)"
                    onClicked: Notifications.dnd = false
                }

                BarButton {
                    readonly property var adapter: Bluetooth.defaultAdapter
                    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

                    visible: !!adapter // no bluetooth hardware
                    text: !adapter?.enabled ? "󰂲" : connected ? "󰂱" : "󰂯"
                    tooltip: !adapter?.enabled ? "Bluetooth off" : connected ? Bluetooth.devices.values.filter(d => d.connected).map(d => d.name).join(", ") : "Bluetooth on"
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
                    visible: Battery.available // laptops only
                    text: Battery.icon
                    suffix: `${Battery.percent}%`
                    size: Style.font.iconMedium - 1
                    tooltip: Battery.status
                    label.color: Battery.low ? Style.bar.active : (Style.bar.text ?? Style.colors.foreground)
                }

                BarButton {
                    text: "󰍛"
                    onClicked: Launch.tui("btop")
                }

                Item {
                    width: Style.space.sm
                    height: 1
                }
            }
        }
    }
}
