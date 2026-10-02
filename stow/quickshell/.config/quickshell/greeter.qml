import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Greetd
import qs.config
import qs.components

// Login screen run by greetd (inside cage) before any session exists:
// `qs -p .../greeter.qml`. Same look as the lockscreen. greetd runs it as
// the greeter user, which can't read ~, so greeter-sync copies this config
// and the theme to /etc/greetd and these variables point at the copies:
//   QS_THEME_FILE         theme (read by Style)
//   QS_GREETER_WALLPAPER  background image
//   QS_GREETER_USER       user to log in; empty shows a username field
//   QS_GREETER_SESSION    command to start (default: start-hyprland)
// Outside greetd it runs as a preview that never logs in.
ShellRoot {
    id: root

    property string user: Quickshell.env("QS_GREETER_USER") ?? ""
    readonly property bool askUser: (Quickshell.env("QS_GREETER_USER") ?? "") === ""
    readonly property string session: Quickshell.env("QS_GREETER_SESSION") || "start-hyprland"

    property string text: ""
    property bool busy: false
    property bool failed: false
    property string message: ""

    function submit() {
        if (busy || text === "")
            return;
        if (user === "") {
            message = "Enter a username";
            return;
        }
        busy = true;
        failed = false;
        message = "";
        if (!Greetd.available) {
            fail("Preview: greetd isn't running");
            return;
        }
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        Greetd.createSession(user);
    }

    function fail(reason) {
        busy = false;
        failed = true;
        text = "";
        message = reason;
        auth.shake();
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired)
                Greetd.respond(root.text);
            else if (message)
                root.message = message; // e.g. faillock's "(5 minutes left to unlock)"
        }
        function onAuthFailure(message) {
            root.fail(root.message || "Wrong password");
        }
        function onError(error) {
            root.fail(`Login error: ${error}`);
        }
        // Start the session through a login shell so ~/.bash_profile sets
        // PATH etc. as on the console; quit so greetd hands over the VT.
        // greetd joins the arguments with spaces and runs the result with
        // `sh -c`, so pass one string with the inner command quoted.
        // Output goes to the journal (journalctl -t hyprland-session) instead
        // of flashing on the console before the desktop appears.
        function onReadyToLaunch() {
            const quoted = "'" + `exec systemd-cat --identifier=hyprland-session ${root.session}`.replace(/'/g, "'\\''") + "'";
            Greetd.launch([`bash -l -c ${quoted}`], [], true);
        }
    }

    // cage shows its only window fullscreen.
    FloatingWindow {
        color: Style.colors.background ?? "black"
        implicitWidth: 1280
        implicitHeight: 800

        AuthScreen {
            id: auth

            anchors.fill: parent
            autoFocus: !root.askUser
            wallpaper: Quickshell.env("QS_GREETER_WALLPAPER") ? "file://" + Quickshell.env("QS_GREETER_WALLPAPER") : ""
            text: root.text
            busy: root.busy
            error: root.failed
            message: root.message

            onEdited: text => {
                root.text = text;
                if (text !== "")
                    root.failed = false;
            }
            onSubmitted: root.submit()

            TextField {
                id: userField

                visible: root.askUser
                Layout.preferredWidth: Style.space.lockFieldWidth
                placeholder: "Username"
                horizontalAlignment: TextInput.AlignHCenter
                textColor: auth.l.text
                placeholderColor: auth.l.placeholder
                fillColor: Style.alpha(auth.l.background, auth.l.backgroundAlpha)
                borderWidth: Style.borderWidth
                borderColor: Style.alpha(auth.l.border, auth.l.borderAlpha)
                onTextChanged: root.user = text.trim()
                onAccepted: auth.focusField()
                Component.onCompleted: if (root.askUser) input.forceActiveFocus()
            }

            // The user being logged in, when it's fixed.
            StyledText {
                visible: !root.askUser
                Layout.alignment: Qt.AlignHCenter
                text: root.user
                size: Style.font.subtitle
                color: auth.l.text
            }
        }
    }
}
