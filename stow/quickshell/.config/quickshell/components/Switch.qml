import QtQuick
import qs.config

// On/off switch styled with the [controls] tokens. It doesn't flip itself:
// handle `toggled` and let `checked` follow the real state.
Item {
    id: root

    property bool checked: false
    signal toggled

    implicitWidth: Style.space.controlHeight * 1.4
    implicitHeight: Style.space.controlHeight * 0.75

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: Style.alpha(Style.controls.normalColor, root.checked ? Style.controls.selectedFillAlpha : Style.controls.normalFillAlpha)
        border.width: Style.controls.normalBorderWidth ?? 1
        border.color: Style.alpha(Style.controls.normalBorder, Style.controls.normalBorderAlpha)

        Rectangle {
            width: parent.height - Style.space.xs * 2
            height: width
            y: Style.space.xs
            x: root.checked ? parent.width - width - Style.space.xs : Style.space.xs
            radius: Style.radius
            color: root.checked ? (Style.colors.accent ?? Style.colors.foreground) : Style.alpha(Style.colors.foreground, 0.4)

            Behavior on x {
                NumberAnimation { duration: Style.anim.normal; easing.type: Style.anim.easing }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
