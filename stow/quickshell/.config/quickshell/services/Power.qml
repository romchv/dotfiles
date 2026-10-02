pragma Singleton

import Quickshell
import Quickshell.Hyprland

// Session and power actions for the power menu: lock, suspend, hibernate,
// log out, reboot, shut down.
Singleton {
    readonly property var actions: [
        { id: "lock", name: "Lock", icon: "\u{F033E}", keywords: "screen" },
        { id: "suspend", name: "Suspend", icon: "\u{F0904}", keywords: "sleep" },
        { id: "hibernate", name: "Hibernate", icon: "\u{F0717}", keywords: "sleep disk" },
        { id: "logout", name: "Log out", icon: "\u{F0343}", keywords: "logout exit sign out quit session" },
        { id: "reboot", name: "Reboot", icon: "\u{F0709}", keywords: "restart" },
        { id: "shutdown", name: "Shut down", icon: "\u{F0425}", keywords: "shutdown power off poweroff halt" }
    ]

    // Name prefix first, then a word of the name, then anywhere in name or keywords.
    function search(query) {
        const q = query.trim().toLowerCase();
        if (!q)
            return actions;
        return actions
            .map((action, index) => ({ action, index, score: match(action, q) }))
            .filter(r => r.score > 0)
            .sort((a, b) => b.score - a.score || a.index - b.index)
            .map(r => r.action);
    }

    function match(action, q) {
        const name = action.name.toLowerCase();
        if (name.startsWith(q))
            return 3;
        if (name.split(" ").some(w => w.startsWith(q)) || action.keywords.split(" ").some(w => w.startsWith(q)))
            return 2;
        return (name + " " + action.keywords).includes(q) ? 1 : 0;
    }

    function run(action) {
        switch (action.id) {
        case "lock":
            // Through logind, so hypridle's lock_cmd runs the Quickshell lock.
            Quickshell.execDetached(["loginctl", "lock-session"]);
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "hibernate":
            Quickshell.execDetached(["systemctl", "hibernate"]);
            break;
        case "logout":
            Hyprland.dispatch("hl.dsp.exit()");
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }
}
