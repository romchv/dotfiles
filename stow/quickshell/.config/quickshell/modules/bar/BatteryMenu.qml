import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.config
import qs.components
import qs.services

// Battery in the bar (laptops only): the glyph shows the charge, a click
// (or `qs ipc call battery toggle`, on the focused monitor) opens a dropdown
// with the charge, the battery's size, cycles, charge limit and state, and
// the power profile. Details the hardware doesn't report are left out, and
// the profiles need power-profiles-daemon.
BarButton {
    id: root

    required property ShellScreen screen
    readonly property bool open: Battery.available && Panels.current === "battery" && Hyprland.focusedMonitor?.name === screen.name
    readonly property color textColor: Style.popups.text ?? Style.colors.foreground

    visible: Battery.available
    text: Battery.icon
    size: Style.font.iconMedium - 1
    tooltip: open ? "" : `${Battery.percent}% · ${Battery.status}`
    label.color: Battery.low ? Style.bar.active : (Style.bar.text ?? Style.colors.foreground)
    onClicked: Panels.toggle("battery")
    onOpenChanged: if (open) Battery.refresh()

    DropdownPanel {
        target: root
        screen: root.screen
        open: root.open
        glyph: Battery.icon
        title: "Battery"
        status: Battery.status
        headline: `${Battery.percent}%`
        onDismissed: Panels.close()

        // Charge
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space.sm
            color: Style.alpha(root.textColor, 0.2)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, Battery.level))
                height: parent.height
                color: Battery.low ? Style.bar.active : root.textColor

                Behavior on width {
                    NumberAnimation { duration: Style.anim.normal }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: Style.space.xl
            rowSpacing: Style.space.xs

            Stat {
                name: "Capacity"
                value: Battery.capacity > 0 ? `${Math.round(Battery.capacity)}Wh` : ""
            }
            StatValue {
                value: Battery.capacity > 0 ? `${Math.round(Battery.capacity)}Wh` : ""
            }

            Stat {
                name: "Charge limit"
                value: Battery.limit
            }
            StatValue {
                value: Battery.limit
            }

            Stat {
                name: "Charge cycles"
                value: Battery.cycles > 0 ? `${Battery.cycles}` : ""
            }
            StatValue {
                value: Battery.cycles > 0 ? `${Battery.cycles}` : ""
            }

            Stat {
                name: "State"
                value: Battery.stateLabel
            }
            StatValue {
                value: Battery.stateLabel
            }

            Stat {
                name: "Health"
                value: Battery.health >= 0 ? `${Battery.health}%` : ""
            }
            StatValue {
                value: Battery.health >= 0 ? `${Battery.health}%` : ""
            }
        }

        DropdownSection {
            visible: Battery.profilesAvailable
            title: "Power profile"
            count: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space.md

                ProfileButton {
                    profile: PowerProfile.PowerSaver
                    glyph: "󰌪"
                    name: "Power saver"
                }

                ProfileButton {
                    profile: PowerProfile.Balanced
                    glyph: "󰾅"
                    name: "Balanced"
                }

                ProfileButton {
                    profile: PowerProfile.Performance
                    glyph: "󰓅"
                    name: "Performance"
                    enabled: Battery.hasPerformance
                }
            }
        }
    }

    // A detail's name, then its value in the next cell; both hide when the
    // hardware doesn't report it, and the grid closes the gap.
    component Stat: StyledText {
        required property string name
        property string value: ""

        visible: value !== ""
        text: name
        size: Style.font.bodySmall
        color: root.textColor
        opacity: 0.6
    }

    component StatValue: StyledText {
        property string value: ""

        visible: value !== ""
        Layout.fillWidth: true
        text: value
        size: Style.font.bodySmall
        color: root.textColor
        horizontalAlignment: Text.AlignRight
    }

    component ProfileButton: Rectangle {
        id: button

        required property int profile
        required property string glyph
        required property string name
        readonly property bool selected: Battery.profile === profile
        readonly property var c: Style.controls

        Layout.fillWidth: true
        implicitHeight: column.implicitHeight + Style.space.controlPaddingY * 2
        opacity: enabled ? 1 : 0.4
        radius: Style.radius
        color: Style.alpha(c.normalColor, selected ? c.selectedFillAlpha : area.containsMouse ? c.hoverCursorFillAlpha : c.normalFillAlpha)
        border.width: c.normalBorderWidth ?? 1
        border.color: Style.alpha(c.normalBorder, selected ? 1 : c.normalBorderAlpha)

        ColumnLayout {
            id: column

            anchors.centerIn: parent
            spacing: Style.space.xxs

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: button.glyph
                size: Style.font.icon
                color: root.textColor
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: button.name
                size: Style.font.caption
                color: root.textColor
                font.bold: button.selected
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Battery.setProfile(button.profile)
        }
    }
}
