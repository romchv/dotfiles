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
                // [ \t] not \s: an empty value must not run on into the next line.
                const file = block.match(/^[ \t]*path[ \t]*=[ \t]*(.+?)[ \t]*$/m)?.[1];
                if (!file)
                    continue;
                const monitor = block.match(/^[ \t]*monitor[ \t]*=[ \t]*(.*?)[ \t]*$/m)?.[1] ?? "";
                found[monitor] = "file://" + file.replace(/^~/, Quickshell.env("HOME"));
            }
            root.paths = found;
        }
    }
}
