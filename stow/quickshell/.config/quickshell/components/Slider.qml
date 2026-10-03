import QtQuick
import qs.config

// Horizontal 0..1 slider: click or drag along it, or scroll over it. It
// doesn't move itself: handle `moved` and let `value` follow the real state.
Item {
    id: root

    property real value: 0
    property bool dimmed: false // e.g. muted: drawn faint, still usable
    property real step: 0.05
    readonly property bool pressed: area.pressed
    readonly property color textColor: Style.popups.text ?? Style.colors.foreground

    signal moved(real value)

    implicitWidth: 120
    implicitHeight: Style.space.popupRowHeight

    function _at(x) {
        root.moved(Math.max(0, Math.min(1, x / width)));
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Style.space.xs
        color: Style.alpha(root.textColor, 0.2)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            color: root.textColor
            opacity: root.dimmed ? 0.4 : 1
        }
    }

    Rectangle {
        readonly property int size: Style.space.lg + (area.containsMouse || area.pressed ? Style.space.xxs : 0)

        width: size
        height: size
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.width * root.value - width / 2))
        radius: Style.radius
        color: root.dimmed ? Style.alpha(root.textColor, 0.4) : (Style.colors.accent ?? root.textColor)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => root._at(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root._at(mouse.x);
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
    }
}
