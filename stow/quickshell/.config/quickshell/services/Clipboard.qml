pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Clipboard history from cliphist (fed by the `wl-paste --watch cliphist
// store` watchers in Hyprland's autostart). Picking an entry copies it back
// with wl-copy and pastes it into the focused window with the same keys as
// the universal paste: Shift+Insert in terminals, Ctrl+V elsewhere.
Singleton {
    id: root

    property var entries: [] // newest first: { id, line, isImage, label }

    function refresh() {
        lister.running = true;
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        return q ? entries.filter(e => e.label.toLowerCase().includes(q)) : entries;
    }

    function paste(entry) {
        copier.command = ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id];
        copier.running = true;
    }

    // Same, for text that isn't in the history yet (the emoji picker).
    function pasteText(text) {
        copier.command = ["wl-copy", "--", text];
        copier.running = true;
    }

    function copyText(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function remove(entry) {
        entries = entries.filter(e => e.id !== entry.id);
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", entry.line]);
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    const body = line.slice(tab + 1);
                    const image = body.match(/^\[\[ binary data (.+) \]\]$/);
                    return {
                        id: line.slice(0, tab),
                        line,
                        isImage: !!image,
                        label: image ? `Image · ${image[1]}` : body.replace(/\s+/g, " ").trim()
                    };
                });
            }
        }
    }

    // Copy, then paste once the picker is gone and focus is back on the window.
    Process {
        id: copier
        onExited: pasteDelay.restart()
    }

    Timer {
        id: pasteDelay
        interval: 120
        onTriggered: activeWindow.running = true
    }

    Process {
        id: activeWindow
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let tags = [];
                try {
                    tags = JSON.parse(text).tags ?? [];
                } catch (e) {}
                const terminal = tags.some(t => t.replace(/\*$/, "") === "terminal");
                root.sendKeys(terminal ? "SHIFT" : "CTRL", terminal ? "Insert" : "V");
            }
        }
    }

    // Down/up pair, as in conf/bindings/clipboard.lua (send_shortcut can leave keys stuck).
    property var keyUp: null
    function sendKeys(mods, key) {
        Hyprland.dispatch(`hl.dsp.send_key_state({ mods = "${mods}", key = "${key}", state = "down" })`);
        keyUp = `hl.dsp.send_key_state({ mods = "${mods}", key = "${key}", state = "up" })`;
        keyUpTimer.restart();
    }

    Timer {
        id: keyUpTimer
        interval: 50
        onTriggered: Hyprland.dispatch(root.keyUp)
    }
}
