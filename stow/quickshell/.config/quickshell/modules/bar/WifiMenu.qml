import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking as Nm
import qs.config
import qs.components
import qs.services

// Wi-Fi in the bar: the glyph shows the connection, a click (or
// `qs ipc call wifi toggle`, on the focused monitor) opens a dropdown with
// a power switch, known networks and nearby ones. It scans while open.
// Click a network to connect or disconnect; a new secured one asks for its
// password in place (Enter connects, Esc cancels). The trash glyph forgets a
// known one. Enterprise (802.1X) networks and right-clicks go to nmtui.
BarButton {
    id: root

    required property ShellScreen screen
    readonly property var wifi: Network.wifi
    readonly property var networks: wifi?.networks.values.filter(n => n.name !== "") ?? []
    readonly property bool open: Panels.current === "wifi" && Hyprland.focusedMonitor?.name === screen.name

    // The network whose password field is showing, and the last failure.
    property var asking: null
    property var failed: null
    property string failure: ""

    text: Network.icon
    tooltip: open ? "" : Network.tooltip
    onClicked: mouse => mouse.button === Qt.RightButton || !wifi ? Launch.tui("nmtui") : Panels.toggle("wifi")

    onAskingChanged: if (!asking) panel.refocus()
    onOpenChanged: if (!open) {
        asking = null;
        failed = null;
    }

    // Scan only while someone is looking.
    readonly property bool scan: open && Nm.Networking.wifiEnabled
    onScanChanged: if (wifi) wifi.scannerEnabled = scan

    function sorted(list) {
        return list.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
    }

    readonly property var enterprise: [Nm.WifiSecurityType.Wpa2Eap, Nm.WifiSecurityType.WpaEap, Nm.WifiSecurityType.Leap, Nm.WifiSecurityType.DynamicWep, Nm.WifiSecurityType.Wpa3SuiteB192]

    function status(n) {
        if (n.state === Nm.ConnectionState.Connecting)
            return "Connecting…";
        if (n.state === Nm.ConnectionState.Disconnecting)
            return "Disconnecting…";
        if (n.connected)
            return "Connected";
        if (n === failed)
            return failure;
        return n.security === Nm.WifiSecurityType.Open || n.security === Nm.WifiSecurityType.Owe ? "" : "󰌾";
    }

    function activate(n) {
        failed = null;
        if (n.connected)
            n.disconnect();
        else if (n.known || n.security === Nm.WifiSecurityType.Open || n.security === Nm.WifiSecurityType.Owe)
            n.connect();
        else if (enterprise.includes(n.security)) {
            Panels.close();
            Launch.tui("nmtui");
        } else
            asking = asking === n ? null : n;
    }

    // NetworkManager says why a connection failed; a missing or wrong
    // password brings the field back.
    Instantiator {
        model: root.networks

        Connections {
            required property var modelData

            target: modelData
            function onConnectionFailed(reason) {
                root.failed = target;
                root.failure = reason === Nm.ConnectionFailReason.NoSecrets ? "Wrong password" : "Failed";
                if (reason === Nm.ConnectionFailReason.NoSecrets && !target.known)
                    root.asking = target;
            }
        }
    }

    DropdownPanel {
        id: panel

        target: root
        screen: root.screen
        open: root.open
        glyph: Nm.Networking.wifiEnabled ? Network.signalGlyph(Network.network ? Network.strength : 1) : "󰤮"
        title: "Wi-Fi"
        status: !Nm.Networking.wifiEnabled ? "Off" : Network.network ? Network.network.name : root.wifi?.scannerEnabled ? "Scanning" : "Not connected"
        checked: Nm.Networking.wifiEnabled
        bodyVisible: Nm.Networking.wifiEnabled
        onToggled: Nm.Networking.wifiEnabled = !Nm.Networking.wifiEnabled
        onDismissed: Panels.close()

        DropdownSection {
            id: known

            readonly property var list: root.sorted(root.networks.filter(n => n.known))

            title: "Known"
            count: list.length

            Repeater {
                model: known.list

                NetworkRow {}
            }
        }

        DropdownSection {
            id: available

            readonly property var list: root.sorted(root.networks.filter(n => !n.known))

            title: "Available"
            count: list.length
            empty: root.wifi?.scannerEnabled ? "Looking for networks…" : "Nothing nearby"

            Repeater {
                model: available.list

                NetworkRow {}
            }
        }
    }

    component NetworkRow: ColumnLayout {
        id: row

        required property var modelData
        readonly property var network: modelData

        Layout.fillWidth: true
        spacing: Style.space.xxs

        DropdownRow {
            glyph: Network.signalGlyph(row.network.signalStrength)
            label: row.network.name
            status: root.status(row.network)
            active: row.network.connected
            busy: row.network.stateChanging
            forgettable: row.network.known
            onClicked: root.activate(row.network)
            onForget: row.network.forget()
        }

        TextField {
            id: psk

            visible: root.asking === row.network
            Layout.fillWidth: true
            Layout.leftMargin: Style.space.rowPaddingX
            Layout.rightMargin: Style.space.rowPaddingX
            Layout.bottomMargin: Style.space.sm
            icon: "󰌾"
            placeholder: "Password"
            password: true
            textColor: Style.popups.text ?? Style.colors.foreground
            onVisibleChanged: {
                text = "";
                if (visible)
                    input.forceActiveFocus();
            }
            onAccepted: if (text !== "") {
                root.failed = null;
                row.network.connectWithPsk(text);
                root.asking = null;
            }
            // Esc closes the field, not the whole menu.
            onKeyPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.asking = null;
                    event.accepted = true;
                }
            }
        }
    }
}
