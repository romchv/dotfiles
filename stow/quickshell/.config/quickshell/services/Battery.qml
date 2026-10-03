pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Laptop battery through UPower's display device. `available` is false on
// machines without one, and the bar hides the battery there. Cycle count and
// charge limits come from sysfs, power profiles from power-profiles-daemon;
// each is -1 / empty / false where the hardware or daemon doesn't offer it.
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

    // Capacity when full, in Wh, and health as 0..100 (-1: not reported).
    readonly property real capacity: device?.energyCapacity ?? 0
    readonly property int health: device?.healthSupported ? Math.round(device.healthPercentage) : -1

    readonly property string stateLabel: {
        if (charging)
            return "Charging";
        if (state === UPowerDeviceState.FullyCharged)
            return "Full";
        if (pluggedIn)
            return "Holding"; // on AC, held below a charge limit
        return "Discharging";
    }

    // The kernel's own battery (BAT0, BAT1...), for the files UPower skips.
    readonly property string _sysfs: {
        const bat = UPower.devices.values.find(d => d.isLaptopBattery && d.nativePath !== "");
        return bat ? `/sys/class/power_supply/${bat.nativePath}` : "";
    }
    property int cycles: -1
    property int limitStart: -1
    property int limitEnd: -1
    readonly property string limit: limitEnd < 0 || limitEnd >= 100 ? "" : limitStart > 0 ? `${limitStart}-${limitEnd}%` : `${limitEnd}%`

    // sysfs files don't notify, so whoever shows them calls this first.
    function refresh() {
        for (const f of [cycleFile, startFile, endFile, ppdFile])
            if (f.path !== "")
                f.reload();
    }

    function _int(text) {
        const n = parseInt(text);
        return isNaN(n) ? -1 : n;
    }

    FileView {
        id: cycleFile
        onLoaded: root.cycles = root._int(text())
        onLoadFailed: root.cycles = -1
        path: root._sysfs ? root._sysfs + "/cycle_count" : ""
        printErrors: false
    }

    FileView {
        id: startFile
        onLoaded: root.limitStart = root._int(text())
        onLoadFailed: root.limitStart = -1
        path: root._sysfs ? root._sysfs + "/charge_control_start_threshold" : ""
        printErrors: false
    }

    FileView {
        id: endFile
        onLoaded: root.limitEnd = root._int(text())
        onLoadFailed: root.limitEnd = -1
        path: root._sysfs ? root._sysfs + "/charge_control_end_threshold" : ""
        printErrors: false
    }

    // Power profiles: Quickshell can't tell whether the daemon exists, so
    // look for its CLI, part of the same package.
    property bool profilesAvailable: false
    readonly property int profile: profilesAvailable ? PowerProfiles.profile : -1
    readonly property bool hasPerformance: profilesAvailable && PowerProfiles.hasPerformanceProfile

    function setProfile(p) {
        PowerProfiles.profile = p;
    }

    FileView {
        id: ppdFile
        onLoaded: root.profilesAvailable = true
        onLoadFailed: root.profilesAvailable = false
        path: "/usr/bin/powerprofilesctl"
        printErrors: false
    }

    function formatTime(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }
}
