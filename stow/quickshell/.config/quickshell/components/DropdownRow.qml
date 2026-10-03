import QtQuick
import QtQuick.Layouts
import qs.config

// One device or network in a DropdownSection: glyph, name (bold when
// `active`), a short status and, when `forgettable`, a trash glyph on hover.
Item {
    id: root

    property string glyph: ""
    property string label: ""
    property string status: ""
    property bool active: false
    property bool busy: false
    property bool forgettable: false
    readonly property color textColor: Style.popups.text ?? Style.colors.foreground

    signal clicked
    signal forget

    Layout.fillWidth: true
    implicitHeight: Style.space.launcherRowHeight

    Rectangle {
        anchors.fill: parent
        color: Style.controls.hoverCursorColor ?? "transparent"
        opacity: area.containsMouse ? (Style.controls.hoverCursorFillAlpha ?? 0.08) : 0
        border.width: Style.controls.hoverCursorBorderWidth ?? 0
        border.color: Style.alpha(Style.controls.hoverCursorBorder, Style.controls.hoverCursorBorderAlpha)

        Behavior on opacity {
            NumberAnimation { duration: Style.anim.fast }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.busy ? Qt.BusyCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.space.rowPaddingX
        anchors.rightMargin: Style.space.rowPaddingX
        spacing: Style.space.xl

        StyledText {
            Layout.preferredWidth: Style.font.icon * 1.4
            text: root.glyph
            size: Style.font.icon
            color: root.textColor
            opacity: root.active ? 1 : 0.6
            horizontalAlignment: Text.AlignHCenter
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
            color: root.textColor
            font.bold: root.active
        }

        StyledText {
            visible: text !== ""
            text: root.status
            size: Style.font.caption
            color: root.textColor
            opacity: 0.6
        }

        // Forget: only on hover, so a stray click can't remove it.
        StyledText {
            visible: root.forgettable && area.containsMouse || forget.containsMouse
            text: "󰆴"
            size: Style.font.icon
            color: forget.containsMouse ? (Style.colors.red ?? root.textColor) : root.textColor
            opacity: forget.containsMouse ? 1 : 0.6

            MouseArea {
                id: forget
                anchors.fill: parent
                anchors.margins: -Style.space.sm
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.forget()
            }
        }
    }
}
