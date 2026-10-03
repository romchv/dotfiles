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

    signal shake

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
        shake();
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

    // cage shows its only window fullscreen, stretched across every monitor
    // (its default -m extend), so give each monitor its own login screen
    // sized to it; they share the state above, like the lockscreen. The
    // leftmost one takes keyboard focus.
    FloatingWindow {
        id: window

        readonly property var screens: [...Quickshell.screens].sort((a, b) => a.x - b.x || a.y - b.y)
        readonly property int originX: Math.min(...screens.map(s => s.x))
        readonly property int originY: Math.min(...screens.map(s => s.y))

        color: Style.colors.background ?? "black"
        implicitWidth: 1280
        implicitHeight: 800

        Repeater {
            model: window.screens.length ? window.screens : [null]

            AuthScreen {
                id: auth

                required property var modelData
                required property int index
                readonly property bool primary: index === 0

                x: modelData ? modelData.x - window.originX : 0
                y: modelData ? modelData.y - window.originY : 0
                width: modelData ? modelData.width : window.width
                height: modelData ? modelData.height : window.height

                autoFocus: primary && !root.askUser
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

                Connections {
                    target: root
                    function onShake() {
                        auth.shake();
                    }
                }

                TextField {
                    id: userField

                    visible: root.askUser
                    Layout.preferredWidth: Style.space.lockFieldWidth
                    placeholder: "Username"
                    text: root.user
                    horizontalAlignment: TextInput.AlignHCenter
                    textColor: auth.l.text
                    placeholderColor: auth.l.placeholder
                    fillColor: Style.alpha(auth.l.background, auth.l.backgroundAlpha)
                    borderWidth: Style.borderWidth
                    borderColor: Style.alpha(auth.l.border, auth.l.borderAlpha)
                    onTextChanged: if (root.user !== text.trim()) root.user = text.trim()
                    onAccepted: auth.focusField()
                    Component.onCompleted: if (root.askUser && auth.primary) input.forceActiveFocus()
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
}
