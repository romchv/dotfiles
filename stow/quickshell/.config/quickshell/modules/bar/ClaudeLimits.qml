import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Claude Code plan limits: hover the glyph for the session and weekly meters,
// each with when it resets. Click it or `qs ipc call claude toggle` to keep
// them open (on the focused monitor); Esc or a click outside closes. The
// glyph turns `bar.active` past 80% of either.
BarButton {
    id: root

    required property ShellScreen screen
    readonly property bool pinned: Panels.current === "claude" && Hyprland.focusedMonitor?.name === screen.name
    readonly property bool high: Math.max(ClaudeUsage.session?.percent ?? 0, ClaudeUsage.weekly?.percent ?? 0) >= 80

    text: "\u{F06A9}" // robot
    label.color: high ? Style.bar.active : (Style.bar.text ?? Style.colors.foreground)
    onHoveredChanged: if (hovered) ClaudeUsage.refresh(60 * 1000)
    onPinnedChanged: if (pinned) ClaudeUsage.refresh(60 * 1000)
    onClicked: Panels.toggle("claude")

    PopupWindow {
        id: popup

        property date now: new Date()

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: Style.space.sm
        implicitWidth: Style.space.dropdownWidth
        implicitHeight: content.implicitHeight + Style.space.popupPadding * 2
        color: "transparent"
        visible: root.pinned || (delay.ready && root.hovered)

        // Same short delay as Tooltip, so sweeping across the bar doesn't flash it.
        Timer {
            id: delay
            property bool ready: false
            interval: 300
            running: root.hovered
            onRunningChanged: if (running) ready = false
            onTriggered: ready = true
        }

        // Keeps the "resets in" countdowns current while open.
        Timer {
            interval: 30 * 1000
            running: popup.visible
            repeat: true
            triggeredOnStart: true
            onTriggered: popup.now = new Date()
        }

        HyprlandFocusGrab {
            active: root.pinned
            windows: [popup]
            onCleared: Panels.close()
        }

        Surface {
            anchors.fill: parent
            section: Style.tooltip
            focus: true
            Keys.onEscapePressed: Panels.close()

            ColumnLayout {
                id: content

                anchors.fill: parent
                anchors.margins: Style.space.popupPadding
                spacing: Style.space.panelGap

                StyledText {
                    text: "Claude Code"
                    size: Style.font.title
                    font.bold: true
                    color: Style.tooltip.text
                }

                Meter {
                    title: "Session"
                    limit: ClaudeUsage.session
                }

                Meter {
                    title: "Weekly"
                    limit: ClaudeUsage.weekly
                }

                StyledText {
                    visible: ClaudeUsage.error !== "" || !ClaudeUsage.loaded
                    Layout.fillWidth: true
                    text: ClaudeUsage.error || "Loading…"
                    wrapMode: Text.Wrap
                    size: Style.font.caption
                    color: ClaudeUsage.error ? Style.bar.active : Style.tooltip.text
                    opacity: ClaudeUsage.error ? 1 : 0.6
                }
            }
        }
    }

    component Meter: ColumnLayout {
        id: meter

        required property string title
        required property var limit // { percent, resetsAt } from ClaudeUsage
        readonly property real value: (limit?.percent ?? 0) / 100

        visible: limit !== null
        Layout.fillWidth: true
        spacing: Style.space.labelGap

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: meter.title
                color: Style.tooltip.text
            }

            StyledText {
                text: `${Math.round(meter.limit?.percent ?? 0)}%`
                color: meter.value >= 0.8 ? Style.bar.active : Style.tooltip.text
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space.xs
            color: Style.alpha(Style.tooltip.text, 0.2)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.value))
                height: parent.height
                color: meter.value >= 0.8 ? Style.bar.active : Style.tooltip.text

                Behavior on width {
                    NumberAnimation { duration: Style.anim.normal }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.resetText(meter.limit?.resetsAt, popup.now)
            size: Style.font.caption
            color: Style.tooltip.text
            opacity: 0.6
        }
    }

    // "Resets in 2h 14m · 17:30", or "in 6d 11h · Sat 03:00" when not today.
    function resetText(at, now) {
        if (!at)
            return "No reset scheduled";
        const mins = Math.max(0, Math.round((at - now) / 60000));
        const d = Math.floor(mins / 1440), h = Math.floor(mins % 1440 / 60), m = mins % 60;
        const left = d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
        const sameDay = at.toDateString() === now.toDateString();
        const when = Qt.formatDateTime(at, sameDay ? "HH:mm" : "ddd HH:mm");
        return `Resets in ${left} · ${when}`;
    }
}
