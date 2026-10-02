import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.components

// A tray app's menu, drawn with the [menu] theme tokens under its icon.
// Submenus expand in place. Click outside or Esc closes it.
PopupWindow {
    id: root

    required property var menu // QsMenuHandle of the tray item
    required property Item target
    readonly property var m: Style.menu

    signal dismissed

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: Style.space.sm
    implicitWidth: Style.space.dropdownWidth
    implicitHeight: entries.implicitHeight + Style.space.sm * 2
    color: "transparent"
    visible: true

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.dismissed()
    }

    Surface {
        anchors.fill: parent
        section: root.m
        focus: true
        Keys.onEscapePressed: root.dismissed()

        Column {
            id: entries

            anchors.fill: parent
            anchors.margins: Style.space.sm

            TrayMenuEntries {
                menu: root.menu
                popup: root
            }
        }
    }
}
