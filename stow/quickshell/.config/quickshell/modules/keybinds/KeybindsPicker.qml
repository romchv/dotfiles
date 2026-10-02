import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Keybind cheatsheet: SUPER+K (`qs ipc call keybinds toggle`). Type to
// filter by action or key; Enter or Esc closes.
Scope {
    IpcHandler {
        target: "keybinds"

        function toggle(): void {
            Panels.toggle("keybinds");
        }
        function open(): void {
            Panels.open("keybinds");
        }
        function close(): void {
            Panels.close();
        }
    }

    LazyLoader {
        active: Panels.current === "keybinds"

        Picker {
            cardWidth: Style.space.cheatsheetWidth
            placeholder: "Keybinds..."
            emptyText: "No matching keybinds"
            items: Keybinds.search(query)
            Component.onCompleted: Keybinds.refresh()

            onPicked: Panels.close()
            onDismissed: Panels.close()

            delegate: PickerRow {
                id: row

                RowLayout {
                    anchors.fill: parent
                    spacing: Style.space.lg

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.description
                        size: Style.font.body
                        color: row.textColor
                    }

                    StyledText {
                        text: row.modelData.keys
                        size: Style.font.caption
                        color: row.textColor
                        opacity: 0.6
                    }
                }
            }
        }
    }
}
