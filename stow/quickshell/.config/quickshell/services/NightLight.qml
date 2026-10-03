pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: warms the screen by running hyprsunset while enabled.
// Stopping it restores normal colors. Resets to off when the shell restarts;
// the temperature is kept in the state dir. While running, a new
// temperature goes over hyprsunset's IPC instead of restarting it.
Singleton {
    id: root

    readonly property int minTemperature: 2000
    readonly property int maxTemperature: 6500
    property bool enabled: false
    property alias temperature: state.temperature // Kelvin, lower is warmer

    function toggle() {
        enabled = !enabled;
    }

    function setTemperature(kelvin) {
        temperature = Math.round(Math.max(minTemperature, Math.min(maxTemperature, kelvin)) / 100) * 100;
    }

    Process {
        running: root.enabled
        command: ["hyprsunset", "--temperature", String(root.temperature)]
    }

    // At most one hyprctl call per tick while dragging, always with the latest value.
    onTemperatureChanged: if (enabled && !send.running) send.start()

    Timer {
        id: send
        interval: 50
        onTriggered: Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(root.temperature)])
    }

    FileView {
        path: Quickshell.statePath("nightlight.json")
        printErrors: false
        watchChanges: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: state

            property int temperature: 4000
        }
    }
}
