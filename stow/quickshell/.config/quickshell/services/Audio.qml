pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output sink (volume, mute, icon) and default mic (mute), plus
// every output, input and playing app for the bar's audio menu.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? false

    // By type: `properties` stays empty until a node is tracked.
    readonly property var _nodes: Pipewire.nodes.values
    readonly property var sinks: _nodes.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: _nodes.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var streams: _nodes.filter(n => n.type === PwNodeType.AudioOutStream)

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

    function setDefault(node) {
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    // What a node is called in menus: an app's name for streams, else the
    // device's short name.
    function label(node) {
        const p = node.properties;
        return node.isStream ? (p["application.name"] || p["media.name"] || node.name)
                             : (node.nickname || node.description || node.name);
    }

    function deviceGlyph(node) {
        const p = node.properties, name = node.name;
        if (/^bluez/.test(name) || /head/.test(p["device.form-factor"] ?? ""))
            return node.isSink ? "󰋋" : "󰋎";
        if (/hdmi/i.test(name))
            return "󰍹";
        return node.isSink ? "󰓃" : "󰍬";
    }

    // Pipewire only fills in audio properties for tracked nodes.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
