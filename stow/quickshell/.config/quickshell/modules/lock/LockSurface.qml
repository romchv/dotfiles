import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// One monitor of the lockscreen. Typing on any monitor shows on all of
// them (state lives in Lock.qml).
WlSessionLockSurface {
    id: surface

    property var lock

    AuthScreen {
        id: auth

        anchors.fill: parent
        wallpaper: Wallpaper.forScreen(surface.screen?.name ?? "")
        text: surface.lock.text
        busy: surface.lock.busy
        error: surface.lock.failed || Faillock.locked
        message: Faillock.message || surface.lock.pamMessage || (surface.lock.failed ? "Wrong password" : "")

        onEdited: text => {
            surface.lock.text = text;
            if (text !== "")
                surface.lock.failed = false;
        }
        onSubmitted: surface.lock.submit()

        Connections {
            target: surface.lock
            function onFailure() {
                auth.shake();
            }
        }
    }
}
