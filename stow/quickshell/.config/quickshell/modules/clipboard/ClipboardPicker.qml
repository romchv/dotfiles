import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Clipboard history picker: SUPER+CTRL+V (`qs ipc call clipboard toggle`).
// Enter pastes the entry into the window you were in; Shift+Del deletes it.
Scope {
    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            Panels.toggle("clipboard");
        }
        function open(): void {
            Panels.open("clipboard");
        }
        function close(): void {
            Panels.close();
        }
    }

    LazyLoader {
        active: Panels.current === "clipboard"

        Picker {
            id: picker

            icon: "󰅍"
            placeholder: "Search clipboard"
            emptyText: Clipboard.entries.length ? "No matches" : "Clipboard history is empty"
            hint: "Enter paste · Shift+Del delete"
            items: Clipboard.search(query)
            Component.onCompleted: Clipboard.refresh()

            onPicked: entry => {
                Panels.close();
                Clipboard.paste(entry);
            }
            onDismissed: Panels.close()
            onKeyPressed: event => {
                if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                    const entry = items[current];
                    if (entry)
                        Clipboard.remove(entry);
                    event.accepted = true;
                }
            }

            delegate: PickerRow {
                id: row

                RowLayout {
                    anchors.fill: parent
                    spacing: Style.space.lg

                    StyledText {
                        visible: row.modelData.isImage
                        text: "󰋩"
                        size: Style.font.icon
                        color: row.textColor
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.label
                        size: Style.font.body
                        color: row.textColor
                        opacity: row.modelData.isImage ? 0.7 : 1
                    }
                }
            }
        }
    }
}
