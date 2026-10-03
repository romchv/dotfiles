pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Emoji for the picker, from data/emoji.tsv (see data/make-emoji.py). Search
// matches names first, then CLDR keywords ("lol" finds 😂). The last ones
// picked come first and are kept in the state dir.
Singleton {
    id: root

    property var all: [] // { char, name, keywords }
    readonly property var recent: state.recent
    readonly property var byChar: {
        const map = {};
        for (const e of all)
            map[e.char] = e;
        return map;
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (!q) {
            const first = recent.map(c => byChar[c]).filter(e => e);
            return first.concat(all.filter(e => !recent.includes(e.char)));
        }
        const ranked = [];
        for (const e of all) {
            let rank = -1;
            if (e.name.startsWith(q))
                rank = 0;
            else if (e.name.includes(" " + q))
                rank = 1;
            else if (e.keywords.some(k => k.startsWith(q)))
                rank = 2;
            else if (e.name.includes(q) || e.keywords.some(k => k.includes(q)))
                rank = 3;
            if (rank >= 0)
                ranked.push({ e, rank });
        }
        // sort is stable, so Unicode's order holds within a rank.
        return ranked.sort((a, b) => a.rank - b.rank).map(r => r.e);
    }

    function used(char) {
        state.recent = [char].concat(state.recent.filter(c => c !== char)).slice(0, 24);
    }

    FileView {
        path: Quickshell.shellDir + "/data/emoji.tsv"
        onLoaded: root.all = text().split("\n").filter(l => l.includes("\t")).map(line => {
            const [char, name, keywords] = line.split("\t");
            return { char, name, keywords: keywords ? keywords.split(" | ") : [] };
        })
    }

    FileView {
        path: Quickshell.statePath("emoji.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: state

            property var recent: []
        }
    }
}
