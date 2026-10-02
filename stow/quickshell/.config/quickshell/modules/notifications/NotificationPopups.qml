import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

// Notification popups, stacked at the top right of the focused monitor
// under the bar, newest on top. Keys (Hyprland binds, `qs ipc call
// notifications ...`): SUPER+, dismiss newest, SUPER+SHIFT+, dismiss all,
// SUPER+CTRL+, toggle Do Not Disturb.
Scope {
    IpcHandler {
        target: "notifications"

        function dismiss(): void {
            Notifications.dismissLatest();
        }
        function dismissAll(): void {
            Notifications.dismissAll();
        }
        function toggleDnd(): void {
            Notifications.dnd = !Notifications.dnd;
        }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: Notifications.popups.length > 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: Style.space.lg
            right: Style.space.lg
        }
        exclusionMode: ExclusionMode.Normal // stays below the bar
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"
        color: "transparent"
        implicitWidth: Style.space.notificationWidth
        implicitHeight: stack.implicitHeight

        Column {
            id: stack

            width: parent.width
            spacing: Style.space.lg

            Repeater {
                model: Notifications.popups.slice(0, Style.notificationMax)

                NotificationCard {
                    required property var modelData
                    notification: modelData
                    width: stack.width
                }
            }

            add: Transition {
                NumberAnimation { property: "x"; from: Style.space.notificationWidth; duration: Style.anim.normal; easing.type: Style.anim.easing }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.anim.normal }
            }
            move: Transition {
                NumberAnimation { property: "y"; duration: Style.anim.normal; easing.type: Style.anim.easing }
            }
        }
    }
}
