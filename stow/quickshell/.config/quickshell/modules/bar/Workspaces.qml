import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// Workspaces of this bar's monitor. Always shows the ones Hyprland's
// workspace rules pin to the monitor (1-5 when none do), plus any others
// that exist there. Active: filled square; empty: dimmed.
Row {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    property var rules: []

    readonly property var ids: {
        const pinned = rules.filter(r => r.monitor === screen.name)
            .map(r => parseInt(r.workspaceString))
            .filter(n => n > 0);
        const live = Hyprland.workspaces.values
            .filter(w => w.id > 0 && w.monitor?.name === screen.name)
            .map(w => w.id);
        return [...new Set([...(pinned.length ? pinned : [1, 2, 3, 4, 5]), ...live])].sort((a, b) => a - b);
    }

    Process {
        id: rulesProc
        command: ["hyprctl", "workspacerules", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.rules = JSON.parse(text)
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                rulesProc.running = true;
        }
    }

    Repeater {
        model: root.ids

        BarButton {
            required property int modelData
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
            readonly property bool active: root.monitor?.activeWorkspace?.id === modelData
            readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0

            text: active ? "󱓻" : modelData
            size: Style.font.body
            padding: Style.space.md
            label.opacity: active || occupied ? 1 : 0.5

            // Lua config: dispatch takes a Lua expression.
            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${modelData}" })`)
        }
    }
}
