import QtQuick
import qs.config
import qs.components

// A clickable glyph or label in the bar, full bar height, with a hover wash.
Item {
    id: root

    property alias text: label.text
    property alias label: label
    property int size: Style.font.icon
    property int padding: Style.space.lg
    property string tooltip: ""
    property alias suffix: suffix.text // optional text after the glyph, at body size

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitWidth: content.implicitWidth + padding * 2
    implicitHeight: parent?.height ?? Style.barHeight

    Rectangle {
        anchors.fill: parent
        color: Style.controls.hoverCursorColor ?? "transparent"
        opacity: area.containsMouse ? (Style.controls.hoverCursorFillAlpha ?? 0.08) : 0

        Behavior on opacity {
            NumberAnimation { duration: Style.anim.fast }
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        height: parent.height
        spacing: Style.space.sm

        StyledText {
            id: label
            height: parent.height
            size: root.size
            color: Style.bar.text ?? Style.colors.foreground
        }

        StyledText {
            id: suffix
            visible: text !== ""
            height: parent.height
            color: label.color
        }
    }

    Tooltip {
        target: root
        text: root.tooltip
        shown: area.containsMouse
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }
}
