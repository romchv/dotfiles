import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

// Overlay search-and-pick list on the focused monitor (launcher, clipboard).
// Type to filter; Up/Down, Ctrl+J/K or Ctrl+N/P, PageUp/PageDown to move;
// Enter picks; Esc or a click outside closes. Rows are PickerRow delegates.
PanelWindow {
    id: picker

    property var items: []
    property string query: ""
    property string placeholder: "Search"
    property string icon: "󰍉"
    property string emptyText: "No matches"
    property string hint: "" // small line under the list, e.g. extra keys
    property alias delegate: list.delegate
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
    onCurrentChanged: list.positionViewAtIndex(current, ListView.Contain)

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
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
        // Height with every row visible: the card's top stays put while filtering.
        readonly property int fullHeight: field.implicitHeight + column.spacing + Style.launcherRows * picker.rowHeight + pad * 2

        section: picker.section
        width: Math.min(Style.space.launcherWidth, parent.width - Style.space.huge * 2)
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
                icon: picker.icon
                placeholder: picker.placeholder
                textColor: picker.section.text
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
                    else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N)))
                        picker.move(1);
                    else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P)))
                        picker.move(-1);
                    else if (event.key === Qt.Key_PageDown)
                        picker.move(Style.launcherRows);
                    else if (event.key === Qt.Key_PageUp)
                        picker.move(-Style.launcherRows);
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
                visible: count > 0
                model: picker.items
                currentIndex: picker.current
                clip: true
                boundsBehavior: Flickable.StopAtBounds
            }

            StyledText {
                visible: list.count === 0
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
}
