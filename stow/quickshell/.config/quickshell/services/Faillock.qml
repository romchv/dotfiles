pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// pam_faillock state for the current user. After enough failures PAM
// rejects even the right password and only says why in the journal, so
// password prompts (polkit, lock) call check() after a failure and show
// `message` while `locked`.
Singleton {
    id: root

    property bool locked: false
    property date lockedUntil: new Date(0)
    readonly property string message: locked
        ? `Too many attempts, locked until ${Qt.formatTime(lockedUntil, "HH:mm")}`
        : ""

    // /etc/security/faillock.conf, with pam_faillock's defaults.
    property int deny: 3
    property int failInterval: 900
    property int unlockTime: 600

    function check() {
        tally.running = true;
    }

    function update(lines) {
        const now = Date.now();
        const failures = lines
            .map(l => l.match(/^(\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d)\s.*\sV$/))
            .filter(m => m)
            .map(m => new Date(`${m[1]}T${m[2]}`).getTime())
            .filter(t => now - t <= failInterval * 1000);
        if (deny <= 0 || failures.length < deny) {
            locked = false;
            return;
        }
        const last = Math.max(...failures);
        // unlock_time = 0 means locked until an admin resets it.
        const until = unlockTime > 0 ? last + unlockTime * 1000 : Infinity;
        locked = now < until;
        if (locked && until !== Infinity) {
            lockedUntil = new Date(until);
            expiry.interval = until - now + 500;
            expiry.restart();
        }
    }

    Process {
        id: tally
        command: ["faillock", "--user", Quickshell.env("USER")]
        stdout: StdioCollector {
            onStreamFinished: root.update(text.split("\n"))
        }
    }

    // Clears `locked` once the lockout runs out.
    Timer {
        id: expiry
        onTriggered: root.check()
    }

    FileView {
        path: "/etc/security/faillock.conf"
        printErrors: false
        onLoaded: {
            for (const line of text().split("\n")) {
                const m = line.match(/^\s*(deny|fail_interval|unlock_time)\s*=\s*(\d+)/);
                if (!m)
                    continue;
                const v = parseInt(m[2]);
                if (m[1] === "deny")
                    root.deny = v;
                else if (m[1] === "fail_interval")
                    root.failInterval = v;
                else
                    root.unlockTime = v;
            }
            root.check();
        }
    }
}
