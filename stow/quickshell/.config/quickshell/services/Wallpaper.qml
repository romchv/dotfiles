pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper paths from hyprpaper.conf, per monitor (blocks without a
// monitor apply to all). Used by the lockscreen background.
Singleton {
    id: root

    property var paths: ({}) // monitor name ("" = any) -> file URL

    function forScreen(name) {
        return paths[name] ?? paths[""] ?? Object.values(paths)[0] ?? "";
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const found = {};
            for (const block of text().split(/\}/)) {
                const file = block.match(/^\s*path\s*=\s*(.+?)\s*$/m)?.[1];
                if (!file)
                    continue;
                const monitor = block.match(/^\s*monitor\s*=\s*(.*?)\s*$/m)?.[1] ?? "";
                found[monitor] = "file://" + file.replace(/^~/, Quickshell.env("HOME"));
            }
            root.paths = found;
        }
    }
}
