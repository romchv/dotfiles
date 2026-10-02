import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.config

// Full-screen password screen: blurred wallpaper, clock, date, password
// field and a message line. Shared by the lockscreen and the greetd login
// screen; the owner keeps the state and binds it in.
Item {
    id: root

    property url wallpaper
    property string text: "" // bind to shared state; edits come back through edited()
    property bool busy: false
    property bool error: false
    property string message: ""
    property string placeholder: "Password"
    property bool autoFocus: true // focus the password field when shown
    readonly property var l: Style.lock

    // Extra rows between the date and the field (e.g. a username).
    default property alias content: slot.data

    signal edited(string text)
    signal submitted

    function shake() {
        shakeAnim.restart();
    }

    function focusField() {
        field.input.forceActiveFocus();
    }

    onTextChanged: {
        if (field.text !== text)
            field.text = text;
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.background ?? "black"
    }

    Image {
        id: image

        anchors.fill: parent
        source: root.wallpaper
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: image
        source: image
        visible: image.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: Style.lockBlur
        blurMax: 64
    }

    Rectangle {
        anchors.fill: parent
        color: Style.alpha(Style.colors.background, Style.lockDim)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Style.space.panelGap

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            size: Style.font.displayLarge * 3
            color: root.l.text
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Style.space.huge * 2
            text: Qt.formatDateTime(clock.date, "dddd d MMMM")
            size: Style.font.title
            color: root.l.text
            opacity: 0.7
        }

        ColumnLayout {
            id: slot
            Layout.alignment: Qt.AlignHCenter
            spacing: Style.space.panelGap
            visible: children.length > 0
        }

        TextField {
            id: field

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Style.space.lockFieldWidth
            focus: true
            password: true
            input.readOnly: root.busy
            placeholder: root.busy ? "Authenticating…" : root.placeholder
            horizontalAlignment: TextInput.AlignHCenter
            textColor: root.error ? root.l.textError : root.l.text
            placeholderColor: root.error ? root.l.textError : root.l.placeholder
            selectionColor: Style.alpha(root.l.selection, root.l.selectionAlpha)
            fillColor: Style.alpha(root.l.background, root.l.backgroundAlpha)
            borderWidth: Style.borderWidth
            borderColor: Style.alpha(root.error && text === "" ? root.l.borderError
                                     : (text !== "" || root.busy) ? root.l.borderActive
                                     : root.l.border, root.l.borderAlpha)

            onTextChanged: {
                if (root.text !== text)
                    root.edited(text);
            }
            onAccepted: root.submitted()

            transform: Translate {
                id: offset
            }

            SequentialAnimation {
                id: shakeAnim

                readonly property int d: Style.space.lg

                NumberAnimation { target: offset; property: "x"; to: -shakeAnim.d; duration: 45 }
                NumberAnimation { target: offset; property: "x"; to: shakeAnim.d; duration: 70 }
                NumberAnimation { target: offset; property: "x"; to: -shakeAnim.d / 2; duration: 60 }
                NumberAnimation { target: offset; property: "x"; to: 0; duration: 45 }
            }
        }

        // Always takes its line, so the field doesn't move when a message appears.
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.message || " "
            size: Style.font.bodySmall
            color: root.l.textError
        }
    }

    Component.onCompleted: if (autoFocus) focusField()
}
