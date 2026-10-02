pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon (org.freedesktop.Notifications). Every notification
// is shown as a popup until it expires or is dismissed; nothing is kept
// afterwards. Do Not Disturb drops everything except critical ones.
Singleton {
    id: root

    property bool dnd: false
    // Newest first.
    readonly property var popups: server.trackedNotifications.values.slice().reverse()

    function dismissLatest() {
        popups[0]?.dismiss();
    }

    function dismissAll() {
        for (const n of popups.slice())
            n.dismiss();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            if (root.dnd && notification.urgency !== NotificationUrgency.Critical)
                return; // not tracked: dropped
            notification.tracked = true;
        }
    }
}
