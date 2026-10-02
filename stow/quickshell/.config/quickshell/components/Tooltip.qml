import QtQuick
import Quickshell
import qs.config

// Hover hint under an item. Set `target` to the item and bind `shown`
// (e.g. to a MouseArea's containsMouse); it appears after a short delay.
PopupWindow {
    id: root

    required property Item target
    property string text: ""
    property bool shown: false

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: Style.space.sm
    implicitWidth: label.implicitWidth + Style.space.controlPaddingX * 2
    implicitHeight: label.implicitHeight + Style.space.controlPaddingY * 2
    color: "transparent"
    visible: delay.ready && shown && text !== ""

    Timer {
        id: delay
        property bool ready: false
        interval: 400
        running: root.shown
        onRunningChanged: if (running) ready = false
        onTriggered: ready = true
    }

    Surface {
        anchors.fill: parent
        section: Style.tooltip

        StyledText {
            id: label
            anchors.centerIn: parent
            text: root.text
            size: Style.font.bodySmall
            color: Style.tooltip.text
        }
    }
}
