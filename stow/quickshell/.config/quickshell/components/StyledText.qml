import QtQuick
import qs.config

// Text with the theme font. Pass `size: Style.font.title` etc.
Text {
    property int size: Style.font.body

    color: Style.colors.foreground ?? "white"
    font.family: Style.font.family
    font.pixelSize: size
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    elide: wrapMode === Text.NoWrap ? Text.ElideRight : Text.ElideNone
}
