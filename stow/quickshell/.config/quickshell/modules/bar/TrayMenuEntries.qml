import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

// The entries of one tray menu level (TrayMenu); an entry with children
// expands its submenu below itself, indented.
Column {
    id: level

    property var menu
    property int depth: 0
    property var popup // the TrayMenu, to close it after a pick
    readonly property var m: Style.menu

    width: parent?.width ?? 0

    QsMenuOpener {
        id: opener
        menu: level.menu
    }

    Repeater {
        model: opener.children.values

        Column {
            id: entryColumn

            required property var modelData
            readonly property var entry: modelData
            property bool expanded: false

            width: level.width

            Rectangle {
                visible: entryColumn.entry.isSeparator
                width: parent.width
                height: Style.space.md * 2 + 1
                color: "transparent"

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Style.space.rowPaddingX
                    width: parent.width - Style.space.rowPaddingX * 2
                    height: 1
                    color: Style.alpha(level.m.text, 0.15)
                }
            }

            Item {
                visible: !entryColumn.entry.isSeparator
                width: parent.width
                height: Style.space.popupRowHeight
                opacity: entryColumn.entry.enabled ? 1 : 0.4

                Rectangle {
                    anchors.fill: parent
                    visible: rowArea.containsMouse && entryColumn.entry.enabled
                    radius: Style.radius
                    color: Style.alpha(level.m.selectedBackground, level.m.selectedBackgroundAlpha)
                    border.width: 1
                    border.color: Style.alpha(level.m.selectedBorder, level.m.selectedBorderAlpha)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space.rowPaddingX + level.depth * Style.space.xl
                    anchors.rightMargin: Style.space.rowPaddingX
                    spacing: Style.space.lg

                    // Checkbox / radio state.
                    StyledText {
                        visible: entryColumn.entry.buttonType !== QsMenuButtonType.None
                        text: {
                            const on = entryColumn.entry.checkState === Qt.Checked;
                            if (entryColumn.entry.buttonType === QsMenuButtonType.RadioButton)
                                return on ? "󰐾" : "󰄯";
                            return on ? "󰄵" : "󰄱";
                        }
                        size: Style.font.icon
                        color: level.m.text
                    }

                    IconImage {
                        visible: entryColumn.entry.icon !== ""
                        implicitSize: Style.font.icon
                        source: entryColumn.entry.icon
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: entryColumn.entry.text.replace(/_(?!_)/g, "") // drop mnemonic underscores
                        size: Style.font.body
                        color: rowArea.containsMouse ? level.m.selectedText : level.m.text
                    }

                    StyledText {
                        visible: entryColumn.entry.hasChildren
                        text: entryColumn.expanded ? "󰅀" : "󰅂"
                        size: Style.font.icon
                        color: level.m.text
                        opacity: 0.6
                    }
                }

                MouseArea {
                    id: rowArea

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: entryColumn.entry.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (entryColumn.entry.hasChildren) {
                            entryColumn.expanded = !entryColumn.expanded;
                        } else {
                            entryColumn.entry.triggered();
                            level.popup.dismissed();
                        }
                    }
                }
            }

            // Loaded by URL: a file can't contain itself directly.
            Loader {
                active: entryColumn.expanded
                width: parent.width
                source: "TrayMenuEntries.qml"
                onLoaded: {
                    item.menu = entryColumn.entry;
                    item.depth = level.depth + 1;
                    item.popup = level.popup;
                }
            }
        }
    }
}
