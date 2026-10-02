import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Polkit authentication agent: the password dialog behind pkexec,
// systemctl, mounts, etc. Enter submits, Esc cancels. A wrong password
// shakes the card and polkit asks again.
Scope {
    id: root

    PolkitAgent {
        id: agent
    }

    LazyLoader {
        active: agent.isActive && agent.flow !== null

        PanelWindow {
            id: win

            readonly property AuthFlow flow: agent.flow
            readonly property var p: Style.polkit
            // Between a submit and polkit's answer (PAM delays wrong answers).
            readonly property bool busy: !!flow && !flow.isResponseRequired && !flow.isCompleted
            readonly property bool error: !!flow && (flow.failed || flow.supplementaryIsError || Faillock.locked)

            Component.onCompleted: Faillock.check()

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-polkit"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Style.alpha(p.scrim, p.scrimAlpha)

            Connections {
                target: win.flow

                function onAuthenticationFailed() {
                    Faillock.check();
                    shake.restart();
                }
                function onIsResponseRequiredChanged() {
                    if (win.flow.isResponseRequired)
                        field.input.forceActiveFocus();
                }
            }

            Surface {
                id: card

                section: Style.polkit
                borderColor: win.error ? win.p.borderError : win.p.border
                width: Math.min(Style.space.dialogWidth, parent.width - Style.space.huge * 2)
                height: column.implicitHeight + Style.space.panelPadding * 2
                anchors.centerIn: parent

                transform: Translate {
                    id: offset
                }

                SequentialAnimation {
                    id: shake

                    readonly property int d: Style.space.lg

                    NumberAnimation { target: offset; property: "x"; to: -shake.d; duration: 45 }
                    NumberAnimation { target: offset; property: "x"; to: shake.d; duration: 70 }
                    NumberAnimation { target: offset; property: "x"; to: -shake.d / 2; duration: 60 }
                    NumberAnimation { target: offset; property: "x"; to: 0; duration: 45 }
                }

                ColumnLayout {
                    id: column

                    anchors.fill: parent
                    anchors.margins: Style.space.panelPadding
                    spacing: Style.space.panelGap

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰌾"
                        size: Style.font.displayLarge
                        color: win.error ? win.p.textError : win.p.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space.labelGap

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Authentication required"
                            size: Style.font.title
                            color: win.p.text
                        }

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: win.flow?.message ?? ""
                            size: Style.font.bodySmall
                            color: win.p.text
                            opacity: 0.6
                        }
                    }

                    TextField {
                        id: field

                        Layout.fillWidth: true
                        focus: true
                        enabled: !win.busy
                        password: !(win.flow?.responseVisible ?? false)
                        placeholder: win.busy ? "Authenticating…" : ((win.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password")
                        textColor: win.error ? win.p.textError : win.p.text
                        Component.onCompleted: input.forceActiveFocus()

                        onAccepted: {
                            if (!win.flow?.isResponseRequired || text === "")
                                return;
                            win.flow.submit(text);
                            text = "";
                        }
                        onKeyPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                win.flow.cancelAuthenticationRequest();
                                event.accepted = true;
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: Faillock.message || win.flow?.supplementaryMessage || (win.flow?.failed ? "Wrong password, try again" : "Enter to confirm · Esc to cancel")
                        size: Style.font.caption
                        color: win.error ? win.p.textError : win.p.text
                        opacity: win.error ? 1 : 0.5
                    }
                }
            }
        }
    }
}
