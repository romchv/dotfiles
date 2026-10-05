pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pomodoro timer: focus blocks split by short breaks, with a long break
// after every `sessions` blocks. Each phase starts the next one on its own
// and sends a notification. Durations, the running phase and today's tally
// are kept in the state dir, so a shell restart resumes the timer.
Singleton {
    id: root

    readonly property var names: ({ focus: "Focus", short: "Short break", long: "Long break" })

    readonly property string phase: state.phase // "focus", "short" or "long"
    readonly property int session: state.session // 1-based block within the cycle
    readonly property bool running: state.running
    readonly property int focusMinutes: state.focus
    readonly property int shortMinutes: state.shortBreak
    readonly property int longMinutes: state.longBreak
    readonly property int sessions: state.sessions
    readonly property int todayBlocks: state.day === today ? state.blocks : 0
    readonly property int todayMinutes: state.day === today ? state.minutes : 0

    readonly property bool isBreak: phase !== "focus"
    readonly property bool started: running || state.left >= 0
    readonly property int duration: minutesOf(phase) * 60
    // Seconds left, counted from the wall clock so a slow tick can't drift.
    readonly property int remaining: running ? Math.max(0, Math.ceil((state.endsAt - now) / 1000)) : state.left >= 0 ? state.left : duration
    readonly property real progress: duration > 0 ? 1 - remaining / duration : 0
    readonly property date endsAt: new Date(running ? state.endsAt : now + remaining * 1000)
    // Blocks finished in this cycle: the current one counts once its break starts.
    readonly property int done: isBreak ? session : session - 1
    readonly property string nextPhase: phase === "focus" ? (session >= sessions ? "long" : "short") : "focus" // as following()

    property real now: Date.now()
    readonly property string today: Qt.formatDate(new Date(now), "yyyy-MM-dd")

    function minutesOf(p) {
        return p === "focus" ? state.focus : p === "short" ? state.shortBreak : state.longBreak;
    }

    function clock(seconds) {
        const m = Math.floor(seconds / 60), s = seconds % 60;
        return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
    }

    // The functions below read `state` directly: the bindings above can
    // still hold the old values partway through one of them.
    function secondsLeft() {
        if (state.running)
            return Math.max(0, Math.ceil((state.endsAt - Date.now()) / 1000));
        return state.left >= 0 ? state.left : minutesOf(state.phase) * 60;
    }

    function start() {
        if (state.running)
            return;
        now = Date.now();
        state.endsAt = now + secondsLeft() * 1000;
        state.running = true;
    }

    function pause() {
        if (!state.running)
            return;
        now = Date.now();
        state.left = secondsLeft();
        state.running = false;
    }

    function toggle() {
        state.running ? pause() : start();
    }

    // Back to the start of this phase; again from there, back to block 1.
    function reset() {
        if (!state.running && state.left < 0) {
            state.phase = "focus";
            state.session = 1;
        }
        state.running = false;
        state.left = -1;
    }

    function skip() {
        enter(following(), state.running);
    }

    function setMinutes(p, minutes) {
        const m = Math.max(1, Math.min(180, Math.round(minutes)));
        if (p === "focus")
            state.focus = m;
        else if (p === "short")
            state.shortBreak = m;
        else
            state.longBreak = m;
    }

    function setSessions(n) {
        state.sessions = Math.max(1, Math.min(12, n));
        state.session = Math.min(state.session, state.sessions);
    }

    function preset(focus, shortBreak) {
        state.focus = focus;
        state.shortBreak = shortBreak;
    }

    function following() {
        return state.phase === "focus" ? (state.session >= state.sessions ? "long" : "short") : "focus";
    }

    function enter(p, run) {
        if (state.phase !== "focus" && p === "focus")
            state.session = state.session >= state.sessions ? 1 : state.session + 1;
        state.phase = p;
        state.left = -1;
        state.running = false;
        if (run)
            start();
    }

    function finish() {
        const was = state.phase;
        if (was === "focus") {
            if (state.day !== today) {
                state.day = today;
                state.blocks = 0;
                state.minutes = 0;
            }
            state.blocks += 1;
            state.minutes += state.focus;
        }
        enter(following(), true);
        const until = Qt.formatTime(new Date(state.endsAt), "HH:mm");
        const body = `${names[state.phase]} · ${minutesOf(state.phase)} min, until ${until}`;
        Quickshell.execDetached(["notify-send", "-a", "Pomodoro", "-i", "alarm-symbolic", was === "focus" ? "Focus block done" : "Break over", body]);
    }

    Timer {
        interval: 250
        running: root.running
        repeat: true
        onTriggered: {
            root.now = Date.now();
            if (root.secondsLeft() <= 0)
                root.finish();
        }
    }

    // Rolls `today` over at midnight while idle.
    Timer {
        interval: 60 * 1000
        running: !root.running
        repeat: true
        onTriggered: root.now = Date.now()
    }

    // Saved once a change settles: writing on every property set reloads
    // the file mid-update and throws away the properties set after it.
    Timer {
        id: save
        interval: 100
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.statePath("pomodoro.json")
        printErrors: false
        watchChanges: false
        onAdapterUpdated: save.restart()

        JsonAdapter {
            id: state

            // Minutes
            property int focus: 25
            property int shortBreak: 5
            property int longBreak: 15
            property int sessions: 4

            property string phase: "focus"
            property int session: 1
            property bool running: false
            property real endsAt: 0 // ms since epoch, while running
            property int left: -1 // seconds left while paused, -1 when not started

            property string day: ""
            property int blocks: 0
            property int minutes: 0
        }
    }
}
