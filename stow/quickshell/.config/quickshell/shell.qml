//@ pragma UseQApplication
import Quickshell
import qs.modules.bar
import qs.modules.clipboard
import qs.modules.launcher
import qs.modules.lock
import qs.modules.osd
import qs.modules.polkit

// Entry point: only instantiates modules. Each module lives in modules/<name>/.
ShellRoot {
    Bar {}
    ClipboardPicker {}
    Launcher {}
    Lock {}
    Osd {}
    Polkit {}
}
