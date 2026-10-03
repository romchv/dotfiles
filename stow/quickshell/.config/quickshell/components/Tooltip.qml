import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// Hover hint under an item. Set `target` to the item and bind `shown`
// (e.g. to a MouseArea's containsMouse); it appears after a short delay.
// `pinned` shows it at once and keeps it up until Esc or a click outside,
// which emit `dismissed`.
PopupWindow {
    id: root

    required property Item target
    property string text: ""
    property bool shown: false
    property bool pinned: false

    signal dismissed

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: Style.space.sm
    implicitWidth: label.implicitWidth + Style.space.controlPaddingX * 2
    implicitHeight: label.implicitHeight + Style.space.controlPaddingY * 2
    color: "transparent"
    visible: (pinned || delay.ready && shown) && text !== ""

    Timer {
        id: delay
        property bool ready: false
        interval: 400
        running: root.shown
        onRunningChanged: if (running) ready = false
        onTriggered: ready = true
    }

    HyprlandFocusGrab {
        active: root.pinned && root.visible
        windows: [root]
        onCleared: root.dismissed()
    }

    Surface {
        anchors.fill: parent
        section: Style.tooltip
        focus: root.pinned
        Keys.onEscapePressed: root.dismissed()

        StyledText {
            id: label
            anchors.centerIn: parent
            text: root.text
            size: Style.font.subtitle
            color: Style.tooltip.text
        }
    }
}
