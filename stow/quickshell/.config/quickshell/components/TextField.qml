import QtQuick
import qs.config

// Single-line input styled with the [controls] tokens: normal, and focus
// while it has keyboard focus. Shared by the launcher, polkit and lock;
// the fill/border/placeholder properties let a surface use its own tokens.
FocusScope {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property string icon: ""
    property bool password: false
    property bool showCursor: true
    property color textColor: Style.colors.foreground ?? "white"

    signal accepted
    // Every key before the input handles it; set event.accepted to swallow it.
    signal keyPressed(var event)

    readonly property var c: Style.controls
    readonly property bool focused: input.activeFocus

    property color fillColor: Style.alpha(focused ? c.focusColor : c.normalColor,
                                          focused ? c.focusFillAlpha : c.normalFillAlpha)
    property color borderColor: Style.alpha(focused ? c.focusBorder : c.normalBorder,
                                            focused ? c.focusBorderAlpha : c.normalBorderAlpha)
    property int borderWidth: focused ? (c.focusBorderWidth ?? 1) : (c.normalBorderWidth ?? 1)
    property color placeholderColor: Style.alpha(textColor, 0.45)
    property color selectionColor: Style.alpha(textColor, c.selectionFillAlpha ?? 0.35)
    property int fontSize: Style.font.subtitle
    property int horizontalAlignment: TextInput.AlignLeft

    implicitWidth: 240
    implicitHeight: Math.max(Style.space.controlHeight, input.implicitHeight + Style.space.inputPaddingY * 2)

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: root.fillColor
        border.width: root.borderWidth
        border.color: root.borderColor

        Behavior on border.color {
            ColorAnimation { duration: Style.anim.normal }
        }
    }

    StyledText {
        id: glyph
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: Style.space.controlPaddingX
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        size: Style.font.icon
        color: root.textColor
        opacity: 0.7
    }

    TextInput {
        id: input

        anchors.left: glyph.visible ? glyph.right : parent.left
        anchors.leftMargin: glyph.visible ? Style.space.lg : Style.space.controlPaddingX
        anchors.right: parent.right
        anchors.rightMargin: Style.space.controlPaddingX
        anchors.verticalCenter: parent.verticalCenter
        focus: true
        clip: true
        color: root.textColor
        selectionColor: root.selectionColor
        selectedTextColor: root.textColor
        font.family: Style.font.family
        font.pixelSize: root.fontSize
        horizontalAlignment: root.horizontalAlignment
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"

        // Hidden while a centered field is empty, where it would sit on the placeholder.
        cursorDelegate: Rectangle {
            width: 1
            color: root.textColor
            visible: root.showCursor && input.activeFocus && blink.on && (input.text !== "" || root.horizontalAlignment !== TextInput.AlignHCenter)

            Timer {
                id: blink
                property bool on: true
                interval: 530
                repeat: true
                running: root.showCursor && input.activeFocus
                onTriggered: on = !on
            }

            Connections {
                target: input
                function onTextChanged() {
                    blink.on = true;
                    blink.restart();
                }
            }
        }

        Keys.onPressed: event => root.keyPressed(event)
        onAccepted: root.accepted()

        StyledText {
            anchors.fill: parent
            visible: input.text === "" && root.placeholder !== ""
            text: root.placeholder
            size: input.font.pixelSize
            color: root.placeholderColor
            horizontalAlignment: root.horizontalAlignment
        }
    }
}
