pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hyprland keybinds for the cheatsheet, read from `hyprctl binds -j` in
// config order. Numbered series ("Switch to workspace 1".."10") collapse
// into one row ("SUPER + 1…0").
Singleton {
    id: root

    property var binds: []

    readonly property var modifiers: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]
    readonly property var keyNames: ({
            RETURN: "Enter",
            ESCAPE: "Esc",
            SPACE: "Space",
            TAB: "Tab",
            DELETE: "Delete",
            PRINT: "Print",
            COMMA: ",",
            PERIOD: ".",
            MINUS: "-",
            EQUAL: "=",
            LEFT: "←",
            RIGHT: "→",
            UP: "↑",
            DOWN: "↓",
            "mouse:272": "Left click",
            "mouse:273": "Right click",
            mouse_down: "Scroll down",
            mouse_up: "Scroll up",
            XF86AudioRaiseVolume: "Volume Up",
            XF86AudioLowerVolume: "Volume Down",
            XF86AudioMute: "Mute",
            XF86AudioMicMute: "Mic Mute",
            XF86MonBrightnessUp: "Brightness Up",
            XF86MonBrightnessDown: "Brightness Down",
            XF86KbdBrightnessUp: "Kbd Light Up",
            XF86KbdBrightnessDown: "Kbd Light Down",
            XF86AudioNext: "Next",
            XF86AudioPrev: "Previous",
            XF86AudioPlay: "Play",
            XF86AudioPause: "Pause",
            XF86Eject: "Eject"
        })

    function refresh() {
        lister.running = true;
    }

    function keyName(key) {
        if (keyNames[key])
            return keyNames[key];
        if (key.startsWith("XF86"))
            return key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
        return key.length === 1 ? key.toUpperCase() : key.charAt(0) + key.slice(1).toLowerCase();
    }

    function mods(mask) {
        return modifiers.filter(m => mask & m[0]).map(m => m[1]);
    }

    function build(raw) {
        const rows = [];
        const series = {}; // "mask|description prefix" -> row
        const seen = new Set();
        for (const b of raw) {
            if (b.submap || !b.description || !b.key)
                continue;
            const numbered = b.description.match(/^(.*\S) (\d+)$/);
            if (numbered && /^\d$/.test(b.key)) {
                const id = `${b.modmask}|${numbered[1]}`;
                if (series[id]) {
                    series[id].last = b.key;
                } else {
                    series[id] = { mods: mods(b.modmask), first: b.key, last: b.key, description: numbered[1] };
                    rows.push(series[id]);
                }
                continue;
            }
            const keys = [...mods(b.modmask), keyName(b.key)].join(" + ");
            if (seen.has(keys + b.description))
                continue;
            seen.add(keys + b.description);
            rows.push({ keys, description: b.description });
        }
        return rows.map(r => {
            const keys = r.keys ?? [...r.mods, r.first === r.last ? r.first : `${r.first}…${r.last}`].join(" + ");
            return { keys, description: r.description, haystack: `${r.description} ${keys}`.toLowerCase() };
        });
    }

    // Description prefix first, then a word of it, then anywhere in description or keys.
    function search(query) {
        const q = query.trim().toLowerCase();
        if (!q)
            return binds;
        return binds
            .map((bind, index) => ({ bind, index, score: match(bind, q) }))
            .filter(r => r.score > 0)
            .sort((a, b) => b.score - a.score || a.index - b.index)
            .map(r => r.bind);
    }

    function match(bind, q) {
        const description = bind.description.toLowerCase();
        if (description.startsWith(q))
            return 3;
        if (description.split(" ").some(w => w.startsWith(q)))
            return 2;
        return bind.haystack.includes(q) ? 1 : 0;
    }

    Process {
        id: lister
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.binds = root.build(JSON.parse(text));
                } catch (e) {
                    root.binds = [];
                }
            }
        }
    }
}
