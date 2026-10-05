pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Ambient sound for focus blocks: noise generated live by ffmpeg's lavfi
// through mpv, so there are no audio files to ship. Plays while a focus
// block is running, and during breaks too when `breaks` is on. The sound,
// volume and that switch are kept in the state dir.
Singleton {
    id: root

    // Amplitudes bring each one to about -22 dB, so switching keeps the level.
    readonly property var sounds: [
        { id: "brown", name: "Brown", glyph: "\u{F147D}", graph: "anoisesrc=c=brown:a=0.4" },
        { id: "pink", name: "Pink", glyph: "\u{F095B}", graph: "anoisesrc=c=pink:a=0.4" },
        { id: "white", name: "White", glyph: "\u{F0430}", graph: "anoisesrc=c=white:a=0.15" },
        // Filtered pink noise for the wash, sparse velvet clicks for drops.
        { id: "rain", name: "Rain", glyph: "\u{F0596}", graph: "anoisesrc=c=pink:a=1,highpass=f=400,lowpass=f=6000[a];anoisesrc=c=velvet:a=0.5,highpass=f=2500[b];[a][b]amix=inputs=2" },
        // Brown noise swelling every ten seconds.
        { id: "ocean", name: "Ocean", glyph: "\u{F078D}", graph: "anoisesrc=c=brown:a=0.45,tremolo=f=0.1:d=0.7" }
    ]

    readonly property string sound: state.sound // a sounds[].id, or "" for none
    readonly property int volume: state.volume // 0..100
    readonly property bool breaks: state.breaks
    readonly property bool playing: sound !== "" && Pomodoro.running && (!Pomodoro.isBreak || breaks)

    // Picking the current sound again turns it off.
    function select(id) {
        state.sound = state.sound === id ? "" : id;
    }

    function setVolume(v) {
        state.volume = Math.round(Math.max(0, Math.min(100, v)));
    }

    function setBreaks(on) {
        state.breaks = on;
    }

    // Live volume over mpv's JSON IPC on stdin, so changing it doesn't restart the sound.
    onVolumeChanged: players.instances.forEach(p => p.write(JSON.stringify({ command: ["set_property", "volume", volume] }) + "\n"))

    // One player per sound while playing: a new sound replaces the process.
    Variants {
        id: players

        model: root.playing ? [root.sound] : []

        Process {
            required property string modelData
            readonly property var entry: root.sounds.find(s => s.id === modelData)

            running: entry !== undefined
            stdinEnabled: true
            // The volume here only applies at start; later changes go over IPC.
            command: ["mpv", "--no-video", "--no-terminal", "--audio-client-name=Ambient", "--input-ipc-client=fd://0", `--volume=${root.volume}`, `av://lavfi:${entry?.graph ?? ""}`]
        }
    }

    // Saved once a change settles, see Pomodoro.
    Timer {
        id: save
        interval: 100
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.statePath("ambient.json")
        printErrors: false
        watchChanges: false
        onAdapterUpdated: save.restart()

        JsonAdapter {
            id: state

            property string sound: ""
            property int volume: 40
            property bool breaks: false
        }
    }
}
