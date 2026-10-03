pragma Singleton

import Quickshell
import Quickshell.Hyprland

// Which overlay is open ("launcher", "clipboard", "keybinds", "power", "wallpapers", "claude", "battery", "bluetooth", "wifi", "audio", "nightlight" or ""), shared by their
// IPC handlers, the bar and the overlays. One at a time: opening one
// replaces the other.
// `screen` is the monitor it opens on: the one clicked from the bar, else
// (IPC, keybinds) the focused one. Clicking a bar doesn't move Hyprland's
// monitor focus, so the bar has to say which screen it is.
Singleton {
    property string current: ""
    property string screen: ""
    readonly property ShellScreen shellScreen: Quickshell.screens.find(s => s.name === screen) ?? Quickshell.screens[0]

    function open(name, screenName) {
        screen = screenName ?? Hyprland.focusedMonitor?.name ?? "";
        current = name;
    }
    function close() {
        current = "";
    }
    function toggle(name, screenName) {
        const target = screenName ?? Hyprland.focusedMonitor?.name ?? "";
        if (current === name && screen === target)
            close();
        else
            open(name, target);
    }
}
