import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Power menu: SUPER+ESCAPE (`qs ipc call power toggle`). Type to filter
// lock / suspend / hibernate / log out / reboot / shut down; Enter runs it.
Scope {
    IpcHandler {
        target: "power"

        function toggle(): void {
            Panels.toggle("power");
        }
        function open(): void {
            Panels.open("power");
        }
        function close(): void {
            Panels.close();
        }
    }

    LazyLoader {
        active: Panels.current === "power"

        Picker {
            placeholder: "Power options..."
            emptyText: "No matching options"
            items: Power.search(query)

            onPicked: action => {
                Panels.close();
                Power.run(action);
            }
            onDismissed: Panels.close()

            delegate: PickerRow {
                id: row

                RowLayout {
                    anchors.fill: parent
                    spacing: Style.space.lg

                    StyledText {
                        Layout.preferredWidth: Style.font.display
                        horizontalAlignment: Text.AlignHCenter
                        text: row.modelData.icon
                        size: Style.font.icon
                        color: row.textColor
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        size: Style.font.subtitle
                        color: row.textColor
                    }
                }
            }
        }
    }
}
