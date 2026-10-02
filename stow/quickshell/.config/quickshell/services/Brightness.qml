pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Built-in display backlight (first device in /sys/class/backlight).
// brightnessctl writes the sysfs file, which FileView sees through inotify.
Singleton {
    id: root

    property string device: ""
    readonly property bool available: device !== "" && max > 0
    property int max: 0
    property int raw: 0
    readonly property real value: available ? raw / max : 0

    readonly property string icon: value < 0.34 ? "󰃞" : value < 0.67 ? "󰃟" : "󰃠"

    Process {
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        id: maxFile
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 0
    }

    FileView {
        id: currentFile
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.raw = parseInt(text()) || 0
    }
}
