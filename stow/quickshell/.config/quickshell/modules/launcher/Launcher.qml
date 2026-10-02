import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// App launcher. Opened by SUPER+SPACE (`qs ipc call launcher toggle`) or
// the bar's apps icon. Keys are Picker's.
Scope {
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Panels.toggle("launcher");
        }
        function open(): void {
            Panels.open("launcher");
        }
        function close(): void {
            Panels.close();
        }
    }

    // The window only exists while open, so every open starts fresh.
    LazyLoader {
        active: Panels.current === "launcher"

        Picker {
            placeholder: "Search apps"
            emptyText: "No matching apps"
            items: Apps.search(query)

            onPicked: entry => {
                Apps.launch(entry);
                Panels.close();
            }
            onDismissed: Panels.close()

            delegate: PickerRow {
                id: row

                RowLayout {
                    anchors.fill: parent
                    spacing: Style.space.xxl

                    IconImage {
                        implicitSize: Style.font.display
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                        asynchronous: true
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
