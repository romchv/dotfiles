pragma Singleton

import Quickshell

// Starting external programs. TUIs open in foot with the TUI.float app-id,
// which Hyprland floats and centers (conf/windowrules.lua).
Singleton {
    function tui(...command) {
        Quickshell.execDetached(["foot", "--app-id=TUI.float", "-e", ...command]);
    }
}
