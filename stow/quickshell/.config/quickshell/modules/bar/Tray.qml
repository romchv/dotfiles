import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.components

// System tray (StatusNotifierItem): icons of background apps like Steam or
// NordVPN, folded behind a chevron; hovering the tray reveals them, and they
// fold back shortly after the pointer leaves (not while a menu is open). Left-click activates
// (or opens the menu of menu-only items), right-click opens the app's menu
// (TrayMenu), middle-click and scroll go to the app. Items marked passive
// (idle) are hidden.
Row {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    // Open while hovered, a moment after (to reach the icons), and while a menu is open.
    readonly property bool expanded: hover.hovered || linger.running || menuItem !== null
    property var menuItem: null // tray item whose menu is open
    property Item menuAnchor: null

    visible: items.length > 0

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered) linger.restart()
    }

    Timer {
        id: linger
        interval: 500
    }

    Item {
        id: drawer

        height: parent.height
        width: root.expanded ? icons.implicitWidth : 0
        clip: true

        Behavior on width {
            NumberAnimation { duration: Style.anim.normal; easing.type: Style.anim.easing }
        }

        Row {
            id: icons

            anchors.right: parent.right
            height: parent.height

            Repeater {
                model: root.items

                Item {
                    id: entry

                    required property SystemTrayItem modelData
                    readonly property SystemTrayItem item: modelData

                    // Some apps (Steam among them) send "name?path=dir" instead of an icon name.
                    readonly property string icon: {
                        const i = item.icon;
                        if (!i.includes("?path="))
                            return i;
                        const [name, dir] = i.split("?path=");
                        return `file://${dir}/${name.slice(name.lastIndexOf("/") + 1)}`;
                    }

                    function openMenu() {
                        root.menuAnchor = entry;
                        root.menuItem = root.menuItem === item ? null : item;
                    }

                    implicitWidth: Style.font.icon + Style.space.lg * 2
                    implicitHeight: parent.height

                    Rectangle {
                        anchors.fill: parent
                        color: Style.controls.hoverCursorColor ?? "transparent"
                        opacity: area.containsMouse || root.menuItem === entry.item ? (Style.controls.hoverCursorFillAlpha ?? 0.08) : 0
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Style.font.icon
                        source: entry.icon
                        asynchronous: true
                    }

                    Tooltip {
                        target: entry
                        text: entry.item.tooltipTitle || entry.item.title || entry.item.id
                        shown: area.containsMouse && root.menuItem === null
                    }

                    MouseArea {
                        id: area

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton)
                                entry.item.secondaryActivate();
                            else if (mouse.button === Qt.RightButton || entry.item.onlyMenu)
                                entry.item.hasMenu ? entry.openMenu() : entry.item.activate();
                            else
                                entry.item.activate();
                        }
                        onWheel: wheel => entry.item.scroll(wheel.angleDelta.y || wheel.angleDelta.x, wheel.angleDelta.y === 0)
                    }
                }
            }
        }
    }

    BarButton {
        text: root.expanded ? "\uf054" : "\uf053" // chevron right / left
        size: Style.font.bodySmall
        padding: Style.space.md
        label.opacity: 0.7
    }

    LazyLoader {
        active: root.menuItem !== null && root.menuItem.hasMenu

        TrayMenu {
            menu: root.menuItem?.menu ?? null
            target: root.menuAnchor
            onDismissed: root.menuItem = null
        }
    }
}
