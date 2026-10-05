import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Pomodoro timer in the bar: the glyph, colored while a focus block runs.
// A click (or `qs ipc call pomodoro toggle`) opens a dropdown with the
// countdown, the cycle, today's tally, the controls, the ambient sound and
// the durations; a middle click starts or pauses it.
BarButton {
    id: root

    required property ShellScreen screen
    readonly property bool open: Panels.current === "pomodoro" && Panels.screen === screen.name
    readonly property color textColor: Style.popups.text ?? Style.colors.foreground
    readonly property color accent: Style.colors.accent ?? textColor
    readonly property string glyph: Pomodoro.isBreak ? "\u{F0176}" : "\u{F051B}" // coffee, timer
    property bool settingsOpen: false

    text: glyph
    label.color: Pomodoro.running && !Pomodoro.isBreak ? Style.bar.active : (Style.bar.text ?? Style.colors.foreground)
    tooltip: open ? "" : Pomodoro.started ? `${Pomodoro.names[Pomodoro.phase]} · ${Pomodoro.clock(Pomodoro.remaining)}${Pomodoro.running ? "" : " · paused"}` : "Pomodoro"
    onClicked: mouse => mouse.button === Qt.MiddleButton ? Pomodoro.toggle() : Panels.toggle("pomodoro", screen.name)

    function status() {
        if (!Pomodoro.started)
            return `Ready · ${Pomodoro.minutesOf(Pomodoro.phase)} min`;
        if (!Pomodoro.running)
            return "Paused";
        const next = Pomodoro.isBreak ? "Focus resumes" : Pomodoro.nextPhase === "long" ? "Long break" : "Break";
        return `Running · ${next} at ${Qt.formatTime(Pomodoro.endsAt, "HH:mm")}`;
    }

    function duration(minutes) {
        const h = Math.floor(minutes / 60), m = minutes % 60;
        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    DropdownPanel {
        target: root
        screen: root.screen
        open: root.open
        glyph: root.glyph
        title: Pomodoro.names[Pomodoro.phase]
        status: root.status()
        badge: `${Pomodoro.session} / ${Pomodoro.sessions}`
        onDismissed: Panels.close()

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space.lg

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Pomodoro.clock(Pomodoro.remaining)
                size: Style.font.hero
                font.bold: true
                font.features: ({ tnum: 1 })
                color: root.textColor
                opacity: Pomodoro.running || !Pomodoro.started ? 1 : 0.6
            }

            // One square per block in the cycle: filled once done, outlined
            // in the accent while it's the one being worked on.
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Style.space.md

                Repeater {
                    model: Pomodoro.sessions

                    Rectangle {
                        required property int index
                        readonly property bool current: !Pomodoro.isBreak && index === Pomodoro.session - 1

                        width: Style.space.xxl
                        height: width
                        radius: Style.radius
                        color: index < Pomodoro.done ? root.textColor : "transparent"
                        border.width: Style.controls.normalBorderWidth ?? 1
                        border.color: current ? root.accent : Style.alpha(root.textColor, 0.5)
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: `Today ${Pomodoro.todayBlocks} ${Pomodoro.todayBlocks === 1 ? "block" : "blocks"} · ${root.duration(Pomodoro.todayMinutes)}`
                size: Style.font.caption
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                color: root.textColor
                opacity: 0.6
            }
        }

        // Phase progress
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space.xs
            color: Style.alpha(root.textColor, 0.2)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, Pomodoro.progress))
                height: parent.height
                color: root.accent
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Style.space.md

            ControlButton {
                glyph: Pomodoro.running ? "\u{F03E4}" : "\u{F040A}" // pause, play
                label: Pomodoro.running ? "Pause" : Pomodoro.started ? "Resume" : "Start"
                selected: Pomodoro.running
                onClicked: Pomodoro.toggle()
            }

            ControlButton {
                glyph: "\u{F099B}"
                label: "Reset"
                onClicked: Pomodoro.reset()
            }

            ControlButton {
                glyph: "\u{F04AD}"
                label: "Skip"
                onClicked: Pomodoro.skip()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Style.alpha(root.textColor, 0.15)
        }

        DropdownSection {
            title: "Ambient sound"
            count: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space.md

                Repeater {
                    model: Ambient.sounds

                    SoundButton {
                        required property var modelData

                        sound: modelData
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Style.space.sm
                spacing: Style.space.lg

                StyledText {
                    text: Ambient.volume === 0 ? "\u{F075F}" : "\u{F057E}" // volume off, high
                    size: Style.font.icon
                    color: root.textColor
                    opacity: 0.6
                }

                Slider {
                    Layout.fillWidth: true
                    value: Ambient.volume / 100
                    step: 0.05
                    dimmed: Ambient.sound === ""
                    onMoved: v => Ambient.setVolume(v * 100)
                }

                StyledText {
                    Layout.preferredWidth: Style.font.body * 2.5
                    horizontalAlignment: Text.AlignRight
                    text: `${Ambient.volume}%`
                    size: Style.font.bodySmall
                    color: root.textColor
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Style.alpha(root.textColor, 0.15)
        }

        DropdownRow {
            glyph: "\u{F0493}"
            label: "Settings"
            status: root.settingsOpen ? "\u{F0143}" : "\u{F0140}" // chevrons
            active: true
            onClicked: root.settingsOpen = !root.settingsOpen
        }

        ColumnLayout {
            visible: root.settingsOpen
            Layout.fillWidth: true
            spacing: Style.space.md

            RowLayout {
                Layout.fillWidth: true

                Caption {
                    Layout.fillWidth: true
                    text: "Durations"
                }

                Caption {
                    text: "Minutes"
                }
            }

            Stepper {
                label: "Focus"
                value: Pomodoro.focusMinutes
                step: 5
                onChanged: v => Pomodoro.setMinutes("focus", v)
            }

            Stepper {
                label: "Short break"
                value: Pomodoro.shortMinutes
                onChanged: v => Pomodoro.setMinutes("short", v)
            }

            Stepper {
                label: "Long break"
                value: Pomodoro.longMinutes
                step: 5
                onChanged: v => Pomodoro.setMinutes("long", v)
            }

            Stepper {
                label: "Sessions before long break"
                value: Pomodoro.sessions
                onChanged: v => Pomodoro.setSessions(v)
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: "Ambient sound during breaks"
                    color: root.textColor
                }

                Switch {
                    checked: Ambient.breaks
                    onToggled: Ambient.setBreaks(!Ambient.breaks)
                }
            }

            RowLayout {
                Layout.topMargin: Style.space.sm
                spacing: Style.space.md

                Repeater {
                    model: [[25, 5], [50, 10], [90, 20]]

                    ControlButton {
                        required property var modelData

                        label: `${modelData[0]} / ${modelData[1]}`
                        selected: Pomodoro.focusMinutes === modelData[0] && Pomodoro.shortMinutes === modelData[1]
                        onClicked: Pomodoro.preset(modelData[0], modelData[1])
                    }
                }
            }
        }
    }

    component Caption: StyledText {
        size: Style.font.caption
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
        color: root.textColor
        opacity: 0.6
    }

    // A bordered button with an optional glyph; `selected` fills it.
    component ControlButton: Rectangle {
        id: button

        property string glyph: ""
        property string label: ""
        property bool selected: false
        readonly property var c: Style.controls

        signal clicked

        implicitWidth: buttonRow.implicitWidth + Style.space.controlPaddingX * 2
        implicitHeight: Style.space.controlHeight
        radius: Style.radius
        color: Style.alpha(c.normalColor, selected ? c.selectedFillAlpha : area.containsMouse ? c.hoverCursorFillAlpha : c.normalFillAlpha)
        border.width: c.normalBorderWidth ?? 1
        border.color: Style.alpha(c.normalBorder, selected ? 1 : c.normalBorderAlpha)

        Row {
            id: buttonRow

            anchors.centerIn: parent
            spacing: Style.space.md

            StyledText {
                visible: button.glyph !== ""
                text: button.glyph
                size: Style.font.icon
                color: root.textColor
            }

            StyledText {
                text: button.label
                color: root.textColor
                font.bold: button.selected
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    // One ambient sound: glyph over its name, filled when picked.
    component SoundButton: Rectangle {
        id: tile

        required property var sound
        readonly property bool selected: Ambient.sound === sound.id
        readonly property var c: Style.controls

        Layout.fillWidth: true
        implicitHeight: tileColumn.implicitHeight + Style.space.controlPaddingY * 2
        radius: Style.radius
        color: Style.alpha(c.normalColor, selected ? c.selectedFillAlpha : tileArea.containsMouse ? c.hoverCursorFillAlpha : c.normalFillAlpha)
        border.width: c.normalBorderWidth ?? 1
        border.color: Style.alpha(c.normalBorder, selected ? 1 : c.normalBorderAlpha)

        ColumnLayout {
            id: tileColumn

            anchors.centerIn: parent
            spacing: Style.space.xxs

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: tile.sound.glyph
                size: Style.font.icon
                color: tile.selected && Ambient.playing ? root.accent : root.textColor
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: tile.sound.name
                size: Style.font.caption
                color: root.textColor
                font.bold: tile.selected
            }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Ambient.select(tile.sound.id)
        }
    }

    // A label with − value + on the right. Scrolling over it steps too.
    component Stepper: RowLayout {
        id: stepper

        required property string label
        required property int value
        property int step: 1

        signal changed(int value)

        Layout.fillWidth: true
        spacing: Style.space.md

        StyledText {
            Layout.fillWidth: true
            text: stepper.label
            color: root.textColor
        }

        ControlButton {
            implicitWidth: implicitHeight
            label: "\u{F0374}"
            onClicked: stepper.changed(stepper.value - stepper.step)
        }

        StyledText {
            Layout.preferredWidth: Style.font.body * 2.5
            horizontalAlignment: Text.AlignHCenter
            text: stepper.value
            color: root.textColor
            font.bold: true

            WheelHandler {
                onWheel: event => stepper.changed(stepper.value + (event.angleDelta.y > 0 ? stepper.step : -stepper.step))
            }
        }

        ControlButton {
            implicitWidth: implicitHeight
            label: "\u{F0415}"
            onClicked: stepper.changed(stepper.value + stepper.step)
        }
    }
}
