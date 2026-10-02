pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Connection summary for the bar: wired beats wifi. Works with either
// device missing (desktop without wifi, laptop without ethernet port).
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
        if (strength < 0.25)
            return "󰤟";
        if (strength < 0.5)
            return "󰤢";
        if (strength < 0.75)
            return "󰤥";
        return "󰤨";
    }
}
