import QtQuick
import qs.config
import qs.components

// Calculator keypad button, painted with the [controls] tokens: normal,
// hover and pressed. `accent` fills it like a selected control (the = key);
// `dark` sinks it into the darker background (the number pad).
Rectangle {
    id: key

    property string label: ""
    property bool accent: false
    property bool dark: false
    property color textColor: Style.launcher.text ?? "white"
    readonly property var c: Style.controls

    signal clicked

    // Rounded, unlike the rest of the shell (Style.radius is 0): keys read as keys.
    radius: Style.space.lg
    opacity: enabled ? 1 : 0.3
    color: dark && !mouse.pressed && !mouse.containsMouse
        ? (Style.colors.darkBackground ?? "black")
        : Style.alpha(c.normalColor, mouse.pressed ? c.pressedFillAlpha
                                     : mouse.containsMouse ? c.hoverCursorFillAlpha
                                     : accent ? c.selectedFillAlpha : c.normalFillAlpha)
    // Outlined number pad, flat operators; any key outlines on hover.
    border.width: dark || mouse.containsMouse ? (c.normalBorderWidth ?? 1) : 0
    border.color: Style.alpha(c.normalBorder, mouse.containsMouse ? c.normalBorderAlpha : c.hoverCursorBorderAlpha)

    Behavior on color {
        ColorAnimation { duration: Style.anim.fast }
    }

    StyledText {
        anchors.centerIn: parent
        text: key.label
        size: Style.font.heading
        color: key.textColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: key.clicked()
    }
}
