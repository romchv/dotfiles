import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services

// Lockscreen on every monitor. `qs ipc call lock lock` locks; it's
// hypridle's lock_cmd, so loginctl lock-session (SUPER+CTRL+L, idle,
// before sleep) ends up here too. The password goes through PAM's
// "login" stack, like hyprlock/swaylock.
Scope {
    id: root

    // Shared by every monitor's surface.
    property string text: ""
    property bool busy: false // PAM is checking
    property bool failed: false
    property string pamMessage: "" // PAM info/error text other than the prompt

    signal failure

    function lock() {
        if (sessionLock.locked)
            return;
        text = "";
        failed = false;
        pamMessage = "";
        Panels.close();
        Faillock.check();
        sessionLock.locked = true;
    }

    function submit() {
        if (busy || text === "")
            return;
        busy = true;
        failed = false;
        pamMessage = "";
        if (!pam.start()) {
            busy = false;
            pamMessage = "Couldn't start authentication";
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }

    PamContext {
        id: pam

        config: "login"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.text);
        }
        onMessageChanged: {
            if (message && !/password/i.test(message))
                root.pamMessage = message;
        }
        onCompleted: result => {
            root.busy = false;
            root.text = "";
            if (result === PamResult.Success) {
                sessionLock.locked = false;
                return;
            }
            root.failed = true;
            Faillock.check();
            root.failure();
        }
        onError: error => {
            root.busy = false;
            root.failed = true;
            root.pamMessage = `Authentication error (${PamError.toString(error)})`;
        }
    }

    WlSessionLock {
        id: sessionLock

        LockSurface {
            lock: root
        }
    }
}
