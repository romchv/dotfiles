import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Volume, mic and brightness feedback: a small card at the bottom center of
// the focused monitor, fading out after a moment.
// Volume and mic: shown on any change (media keys, bar scroll, wiremix).
// Brightness: only after `qs ipc call osd brightness` (sent by the brightness
// keybinds), since hypridle dims and restores the backlight on its own.
Scope {
    id: root

    property string icon: ""
    property real value: -1 // 0..1 draws a bar; below 0 shows `label` instead
    property string label: ""
    property bool open: false
    property bool armed: false // ignore the initial values while services settle
    property real brightnessUntil: 0 // brightness changes before this time show the OSD

    function show(icon, value, label) {
        if (!armed)
            return;
        root.icon = icon;
        root.value = value;
        root.label = label ?? "";
        open = true;
        hideTimer.restart();
    }

    function showVolume() {
        show(Audio.icon, Audio.muted ? 0 : Audio.volume);
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.open = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.showVolume();
        }
        function onMutedChanged() {
            root.showVolume();
        }
        function onMicMutedChanged() {
            root.show(Audio.micMuted ? "󰍭" : "󰍬", -1, Audio.micMuted ? "Microphone muted" : "Microphone on");
        }
    }

    IpcHandler {
        target: "osd"

        // The keybind's brightnessctl write and this call race each other, so
        // show the current value now and follow the change for a moment.
        function brightness(): void {
            root.brightnessUntil = Date.now() + 1000;
            root.show(Brightness.icon, Brightness.value);
        }
    }

    Connections {
        target: Brightness
        function onRawChanged() {
            if (Date.now() < root.brightnessUntil)
                root.show(Brightness.icon, Brightness.value);
        }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: card.opacity > 0
        anchors.bottom: true
        margins.bottom: Style.space.osdMargin
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"
        color: "transparent"
        implicitWidth: Style.space.osdWidth
        implicitHeight: card.implicitHeight
        mask: Region {} // clicks pass through

        Surface {
            id: card

            anchors.fill: parent
            implicitHeight: content.implicitHeight + Style.space.xxl * 2
            section: Style.popups
            opacity: root.open ? 1 : 0

            transform: Translate {
                y: root.open ? 0 : Style.space.lg

                Behavior on y {
                    NumberAnimation { duration: Style.anim.normal; easing.type: Style.anim.easing }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: Style.anim.normal; easing.type: Style.anim.easing }
            }

            RowLayout {
                id: content

                anchors.fill: parent
                anchors.margins: Style.space.xxl
                spacing: Style.space.xl

                StyledText {
                    text: root.icon
                    size: Style.font.iconLarge
                    color: Style.popups.text
                    horizontalAlignment: Text.AlignHCenter
                    Layout.preferredWidth: Style.font.iconLarge * 1.5
                }

                Rectangle {
                    visible: root.value >= 0
                    Layout.fillWidth: true
                    implicitHeight: Style.space.xs
                    color: Style.alpha(Style.popups.text, 0.2)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.value))
                        height: parent.height
                        color: Style.popups.text

                        Behavior on width {
                            NumberAnimation { duration: Style.anim.fast }
                        }
                    }
                }

                StyledText {
                    id: percent
                    visible: root.value >= 0
                    text: Math.round(root.value * 100)
                    color: Style.popups.text
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: widest.width

                    TextMetrics {
                        id: widest
                        font: percent.font
                        text: "100"
                    }
                }

                StyledText {
                    visible: root.value < 0
                    text: root.label
                    color: Style.popups.text
                    Layout.fillWidth: true
                }
            }
        }
    }
}
