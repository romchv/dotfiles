import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.config
import qs.components

// One notification popup: icon or image, summary, body, actions and a
// countdown. Click runs the default action (or dismisses), right-click
// dismisses; hovering pauses the countdown. Critical ones never expire.
Surface {
    id: card

    required property Notification notification
    readonly property var n: notification
    readonly property var t: Style.notifications
    readonly property bool critical: n.urgency === NotificationUrgency.Critical
    readonly property int timeout: n.expireTimeout > 0 ? n.expireTimeout : Style.notificationTimeout
    readonly property var defaultAction: n.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: n.actions.filter(a => a.identifier !== "default")
    readonly property string icon: {
        const i = n.appIcon;
        if (!i)
            return "";
        return i.startsWith("/") || i.includes("://") ? i : Quickshell.iconPath(i, true);
    }
    property real remaining: 1 // countdown, 1 -> 0

    section: Style.notifications
    borderColor: critical ? Style.bar.active : t.border
    implicitWidth: Style.space.notificationWidth
    implicitHeight: content.implicitHeight + Style.space.popupPadding * 2

    NumberAnimation on remaining {
        id: countdown
        running: !card.critical
        paused: hover.containsMouse
        from: 1
        to: 0
        duration: card.timeout
        onFinished: card.n.expire()
    }

    // A replaced notification (same id, new content) starts its countdown over.
    Connections {
        target: card.n
        function onSummaryChanged() {
            countdown.restart();
        }
        function onBodyChanged() {
            countdown.restart();
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && card.defaultAction)
                card.defaultAction.invoke();
            else
                card.n.dismiss();
        }
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Style.space.popupPadding
        spacing: Style.space.xxl

        // Prefer the notification's own image (avatar, album art), else the app icon.
        Item {
            visible: card.n.image !== "" || card.icon !== ""
            Layout.alignment: Qt.AlignTop
            implicitWidth: Style.font.display * 2
            implicitHeight: implicitWidth

            Image {
                anchors.fill: parent
                visible: card.n.image !== ""
                source: card.n.image
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            IconImage {
                anchors.fill: parent
                visible: card.n.image === ""
                source: card.icon
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space.sm

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: card.n.summary || card.n.appName
                    size: Style.font.subtitle
                    font.bold: true
                    color: card.t.text
                }

                StyledText {
                    visible: card.n.appName !== "" && card.n.summary !== ""
                    text: card.n.appName
                    size: Style.font.caption
                    color: card.t.text
                    opacity: 0.5
                }
            }

            StyledText {
                visible: text !== ""
                Layout.fillWidth: true
                text: card.n.body
                textFormat: Text.StyledText // the markup subset the server advertises
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                size: Style.font.body
                color: card.t.text
                opacity: 0.8
                linkColor: card.t.text
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            RowLayout {
                visible: card.buttons.length > 0
                Layout.fillWidth: true
                Layout.topMargin: Style.space.sm
                spacing: Style.space.controlGap

                Repeater {
                    model: card.buttons

                    Rectangle {
                        id: button

                        required property var modelData
                        readonly property var c: Style.controls

                        Layout.fillWidth: true
                        implicitHeight: Style.space.controlHeight
                        radius: Style.radius
                        color: Style.alpha(c.normalColor, buttonArea.containsMouse ? c.hoverCursorFillAlpha : c.normalFillAlpha)
                        border.width: c.normalBorderWidth ?? 1
                        border.color: Style.alpha(c.normalBorder, c.normalBorderAlpha)

                        StyledText {
                            anchors.centerIn: parent
                            width: parent.width - Style.space.controlPaddingX * 2
                            horizontalAlignment: Text.AlignHCenter
                            text: button.modelData.text
                            size: Style.font.bodySmall
                            color: card.t.text
                        }

                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: button.modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    // Countdown along the bottom edge.
    Rectangle {
        visible: !card.critical
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: parent.border.width
        width: (parent.width - parent.border.width * 2) * card.remaining
        height: Style.space.xxs
        color: Style.alpha(card.t.countdown, 0.6)
    }
}
