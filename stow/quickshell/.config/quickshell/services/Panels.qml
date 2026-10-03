pragma Singleton

import Quickshell

// Which overlay is open ("launcher", "clipboard", "keybinds", "power", "wallpapers", "claude", "battery", "bluetooth", "wifi" or ""), shared by their
// IPC handlers, the bar and the overlays. One at a time: opening one
// replaces the other.
Singleton {
    property string current: ""

    function open(name) {
        current = name;
    }
    function close() {
        current = "";
    }
    function toggle(name) {
        current = current === name ? "" : name;
    }
}
