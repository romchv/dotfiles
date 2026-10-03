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

    PopupWindow {
        id: popup

        readonly property color text: Style.popups.text ?? Style.colors.foreground

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: Style.space.sm
        implicitWidth: Style.space.bluetoothWidth
        implicitHeight: content.implicitHeight + Style.space.popupPadding * 2
        color: "transparent"
        visible: root.open

        HyprlandFocusGrab {
            active: popup.visible
            windows: [popup]
            onCleared: Panels.close()
        }

        Surface {
            anchors.fill: parent
            section: Style.popups
            focus: true
            Keys.onEscapePressed: Panels.close()

            ColumnLayout {
                id: content

                anchors.fill: parent
                anchors.margins: Style.space.popupPadding
                spacing: Style.space.lg

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space.xl

                    StyledText {
                        text: root.text
                        size: Style.font.iconLarge
                        color: popup.text
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: "Bluetooth"
                            size: Style.font.title
                            font.bold: true
                            color: popup.text
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: !root.on ? "Off" : root.adapter?.discovering ? "Scanning" : root.connected.length > 0 ? `${root.connected.length} connected` : "On"
                            size: Style.font.caption
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1
                            color: popup.text
                            opacity: 0.6
                        }
                    }

                    Switch {
                        checked: root.on
                        onToggled: if (root.adapter) root.adapter.enabled = !root.on
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Style.alpha(popup.text, 0.15)
                }

                Flickable {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(lists.implicitHeight, Style.space.popupRowHeight * 12)
                    contentHeight: lists.implicitHeight
                    clip: true
                    visible: root.on
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: lists

                        width: parent.width
                        spacing: Style.space.panelGap

                        Section {
                            title: "Paired"
                            devices: root.sorted(root.devices.filter(d => d.paired))
                        }

                        Section {
                            title: "Available"
                            devices: root.sorted(root.devices.filter(d => !d.paired))
                            empty: root.adapter?.discovering ? "Looking for devices…" : "Nothing nearby"
                        }
                    }
                }
            }
        }
    }

    component Section: ColumnLayout {
        id: section

        required property string title
        required property var devices
        property string empty: ""

        visible: devices.length > 0 || empty !== ""
        Layout.fillWidth: true
        spacing: Style.space.xxs

        StyledText {
            text: section.title
            size: Style.font.caption
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
            color: popup.text
            opacity: 0.6
            bottomPadding: Style.space.xs
        }

        StyledText {
            visible: section.devices.length === 0
            text: section.empty
            size: Style.font.bodySmall
            color: popup.text
            opacity: 0.6
            leftPadding: Style.space.rowPaddingX
        }

        Repeater {
            model: section.devices

            DeviceRow {}
        }
    }

    component DeviceRow: Item {
        id: row

        required property var modelData
        readonly property var device: modelData
        readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting

        Layout.fillWidth: true
        implicitHeight: Style.space.launcherRowHeight

        Rectangle {
            anchors.fill: parent
            color: Style.controls.hoverCursorColor ?? "transparent"
            opacity: area.containsMouse ? (Style.controls.hoverCursorFillAlpha ?? 0.08) : 0
            border.width: Style.controls.hoverCursorBorderWidth ?? 0
            border.color: Style.alpha(Style.controls.hoverCursorBorder, Style.controls.hoverCursorBorderAlpha)

            Behavior on opacity {
                NumberAnimation { duration: Style.anim.fast }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.busy ? Qt.BusyCursor : Qt.PointingHandCursor
            onClicked: root.activate(row.device)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space.rowPaddingX
            anchors.rightMargin: Style.space.rowPaddingX
            spacing: Style.space.xl

            StyledText {
                Layout.preferredWidth: Style.font.icon * 1.4
                text: root.glyph(row.device.icon)
                size: Style.font.icon
                color: popup.text
                opacity: row.device.connected ? 1 : 0.6
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {
                Layout.fillWidth: true
                text: row.device.name
                color: popup.text
                font.bold: row.device.connected
            }

            StyledText {
                visible: text !== ""
                text: root.status(row.device)
                size: Style.font.caption
                color: popup.text
                opacity: 0.6
            }

            // Forget: only on hover, so a stray click can't unpair.
            StyledText {
                visible: row.device.paired && area.containsMouse || forget.containsMouse
                text: "󰆴"
                size: Style.font.icon
                color: forget.containsMouse ? (Style.colors.red ?? popup.text) : popup.text
                opacity: forget.containsMouse ? 1 : 0.6

                MouseArea {
                    id: forget
                    anchors.fill: parent
                    anchors.margins: -Style.space.sm
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.device.forget()
                }
            }
        }
    }

    component Switch: Item {
        id: sw

        property bool checked: false
        signal toggled

        implicitWidth: Style.space.controlHeight * 1.4
        implicitHeight: Style.space.controlHeight * 0.75

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Style.alpha(Style.controls.normalColor, sw.checked ? Style.controls.selectedFillAlpha : Style.controls.normalFillAlpha)
            border.width: Style.controls.normalBorderWidth ?? 1
            border.color: Style.alpha(Style.controls.normalBorder, Style.controls.normalBorderAlpha)

            Rectangle {
                width: parent.height - Style.space.xs * 2
                height: width
                y: Style.space.xs
                x: sw.checked ? parent.width - width - Style.space.xs : Style.space.xs
                radius: Style.radius
                color: sw.checked ? (Style.colors.accent ?? popup.text) : Style.alpha(popup.text, 0.4)

                Behavior on x {
                    NumberAnimation { duration: Style.anim.normal; easing.type: Style.anim.easing }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sw.toggled()
        }
    }
}
