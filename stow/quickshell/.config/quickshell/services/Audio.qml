pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output sink (volume, mute, icon) and default mic (mute).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property string icon: {
        if (muted || volume <= 0)
            return "󰝟";
        if (volume < 0.34)
            return "󰕿";
        if (volume < 0.67)
            return "󰖀";
        return "󰕾";
    }

    function setVolume(v) {
        if (ready && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (ready && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // Pipewire only fills in audio properties for tracked nodes.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
