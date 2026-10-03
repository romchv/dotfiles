import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Emoji picker: SUPER+CTRL+E (`qs ipc call emoji toggle`). Search by name
// or keyword; arrows move around the grid, hover an emoji for its name.
// Enter pastes it into the window you were in, Shift+Enter only copies it.
// The last ones picked come first.
Scope {
    IpcHandler {
        target: "emoji"

        function toggle(): void {
            Panels.toggle("emoji");
        }
        function open(): void {
            Panels.open("emoji");
        }
        function close(): void {
            Panels.close();
        }
    }

    LazyLoader {
        active: Panels.current === "emoji"

        Picker {
            id: picker

            property bool copyOnly: false

            cellSize: Style.space.launcherRowHeight
            cardWidth: cellSize * 9 + Style.space.popupPadding * 2
            placeholder: "Emoji..."
            emptyText: "No matching emoji"
            hint: "Enter paste · Shift+Enter copy"
            items: Emoji.search(query)

            onPicked: entry => {
                Panels.close();
                Emoji.used(entry.char);
                if (copyOnly)
                    Clipboard.copyText(entry.char);
                else
                    Clipboard.pasteText(entry.char);
            }
            onDismissed: Panels.close()
            onKeyPressed: event => {
                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier)) {
                    copyOnly = true;
                    pick(items[current]);
                    event.accepted = true;
                }
            }

            delegate: PickerCell {
                id: cell

                hint: modelData.name

                StyledText {
                    anchors.centerIn: parent
                    text: cell.modelData.char
                    size: Style.font.display
                    font.family: "Noto Color Emoji"
                }
            }
        }
    }
}
