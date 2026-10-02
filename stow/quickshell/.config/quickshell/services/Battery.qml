pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Laptop battery through UPower's display device. `available` is false on
// machines without one, and the bar hides the battery there.
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: (device?.isLaptopBattery ?? false) && device.isPresent

    // Quickshell reports 0..1; guard against a 0..100 backend.
    readonly property real level: {
        const p = device?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property int percent: Math.round(level * 100)
    readonly property int state: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property bool low: !pluggedIn && percent <= 20

    // Plug while on AC (charging or not), else the battery at its charge level.
    readonly property string icon: {
        if (pluggedIn)
            return "󰚥";
        const step = Math.max(0, Math.min(9, Math.ceil(level * 10) - 1));
        return ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][step];
    }

    readonly property string status: {
        if (charging)
            return device.timeToFull > 0 ? `Charging, ${formatTime(device.timeToFull)} to full` : "Charging";
        if (state === UPowerDeviceState.FullyCharged)
            return "Fully charged";
        if (pluggedIn)
            return "Plugged in, not charging";
        return device?.timeToEmpty > 0 ? `${formatTime(device.timeToEmpty)} left` : "On battery";
    }

    function formatTime(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }
}
