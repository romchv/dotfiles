pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop applications: search and launch. Launch counts are kept in the
// shell's state dir and lift frequently used apps in the results.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    property var usage: ({})

    // Best matches first. Empty query: everything, most used first.
    function search(query) {
        const q = query.trim().toLowerCase();
        return all
            .map(entry => ({ entry, score: q ? match(entry, q) : 1 }))
            .filter(r => r.score > 0)
            .map(r => ({ entry: r.entry, score: r.score + Math.min(usage[r.entry.id] ?? 0, 30) * 5 }))
            .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
            .map(r => r.entry);
    }

    function match(entry, q) {
        const name = entry.name.toLowerCase();
        if (name === q)
            return 1000;
        if (name.startsWith(q))
            return 800 - name.length;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 600 - name.length;
        if (name.includes(q))
            return 400 - name.indexOf(q);
        const extra = [entry.genericName, entry.id, ...(entry.keywords ?? [])].join(" ").toLowerCase();
        if (extra.includes(q))
            return 200;
        // Letters in order with gaps ("ffx" -> Firefox), tighter is better.
        let at = -1, gaps = 0;
        for (const c of q) {
            const next = name.indexOf(c, at + 1);
            if (next < 0)
                return 0;
            gaps += next - at - 1;
            at = next;
        }
        return Math.max(1, 100 - gaps);
    }

    function launch(entry) {
        usage = Object.assign({}, usage, { [entry.id]: (usage[entry.id] ?? 0) + 1 });
        usageFile.setText(JSON.stringify(usage));
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["foot", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        printErrors: false // missing until the first launch
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }
}
