import QtQuick
import qs.config

// Cell delegate for a Picker grid (`cellSize` set): like PickerRow, with the
// content centered and `hint` shown in a bubble while hovered.
Item {
    id: cell

    required property int index
    required property var modelData
    property string hint: ""
    readonly property var picker: GridView.view.owner
    readonly property bool selected: index === picker.current
    readonly property color textColor: selected ? picker.section.selectedText : picker.section.text
    default property alias content: body.data

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        visible: cell.selected
        radius: Style.radius
        color: Style.alpha(cell.picker.section.selectedBackground, cell.picker.section.selectedBackgroundAlpha)
        border.width: 1
        border.color: Style.alpha(cell.picker.section.selectedBorder, cell.picker.section.selectedBorderAlpha)
    }

    Item {
        id: body
        anchors.fill: parent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse)
                cell.picker.hovered = cell;
            else if (cell.picker.hovered === cell)
                cell.picker.hovered = null;
        }
        // Same as PickerRow: only real pointer movement moves the selection.
        onPositionChanged: mouse => {
            const p = mapToItem(null, mouse.x, mouse.y);
            if (cell.picker.pointer && (p.x !== cell.picker.pointer.x || p.y !== cell.picker.pointer.y))
                cell.picker.current = cell.index;
            cell.picker.pointer = p;
        }
        onClicked: cell.picker.pick(cell.modelData)
    }

    Component.onDestruction: if (picker && picker.hovered === cell) picker.hovered = null
}
