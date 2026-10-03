import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Wallpapers of the current theme, side by side. Opened by a double click on
// the desktop or `qs ipc call wallpapers toggle`. Left/Right (or H/L, Tab)
// to move, Enter or a click applies, Esc or a click outside closes.
// The list comes from shell.json, written by theme-switch.
Scope {
    IpcHandler {
        target: "wallpapers"

        function toggle(): void {
            Panels.toggle("wallpapers");
        }
        function open(): void {
            Panels.open("wallpapers");
        }
        function close(): void {
            Panels.close();
        }
    }

    LazyLoader {
        active: Panels.current === "wallpapers"

        PanelWindow {
            id: picker

            readonly property var section: Style.launcher
            readonly property var paths: Style.theme.wallpapers ?? []
            readonly property string active: Wallpaper.forScreen(screen?.name ?? "").replace(/^file:\/\//, "")
            readonly property int thumbWidth: Math.round(260 * Style.spaceScale)
            property int current: Math.max(0, paths.indexOf(active))

            function move(delta) {
                if (paths.length)
                    current = (current + delta + paths.length) % paths.length;
            }

            function pick(path) {
                Panels.close();
                if (path && path !== active)
                    Quickshell.execDetached(["theme-switch", "--wallpaper", path]);
            }

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
                onClicked: Panels.close()
            }

            Surface {
                id: card

                readonly property int pad: Style.space.popupPadding

                section: picker.section
                width: Math.min(column.implicitWidth + pad * 2, parent.width - Style.space.huge * 2)
                height: column.implicitHeight + pad * 2
                anchors.centerIn: parent

                // Swallow clicks so they don't reach the scrim.
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: column

                    anchors.fill: parent
                    anchors.margins: card.pad
                    spacing: Style.space.md
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: event => {
                        const k = event.key;
                        if (k === Qt.Key_Escape)
                            Panels.close();
                        else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                            picker.pick(picker.paths[picker.current]);
                        else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_Tab)
                            picker.move(1);
                        else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_Backtab)
                            picker.move(-1);
                        else
                            return;
                        event.accepted = true;
                    }

                    StyledText {
                        text: Style.theme.name ?? "Wallpapers"
                        size: Style.font.subtitle
                        color: picker.section.text
                    }

                    RowLayout {
                        spacing: Style.space.lg

                        Repeater {
                            model: picker.paths

                            Item {
                                id: thumb

                                required property int index
                                required property string modelData
                                readonly property bool selected: index === picker.current

                                implicitWidth: picker.thumbWidth
                                implicitHeight: Math.round(picker.thumbWidth * 9 / 16)

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: Style.borderWidth * 2
                                    source: "file://" + thumb.modelData
                                    sourceSize.width: picker.thumbWidth * 2
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Style.radius
                                    color: "transparent"
                                    border.width: Style.borderWidth
                                    border.color: thumb.selected
                                        ? Style.alpha(picker.section.selectedBorder, picker.section.selectedBorderAlpha ?? 1)
                                        : "transparent"
                                }

                                // Marks the wallpaper on screen now.
                                StyledText {
                                    visible: thumb.modelData === picker.active
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: Style.space.lg
                                    text: "󰄬"
                                    size: Style.font.subtitle
                                    color: picker.section.selectedText
                                    style: Text.Outline
                                    styleColor: Style.alpha(picker.section.background, 0.8)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: picker.current = thumb.index
                                    onClicked: picker.pick(thumb.modelData)
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: picker.paths.length === 0
                        text: "This theme has no wallpapers"
                        color: picker.section.text
                        opacity: 0.5
                    }
                }
            }
        }
    }
}
