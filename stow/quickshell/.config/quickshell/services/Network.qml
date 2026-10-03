pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Connection summary for the bar: wired beats wifi. Works with either
// device missing (desktop without wifi, laptop without ethernet port).
// While `monitoring` (the bar's network menu is open) it also measures
// the live connection: speeds, totals, address, gateway, ping and loss.
Singleton {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool ethernet: wired?.connected ?? false
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: network?.signalStrength ?? 0

    readonly property string tooltip: {
        if (ethernet)
            return "Ethernet";
        if (network)
            return `${network.name} (${Math.round(strength * 100)}%)`;
        return wifi && Networking.wifiEnabled ? "Not connected" : "Offline";
    }

    readonly property string icon: {
        if (ethernet)
            return "󰀂";
        if (!wifi) // desktop without wifi, cable unplugged
            return "󰈂";
        if (!Networking.wifiEnabled)
            return "󰤮";
        if (!network)
            return "󰤯";
        return signalGlyph(strength);
    }

    // Wifi bars for a signal strength from 0 to 1.
    function signalGlyph(s) {
        if (s < 0.25)
            return "󰤟";
        if (s < 0.5)
            return "󰤢";
        if (s < 0.75)
            return "󰤥";
        return "󰤨";
    }

    // ---- live connection details, only while monitoring ----
    property bool monitoring: false

    // From the route to the internet: the interface really in use (wifi or
    // cable), its address and the gateway.
    property string iface: ""
    property string address: ""
    property string gateway: ""

    // Bytes per second, and bytes since the interface came up.
    property real rxRate: -1
    property real txRate: -1
    property real rxTotal: -1
    property real txTotal: -1

    // Round trip to pingHost in ms, and the share of probes lost (0..1).
    readonly property string pingHost: "1.1.1.1"
    property real ping: -1
    property real loss: -1

    property var _last: null // { rx, tx, at } from the previous sample

    onMonitoringChanged: if (!monitoring) {
        _last = null;
        rxRate = txRate = -1;
    }
    onIfaceChanged: _last = null

    // 1 KB = 1000 bytes, as speed tests count.
    function formatBytes(n, perSecond) {
        if (n < 0)
            return "";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (n >= 1000 && i < units.length - 1) {
            n /= 1000;
            i++;
        }
        const digits = i === 0 ? 0 : perSecond ? 1 : 2;
        return `${n.toFixed(digits)} ${units[i]}${perSecond ? "/s" : ""}`;
    }

    function _sample() {
        const rx = parseFloat(rxFile.text()), tx = parseFloat(txFile.text()), at = Date.now();
        if (isNaN(rx) || isNaN(tx))
            return;
        if (_last && at > _last.at) {
            rxRate = Math.max(0, (rx - _last.rx) * 1000 / (at - _last.at));
            txRate = Math.max(0, (tx - _last.tx) * 1000 / (at - _last.at));
        }
        rxTotal = rx;
        txTotal = tx;
        _last = { rx, tx, at };
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.monitoring && root.iface !== ""
        triggeredOnStart: true
        // Both counters, then one sample from the pair.
        onTriggered: {
            rxFile.reload();
            txFile.reload();
            rxFile.waitForJob();
            txFile.waitForJob();
            root._sample();
        }
    }

    FileView {
        id: rxFile
        path: root.iface ? `/sys/class/net/${root.iface}/statistics/rx_bytes` : ""
        printErrors: false
    }

    FileView {
        id: txFile
        path: root.iface ? `/sys/class/net/${root.iface}/statistics/tx_bytes` : ""
        printErrors: false
    }

    // Route, then ping, refresh less often: a ping burst takes about a second.
    Timer {
        interval: 5000
        repeat: true
        running: root.monitoring
        triggeredOnStart: true
        onTriggered: route.running = true
    }

    Process {
        id: route
        command: ["ip", "-j", "-4", "route", "get", root.pingHost]
        stdout: StdioCollector {
            onStreamFinished: {
                let r = null;
                try {
                    r = JSON.parse(text)[0];
                } catch (e) {}
                root.iface = r?.dev ?? "";
                root.address = r?.prefsrc ?? "";
                root.gateway = r?.gateway ?? "";
                // Ping once the route says there's a way out.
                if (root.iface !== "")
                    pinger.running = true;
            }
        }
        // No route at all (offline) prints nothing on stdout.
        onExited: code => {
            if (code !== 0)
                root.iface = root.address = root.gateway = "";
        }
    }

    Process {
        id: pinger
        command: ["ping", "-n", "-q", "-c", "5", "-i", "0.2", "-W", "1", root.pingHost]
        stdout: StdioCollector {
            onStreamFinished: {
                const loss = text.match(/([\d.]+)% packet loss/);
                const rtt = text.match(/= [\d.]+\/([\d.]+)\//);
                root.loss = loss ? parseFloat(loss[1]) / 100 : -1;
                root.ping = rtt ? parseFloat(rtt[1]) : -1;
            }
        }
    }
}
