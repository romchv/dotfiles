//@ pragma UseQApplication
import Quickshell
import qs.modules.bar
import qs.modules.calculator
import qs.modules.clipboard
import qs.modules.desktop
import qs.modules.emoji
import qs.modules.keybinds
import qs.modules.launcher
import qs.modules.lock
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit
import qs.modules.power
import qs.modules.wallpapers

// Entry point: only instantiates modules. Each module lives in modules/<name>/.
ShellRoot {
    Bar {}
    Calculator {}
    ClipboardPicker {}
    Desktop {}
    EmojiPicker {}
    KeybindsPicker {}
    Launcher {}
    Lock {}
    NotificationPopups {}
    Osd {}
    Polkit {}
    PowerMenu {}
    WallpaperPicker {}
}
