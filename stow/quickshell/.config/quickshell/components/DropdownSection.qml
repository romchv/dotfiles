import QtQuick
import QtQuick.Layouts
import qs.config

// A titled group of DropdownRows in a DropdownPanel. Shows `empty` when it
// has no rows, or hides itself if that's blank.
ColumnLayout {
    id: root

    required property string title
    property int count: 0
    property string empty: ""
    default property alias rows: rowsColumn.data
    readonly property color textColor: Style.popups.text ?? Style.colors.foreground

    visible: count > 0 || empty !== ""
    Layout.fillWidth: true
    spacing: Style.space.xxs

    StyledText {
        text: root.title
        size: Style.font.caption
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
        color: root.textColor
        opacity: 0.6
        bottomPadding: Style.space.xs
    }

    StyledText {
        visible: root.count === 0
        text: root.empty
        size: Style.font.bodySmall
        color: root.textColor
        opacity: 0.6
        leftPadding: Style.space.rowPaddingX
    }

    ColumnLayout {
        id: rowsColumn

        Layout.fillWidth: true
        spacing: Style.space.xxs
    }
}
