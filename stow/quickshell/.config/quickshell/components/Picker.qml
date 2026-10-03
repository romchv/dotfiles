import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Overlay search-and-pick list on Panels.screen (launcher, clipboard).
// Type to filter; Up/Down, Ctrl+J/K or Ctrl+N/P, PageUp/PageDown to move;
// Enter picks; Esc or a click outside closes. Rows are PickerRow delegates.
// With `cellSize` set it's a grid of PickerCell delegates instead (emoji):
// Left/Right move too, and a cell's `hint` shows in a bubble on hover.
PanelWindow {
    id: picker

    property var items: []
    property string query: ""
    property string placeholder: "Search..."
    property int cardWidth: Style.space.launcherWidth
    property string emptyText: "No matches"
    property string hint: "" // small line under the list, e.g. extra keys
    property Component delegate
    property int cellSize: 0 // > 0: a grid of cells this size instead of rows
    readonly property bool grid: cellSize > 0
    readonly property int columns: grid ? Math.max(1, Math.floor(card.innerWidth / cellSize)) : 1
    // Rows in view, and the number of steps PageUp/PageDown jump.
    readonly property int page: Style.launcherRows * columns
    property Item hovered: null // the cell under the pointer, for the hint bubble
    property int current: 0
    property var pointer: null // last pointer position seen by the rows
    readonly property int rowHeight: Style.space.launcherRowHeight
    readonly property var section: Style.launcher

    signal picked(var item)
    signal dismissed
    // Every key before the picker handles it; set event.accepted to swallow it.
    signal keyPressed(var event)

    function move(delta) {
        current = Math.max(0, Math.min(items.length - 1, current + delta));
    }

    function pick(item) {
        if (item)
            picked(item);
    }

    onQueryChanged: current = 0
    onItemsChanged: current = Math.max(0, Math.min(current, items.length - 1))
    onCurrentChanged: grid ? cells.positionViewAtIndex(current, GridView.Contain) : list.positionViewAtIndex(current, ListView.Contain)

    screen: Panels.shellScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-picker"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: Style.alpha(section.scrim, section.scrimAlpha)

    // Click on the scrim closes.
    MouseArea {
        anchors.fill: parent
        onClicked: picker.dismissed()
    }

    Surface {
        id: card

        readonly property int pad: Style.space.popupPadding
        readonly property int innerWidth: width - pad * 2
        // Height with every row visible: the card's top stays put while filtering.
        readonly property int fullHeight: field.implicitHeight + column.spacing + Style.launcherRows * (picker.grid ? picker.cellSize : picker.rowHeight) + pad * 2

        section: picker.section
        width: Math.min(picker.cardWidth, parent.width - Style.space.huge * 2)
        height: column.implicitHeight + pad * 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Style.space.huge, (parent.height - fullHeight) / 2)

        // Swallow clicks so they don't reach the scrim.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: card.pad
            spacing: Style.space.md

            TextField {
                id: field

                Layout.fillWidth: true
                placeholder: picker.placeholder
                textColor: picker.section.text
                // Blends into the card: no fill, border or cursor.
                fillColor: "transparent"
                borderWidth: 0
                showCursor: false
                focus: true
                Component.onCompleted: input.forceActiveFocus()

                onTextChanged: picker.query = text
                onAccepted: picker.pick(picker.items[picker.current])
                onKeyPressed: event => {
                    picker.keyPressed(event);
                    if (event.accepted)
                        return;
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Escape)
                        picker.dismissed();
                    else if (picker.grid && event.key === Qt.Key_Right)
                        picker.move(1);
                    else if (picker.grid && event.key === Qt.Key_Left)
                        picker.move(-1);
                    else if (picker.grid && (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))))
                        picker.move(picker.columns);
                    else if (picker.grid && (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))))
                        picker.move(-picker.columns);
                    else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N)))
                        // Down on the last row wraps to the first.
                        picker.move(picker.current === picker.items.length - 1 ? -picker.current : 1);
                    else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P)))
                        // Up on the first row wraps to the last.
                        picker.move(picker.current === 0 ? picker.items.length - 1 : -1);
                    else if (event.key === Qt.Key_PageDown)
                        picker.move(picker.page);
                    else if (event.key === Qt.Key_PageUp)
                        picker.move(-picker.page);
                    else
                        return;
                    event.accepted = true;
                }
            }

            ListView {
                id: list

                readonly property var owner: picker // PickerRow reaches the picker through this

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(count, Style.launcherRows) * picker.rowHeight
                visible: !picker.grid && count > 0
                model: picker.grid ? [] : picker.items
                delegate: picker.grid ? null : picker.delegate
                currentIndex: picker.current
                clip: true
                boundsBehavior: Flickable.StopAtBounds
            }

            GridView {
                id: cells

                readonly property var owner: picker // PickerCell reaches the picker through this

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Math.ceil(count / picker.columns), Style.launcherRows) * picker.cellSize
                visible: picker.grid && count > 0
                model: picker.grid ? picker.items : []
                delegate: picker.grid ? picker.delegate : null
                cellWidth: width / picker.columns
                cellHeight: picker.cellSize
                currentIndex: picker.current
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                onContentYChanged: picker.hovered = null
            }

            StyledText {
                visible: (picker.grid ? cells.count : list.count) === 0
                Layout.fillWidth: true
                Layout.preferredHeight: picker.rowHeight
                horizontalAlignment: Text.AlignHCenter
                text: picker.emptyText
                color: picker.section.text
                opacity: 0.5
            }

            StyledText {
                visible: picker.hint !== ""
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: picker.hint
                size: Style.font.caption
                color: picker.section.text
                opacity: 0.5
            }
        }
    }

    // The hovered cell's hint, under it (or over it at the bottom of the
    // window), after the same short delay as Tooltip.
    Surface {
        id: bubble

        readonly property Item cell: picker.hovered
        readonly property point at: cell ? cell.mapToItem(null, cell.width / 2, 0) : Qt.point(0, 0)
        readonly property bool below: at.y + (cell?.height ?? 0) + height + Style.space.sm < picker.height

        visible: cell !== null && (cell?.hint ?? "") !== "" && delay.ready
        section: Style.tooltip
        width: hintLabel.implicitWidth + Style.space.controlPaddingX * 2
        height: hintLabel.implicitHeight + Style.space.controlPaddingY * 2
        x: Math.max(Style.space.sm, Math.min(picker.width - width - Style.space.sm, at.x - width / 2))
        y: below ? at.y + (cell?.height ?? 0) + Style.space.xs : at.y - height - Style.space.xs

        Timer {
            id: delay
            property bool ready: false
            interval: 400
            running: bubble.cell !== null
            onRunningChanged: if (running) ready = false
            onTriggered: ready = true
        }

        StyledText {
            id: hintLabel
            anchors.centerIn: parent
            text: bubble.cell?.hint ?? ""
            size: Style.font.subtitle
            color: Style.tooltip.text
        }
    }
}
