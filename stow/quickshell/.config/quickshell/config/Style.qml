pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every visual value the shell uses. Modules read Style.*, never literals.
// Source: ~/.local/state/theme/current/shell.json, written by theme-switch
// and watched, so switching themes restyles the shell live.
Singleton {
    id: root

    property var theme: ({})

    function _parse(text) {
        try {
            root.theme = JSON.parse(text);
        } catch (e) {
            console.warn("Style: bad shell.json:", e);
        }
    }

    // Blocking first read so nothing renders with an empty theme; later
    // changes (theme-switch) arrive through onLoaded.
    Component.onCompleted: _parse(file.text())

    FileView {
        id: file
        blockLoading: true
        // QS_THEME_FILE: the greeter's copy (it can't read ~).
        path: Quickshell.env("QS_THEME_FILE")
            || (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/theme/current/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._parse(text())
        onLoadFailed: err => console.warn("Style: can't read shell.json:", FileViewError.toString(err))
    }

    // ---- raw theme sections (colors resolved, keys camelCased) ----
    readonly property var colors: theme.colors ?? ({})
    readonly property bool dark: (theme.mode ?? "dark") === "dark"
    readonly property var bar: theme.bar ?? ({})
    readonly property var controls: theme.controls ?? ({})
    readonly property var popups: theme.popups ?? ({})
    readonly property var tooltip: theme.tooltip ?? ({})
    readonly property var notifications: theme.notifications ?? ({})
    readonly property var launcher: theme.launcher ?? ({})
    readonly property var menu: theme.menu ?? ({})
    readonly property var polkit: theme.polkit ?? ({})
    readonly property var lock: theme.lock ?? ({})

    // ---- helpers ----
    function alpha(c, a) {
        return Qt.alpha(c ?? "transparent", a ?? 1);
    }

    // ---- geometry (matches Hyprland: rounding 0, border_size 2) ----
    readonly property int radius: 0
    readonly property int borderWidth: 2

    // ---- type scale: base-size is the rem root, per-token px overrides win ----
    readonly property var _font: theme.font ?? ({})
    readonly property real fontBase: Math.max(1, _font.baseSize ?? 12)
    function _fs(token, ratio) {
        return _font[token] ?? Math.round(fontBase * ratio);
    }
    readonly property QtObject font: QtObject {
        readonly property string family: root._font.family ?? "JetBrainsMono Nerd Font"
        readonly property int caption: root._fs("caption", 10 / 12)
        readonly property int bodySmall: root._fs("bodySmall", 11 / 12)
        readonly property int body: root._fs("body", 1)
        readonly property int subtitle: root._fs("subtitle", 13 / 12)
        readonly property int title: root._fs("title", 14 / 12)
        readonly property int heading: root._fs("heading", 16 / 12)
        readonly property int display: root._fs("display", 2)
        readonly property int displayLarge: root._fs("displayLarge", 28 / 12)
        readonly property int hero: root._fs("hero", 56 / 12) // pomodoro countdown
        readonly property int iconSmall: root._fs("iconSmall", 11 / 12)
        readonly property int icon: root._fs("icon", 14 / 12)
        // Material volume/battery glyphs sit small in their box: this size
        // matches them optically to wifi/bluetooth at `icon`.
        readonly property int iconMedium: root._fs("iconMedium", 17 / 12)
        readonly property int iconLarge: root._fs("iconLarge", 1.5)
    }

    // ---- spacing: defaults * scale (* font factor), per-token px overrides win ----
    readonly property var _space: theme.spacing ?? ({})
    readonly property real spaceScale: (_space.scale ?? 1) * ((_space.scaleWithFont ?? true) ? fontBase / 12 : 1)
    function _sp(token, base) {
        return _space[token] ?? Math.round(base * spaceScale);
    }
    readonly property QtObject space: QtObject {
        readonly property int xxs: root._sp("xxs", 2)
        readonly property int xs: root._sp("xs", 3)
        readonly property int sm: root._sp("sm", 4)
        readonly property int md: root._sp("md", 6)
        readonly property int lg: root._sp("lg", 8)
        readonly property int xl: root._sp("xl", 10)
        readonly property int xxl: root._sp("xxl", 12)
        readonly property int xxxl: root._sp("xxxl", 14)
        readonly property int huge: root._sp("huge", 18)
        readonly property int controlGap: root._sp("controlGap", 8)
        readonly property int controlPaddingX: root._sp("controlPaddingX", 10)
        readonly property int controlPaddingY: root._sp("controlPaddingY", 6)
        readonly property int inputPaddingY: root._sp("inputPaddingY", 7)
        readonly property int controlHeight: root._sp("controlHeight", 28)
        readonly property int popupRowHeight: root._sp("popupRowHeight", 28)
        readonly property int rowGap: root._sp("rowGap", 8)
        readonly property int rowPaddingX: root._sp("rowPaddingX", 12)
        readonly property int labelGap: root._sp("labelGap", 4)
        readonly property int panelGap: root._sp("panelGap", 14)
        readonly property int panelPadding: root._sp("panelPadding", 18)
        readonly property int popupPadding: root._sp("popupPadding", 14)
        readonly property int dropdownWidth: root._sp("dropdownWidth", 240)
        readonly property int deviceMenuWidth: root._sp("deviceMenuWidth", 360)
        readonly property int launcherWidth: root._sp("launcherWidth", 300)
        readonly property int cheatsheetWidth: root._sp("cheatsheetWidth", 520)
        readonly property int launcherRowHeight: root._sp("launcherRowHeight", 40)
        readonly property int dialogWidth: root._sp("dialogWidth", 380)
        readonly property int notificationWidth: root._sp("notificationWidth", 360)
        readonly property int lockFieldWidth: root._sp("lockFieldWidth", 320)
        readonly property int osdWidth: root._sp("osdWidth", 240)
        readonly property int osdMargin: root._sp("osdMargin", 60)
    }

    // Lockscreen wallpaper treatment: blur 0..1, darkening 0..1.
    readonly property real lockBlur: theme.lock?.blur ?? 0.8
    readonly property real lockDim: theme.lock?.dim ?? 0.35

    // Notification popups: default display time (ms) when the app sets none,
    // and how many show at once.
    readonly property int notificationTimeout: theme.notifications?.timeout ?? 5000
    readonly property int notificationMax: theme.notifications?.max ?? 5

    // Rows the launcher shows before scrolling.
    readonly property int launcherRows: theme.launcher?.rows ?? 8

    // ---- bar size (cross-axis), optionally tracking the font size ----
    readonly property int barHeight: Math.round((bar.sizeHorizontal ?? 26) * ((bar.scaleWithFont ?? true) ? fontBase / 12 : 1))
    readonly property int barWidth: Math.round((bar.sizeVertical ?? 28) * ((bar.scaleWithFont ?? true) ? fontBase / 12 : 1))

    // ---- motion: short and quiet ----
    readonly property QtObject anim: QtObject {
        readonly property int fast: 100
        readonly property int normal: 180
        readonly property int slow: 280
        readonly property int easing: Easing.OutCubic
    }
}
