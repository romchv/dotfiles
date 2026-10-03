import QtQuick
import QtQuick.Layouts
import qs.config

// Name/value pairs, two to a row, as in a dropdown's details (battery,
// network). `details` is [[name, value], ...]; pairs with an empty value
// are left out and the rest close up.
GridLayout {
    id: root

    property var details: []
    // Flattened by hand: this JS engine has no Array.flat.
    readonly property var _cells: details.filter(d => d[1] !== "" && d[1] !== undefined && d[1] !== null).reduce((all, d) => all.concat(d), [])
    readonly property color textColor: Style.popups.text ?? Style.colors.foreground

    Layout.fillWidth: true
    columns: 4
    columnSpacing: Style.space.xl
    rowSpacing: Style.space.xs

    Repeater {
        model: root._cells

        StyledText {
            required property int index
            required property var modelData
            readonly property bool isValue: index % 2 === 1

            Layout.fillWidth: isValue
            text: modelData
            size: Style.font.bodySmall
            color: root.textColor
            opacity: isValue ? 1 : 0.6
            horizontalAlignment: isValue ? Text.AlignRight : Text.AlignLeft
        }
    }
}
