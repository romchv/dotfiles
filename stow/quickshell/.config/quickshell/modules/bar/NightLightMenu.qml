import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Night light in the bar, shown while it's on. A click opens a dropdown
// with the on/off switch and a temperature slider (warmer to the left);
// scroll over the glyph to change the temperature. The light itself is
// toggled by SUPER+CTRL+N (`qs ipc call nightlight toggle`).
BarButton {
    id: root

    required property ShellScreen screen
    readonly property bool open: Panels.current === "nightlight" && Panels.screen === screen.name
    readonly property real fraction: (NightLight.temperature - NightLight.minTemperature) / (NightLight.maxTemperature - NightLight.minTemperature)

    visible: NightLight.enabled
    text: "\u{F0594}"
    tooltip: open ? "" : `Night light · ${NightLight.temperature}K`
    onClicked: Panels.toggle("nightlight", screen.name)
    onScrolled: wheel => NightLight.setTemperature(NightLight.temperature + (wheel.angleDelta.y > 0 ? 100 : -100))

    DropdownPanel {
        target: root
        screen: root.screen
        open: root.open
        glyph: "\u{F0594}"
        title: "Night light"
        status: NightLight.enabled ? `${NightLight.temperature}K` : "Off"
        checked: NightLight.enabled
        onToggled: NightLight.toggle()
        onDismissed: Panels.close()

        DropdownSection {
            title: "Temperature"
            count: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space.lg

                Slider {
                    Layout.fillWidth: true
                    value: root.fraction
                    step: 100 / (NightLight.maxTemperature - NightLight.minTemperature)
                    dimmed: !NightLight.enabled
                    onMoved: v => NightLight.setTemperature(NightLight.minTemperature + v * (NightLight.maxTemperature - NightLight.minTemperature))
                }

                StyledText {
                    text: `${NightLight.temperature}K`
                    size: Style.font.bodySmall
                    color: Style.popups.text ?? Style.colors.foreground
                    Layout.minimumWidth: implicitWidth
                }
            }
        }
    }
}
