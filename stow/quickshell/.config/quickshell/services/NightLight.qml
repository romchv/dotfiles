pragma Singleton

import Quickshell
import Quickshell.Io

// Night light: warms the screen by running hyprsunset while enabled.
// Stopping it restores normal colors. Resets to off when the shell restarts.
Singleton {
    id: root

    property bool enabled: false
    property int temperature: 4000 // Kelvin, lower is warmer

    function toggle() {
        enabled = !enabled;
    }

    Process {
        running: root.enabled
        command: ["hyprsunset", "--temperature", String(root.temperature)]
    }
}
