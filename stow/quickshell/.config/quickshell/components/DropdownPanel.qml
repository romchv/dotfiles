import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config

// A card under a bar glyph (Bluetooth, Wi-Fi): header with a glyph, title,
// status line and power switch, then a scrolling body of DropdownSections.
// A full-screen, see-through layer rather than a bar popup: a popup never
// gets the keyboard, so Esc couldn't reach it. Like Picker, it takes the
// keyboard while open and a click anywhere outside the card closes it.
PanelWindow {
    id: root

    required property Item target // the bar glyph it hangs under
    property bool open: false
    property string glyph: ""
    property string title: ""
    property string status: ""
    property bool checked: false
    property bool bodyVisible: true
    default property alias body: lists.data
    readonly property color textColor: Style.popups.text ?? Style.colors.foreground
    // Centered on the glyph and kept on screen; read again on each open.
    readonly property real targetCenter: open ? target.mapToItem(null, target.width / 2, 0).x : 0

    signal toggled
    signal dismissed

    // Back to the card after an input inside it lets go, so Esc still closes.
    function refocus() {
        card.forceActiveFocus();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-dropdown"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    visible: open
    onVisibleChanged: if (visible) card.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Surface {
        id: card

        width: Style.space.deviceMenuWidth
        height: content.implicitHeight + Style.space.popupPadding * 2
        x: Math.max(Style.space.sm, Math.min(root.width - width - Style.space.sm, root.targetCenter - width / 2))
        y: Style.barHeight + Style.space.sm
        section: Style.popups
        focus: true
        Keys.onEscapePressed: root.dismissed()

        // Swallow clicks so they don't reach the close-on-click layer.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: Style.space.popupPadding
            spacing: Style.space.lg

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space.xl

                StyledText {
                    text: root.glyph
                    size: Style.font.iconLarge
                    color: root.textColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: root.title
                        size: Style.font.title
                        font.bold: true
                        color: root.textColor
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.status
                        size: Style.font.caption
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                        color: root.textColor
                        opacity: 0.6
                    }
                }

                Switch {
                    checked: root.checked
                    onToggled: root.toggled()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.alpha(root.textColor, 0.15)
            }

            Flickable {
                Layout.fillWidth: true
                implicitHeight: Math.min(lists.implicitHeight, Style.space.popupRowHeight * 12)
                contentHeight: lists.implicitHeight
                clip: true
                visible: root.bodyVisible
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: lists

                    width: parent.width
                    spacing: Style.space.panelGap
                }
            }
        }
    }
}
