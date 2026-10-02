import QtQuick
import qs.config

// Row delegate for Picker: selection highlight, hover-to-select and
// click-to-pick. The row's content goes inside, between the side paddings.
Item {
    id: row

    required property int index
    required property var modelData
    readonly property var picker: ListView.view.owner
    readonly property bool selected: index === picker.current
    readonly property color textColor: selected ? picker.section.selectedText : picker.section.text
    default property alias content: body.data

    width: ListView.view.width
    height: picker.rowHeight

    Rectangle {
        anchors.fill: parent
        visible: row.selected
        radius: Style.radius
        color: Style.alpha(row.picker.section.selectedBackground, row.picker.section.selectedBackgroundAlpha)
        border.width: 1
        border.color: Style.alpha(row.picker.section.selectedBorder, row.picker.section.selectedBorderAlpha)
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.leftMargin: Style.space.rowPaddingX
        anchors.rightMargin: Style.space.rowPaddingX
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        // Follow real pointer movement only: opening under a resting
        // cursor sends a position too, which must not move the selection.
        onPositionChanged: mouse => {
            const p = mapToItem(null, mouse.x, mouse.y);
            if (row.picker.pointer && (p.x !== row.picker.pointer.x || p.y !== row.picker.pointer.y))
                row.picker.current = row.index;
            row.picker.pointer = p;
        }
        onClicked: row.picker.pick(row.modelData)
    }
}
