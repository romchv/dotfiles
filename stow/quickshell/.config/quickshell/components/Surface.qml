import QtQuick
import qs.config

// A card painted from one theme section (Style.popups, Style.launcher,
// Style.polkit, ...): background + alpha, border + alpha, shared geometry.
Rectangle {
    property var section: Style.popups
    property color borderColor: section.border ?? "transparent"

    color: Style.alpha(section.background, section.backgroundAlpha)
    radius: Style.radius
    border.width: section.borderWidth ?? Style.borderWidth
    border.color: Style.alpha(borderColor, section.borderAlpha)

    Behavior on border.color {
        ColorAnimation { duration: Style.anim.normal }
    }
}
