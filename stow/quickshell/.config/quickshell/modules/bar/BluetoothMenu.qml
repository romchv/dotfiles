import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Bluetooth in the bar: the glyph shows the state, a click (or
// `qs ipc call bluetooth toggle`, on the focused monitor) opens a dropdown
// with a power switch, paired devices and nearby ones. It scans while open.
// Click a paired device to connect or disconnect it, the trash glyph to
// forget it, a nearby one to pair, trust and connect it. Right-click the
// glyph for bluetui, which can answer PIN prompts this menu can't.
BarButton {
    id: root

    required property ShellScreen screen
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values.filter(d => d.deviceName !== "" || d.paired)
    readonly property var connected: devices.filter(d => d.connected)
    // Devices first: Quickshell can miss the adapter's power-on at boot
    // and stay at Enabling, though a connected device proves it's on.
    readonly property bool on: connected.length > 0 || adapter?.enabled || adapter?.state === BluetoothAdapterState.Enabling
    readonly property bool open: Panels.current === "bluetooth" && Hyprland.focusedMonitor?.name === screen.name

    visible: !!adapter // no bluetooth hardware
    text: connected.length > 0 ? "󰂱" : on ? "󰂯" : "󰂲"
    tooltip: open ? "" : connected.length > 0 ? connected.map(d => d.name).join(", ") : on ? "Bluetooth on" : "Bluetooth off"
    onClicked: mouse => mouse.button === Qt.RightButton ? Launch.tui("bluetui") : Panels.toggle("bluetooth")

    // Scan only while someone is looking: discovery drains batteries and
    // slows audio on some adapters.
    readonly property bool scan: open && !!adapter?.enabled
    onScanChanged: if (adapter) adapter.discovering = scan

    function sorted(list) {
        return list.slice().sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));
    }

    function status(d) {
        if (d.pairing)
            return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (d.connected)
            return d.batteryAvailable ? `${Math.round(d.battery * 100)}%` : "Connected";
        return "";
    }

    function glyph(icon) {
        if (/audio-head|headset|headphone/.test(icon))
            return "󰋋";
        if (/audio|speaker/.test(icon))
            return "󰓃";
        if (/keyboard/.test(icon))
            return "󰌌";
        if (/mouse/.test(icon))
            return "󰍽";
        if (/gaming|joystick/.test(icon))
            return "󰊴";
        if (/phone/.test(icon))
            return "󰏲";
        if (/computer/.test(icon))
            return "󰟀";
        return "󰂯";
    }

    function activate(d) {
        if (d.paired)
            d.connected ? d.disconnect() : d.connect();
        else if (!d.pairing)
            d.pair();
    }

    // A device paired from this menu should come back on its own and be in
    // use right away, as bluetui does.
    Instantiator {
        model: root.devices

        Connections {
            required property var modelData

            target: modelData
            function onPairedChanged() {
                if (target.paired) {
                    target.trusted = true;
                    target.connect();
                }
            }
        }
    }

    DropdownPanel {
        target: root
        screen: root.screen
        open: root.open
        glyph: root.text
        title: "Bluetooth"
        status: !root.on ? "Off" : root.adapter?.discovering ? "Scanning" : root.connected.length > 0 ? `${root.connected.length} connected` : "On"
        checked: root.on
        bodyVisible: root.on
        onToggled: if (root.adapter) root.adapter.enabled = !root.on
        onDismissed: Panels.close()

        DropdownSection {
            id: paired

            readonly property var list: root.sorted(root.devices.filter(d => d.paired))

            title: "Paired"
            count: list.length

            Repeater {
                model: paired.list

                DeviceRow {}
            }
        }

        DropdownSection {
            id: available

            readonly property var list: root.sorted(root.devices.filter(d => !d.paired))

            title: "Available"
            count: list.length
            empty: root.adapter?.discovering ? "Looking for devices…" : "Nothing nearby"

            Repeater {
                model: available.list

                DeviceRow {}
            }
        }
    }

    component DeviceRow: DropdownRow {
        required property var modelData

        glyph: root.glyph(modelData.icon)
        label: modelData.name
        status: root.status(modelData)
        active: modelData.connected
        busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
        forgettable: modelData.paired
        onClicked: root.activate(modelData)
        onForget: modelData.forget()
    }
}
