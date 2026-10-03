pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Claude plan limits (5-hour session, 7-day week) from the endpoint Claude
// Code's /usage reads, authenticated with Claude Code's own OAuth token.
// The token never lands in argv: jq builds the header and curl reads it from
// stdin. Claude Code refreshes the token; when it has expired, `error` says so.
Singleton {
    id: root

    // { percent: 0..100, resetsAt: Date } or null until the first fetch.
    property var session: null
    property var weekly: null
    property string error: ""
    property date fetchedAt: new Date(0)
    readonly property bool loaded: session !== null

    readonly property string credentials: Quickshell.env("HOME") + "/.claude/.credentials.json"

    // Called when the popup opens, so the numbers are never more than a minute old.
    function refresh(maxAgeMs) {
        if (!fetcher.running && Date.now() - fetchedAt.getTime() > (maxAgeMs ?? 0))
            fetcher.running = true;
    }

    function _limit(entry) {
        return entry ? { percent: entry.utilization ?? 0, resetsAt: entry.resets_at ? new Date(entry.resets_at) : null } : null;
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: fetcher
        command: ["sh", "-c", `jq -r '"Authorization: Bearer " + .claudeAiOauth.accessToken' "$1" | curl -s -m 15 -H @- -H 'anthropic-beta: oauth-2025-04-20' https://api.anthropic.com/api/oauth/usage`, "sh", root.credentials]
        stdout: StdioCollector {
            onStreamFinished: {
                root.fetchedAt = new Date();
                let data;
                try {
                    data = JSON.parse(text);
                } catch (e) {
                    root.error = "Can't reach Anthropic";
                    return;
                }
                if (data.type === "error") {
                    root.error = data.error?.type === "authentication_error" ? "Token expired, open Claude Code to refresh it" : (data.error?.message ?? "Request failed");
                    return;
                }
                root.error = "";
                root.session = root._limit(data.five_hour);
                root.weekly = root._limit(data.seven_day);
            }
        }
    }
}
