pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Active layout of the main keyboard as a short label: us -> en, us/intl -> en-intl.
Singleton {
    id: root

    property string label: ""

    // xkb layout code -> language, when they differ. Anything else shows its code.
    readonly property var languages: ({ us: "en", gb: "en" })

    function refresh() {
        devices.running = true;
    }

    function next() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]);
    }

    Process {
        id: devices
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const keyboards = JSON.parse(text).keyboards;
                const kb = keyboards.find(k => k.main) ?? keyboards[0];
                if (!kb)
                    return;
                const i = kb.active_layout_index;
                const layout = kb.layout.split(",")[i] ?? "";
                const variant = kb.variant.split(",")[i] ?? "";
                root.label = (root.languages[layout] ?? layout) + (variant ? "-" + variant : "");
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refresh();
        }
    }
}
