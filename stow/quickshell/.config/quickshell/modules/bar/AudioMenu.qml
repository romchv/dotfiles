import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.components
import qs.services

// Audio in the bar: the glyph shows the volume; scroll over it to change
// it, right-click to mute. A click (or `qs ipc call audio toggle`, on the
// focused monitor) opens a dropdown: the switch mutes, then output and
// input volume with every device (click one to make it the default), and a
// volume for each app playing. Click a slider's glyph to mute just that one.
BarButton {
    id: root

    required property ShellScreen screen
    readonly property bool open: Panels.current === "audio" && Panels.screen === screen.name

    text: Audio.icon
    size: Style.font.iconMedium
    tooltip: open ? "" : Audio.muted ? "Muted" : `Volume ${Math.round(Audio.volume * 100)}%`
    onClicked: mouse => mouse.button === Qt.RightButton ? Audio.toggleMute() : Panels.toggle("audio", screen.name)
    onScrolled: wheel => Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))

    // Pipewire only fills in volumes for tracked nodes; Audio tracks the
    // defaults, this the rest while the menu shows them.
    PwObjectTracker {
        objects: root.open ? [...Audio.sinks, ...Audio.sources, ...Audio.streams] : []
    }

    DropdownPanel {
        target: root
        screen: root.screen
        open: root.open
        glyph: Audio.icon
        title: "Audio"
        status: Audio.muted ? "Muted" : `${Math.round(Audio.volume * 100)}% · ${Audio.sink ? Audio.label(Audio.sink) : "No output"}`
        checked: !Audio.muted
        onToggled: Audio.toggleMute()
        onDismissed: Panels.close()

        DropdownSection {
            title: "Output"
            count: Audio.sinks.length

            VolumeRow {
                node: Audio.sink
            }

            Repeater {
                model: Audio.sinks

                DeviceRow {}
            }
        }

        DropdownSection {
            title: "Input"
            count: Audio.sources.length

            VolumeRow {
                node: Audio.source
                glyph: Audio.micMuted ? "󰍭" : "󰍬"
            }

            Repeater {
                model: Audio.sources

                DeviceRow {}
            }
        }

        DropdownSection {
            title: "Apps"
            count: Audio.streams.length
            empty: "Nothing playing"

            Repeater {
                model: Audio.streams

                VolumeRow {
                    required property var modelData

                    node: modelData
                    label: Audio.label(modelData)
                }
            }
        }
    }

    // Selecting only: a device's own volume is its VolumeRow once default.
    component DeviceRow: DropdownRow {
        required property var modelData

        glyph: Audio.deviceGlyph(modelData)
        label: Audio.label(modelData)
        active: modelData === Audio.sink || modelData === Audio.source
        status: active ? "Default" : ""
        onClicked: Audio.setDefault(modelData)
    }

    // A slider for one node's volume, an optional name above it, and its
    // percentage. The glyph mutes it.
    component VolumeRow: ColumnLayout {
        id: vol

        property var node: null
        property string label: ""
        property string glyph: node?.audio?.muted || (node?.audio?.volume ?? 0) <= 0 ? "󰝟" : "󰕾"
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property color textColor: Style.popups.text ?? Style.colors.foreground

        visible: !!node
        Layout.fillWidth: true
        Layout.leftMargin: Style.space.rowPaddingX
        Layout.rightMargin: Style.space.rowPaddingX
        Layout.bottomMargin: Style.space.xs
        spacing: 0

        StyledText {
            visible: vol.label !== ""
            Layout.fillWidth: true
            text: vol.label
            size: Style.font.bodySmall
            color: vol.textColor
            opacity: 0.8
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.space.xl

            StyledText {
                Layout.preferredWidth: Style.font.icon * 1.4
                text: vol.glyph
                size: Style.font.icon
                color: vol.textColor
                opacity: vol.muted ? 0.6 : 1
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Style.space.sm
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (vol.node?.audio) vol.node.audio.muted = !vol.node.audio.muted
                }
            }

            Slider {
                Layout.fillWidth: true
                value: vol.node?.audio?.volume ?? 0
                dimmed: vol.muted
                onMoved: v => {
                    if (vol.node?.audio)
                        vol.node.audio.volume = v;
                }
            }

            StyledText {
                Layout.preferredWidth: Style.font.caption * 3
                text: `${Math.round((vol.node?.audio?.volume ?? 0) * 100)}%`
                size: Style.font.caption
                color: vol.textColor
                opacity: 0.6
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
