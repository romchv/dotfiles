import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Invisible layer over the wallpaper, under windows, so it only gets clicks
// on the bare desktop. Double click: the wallpaper picker.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell-desktop"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                onDoubleClicked: Panels.open("wallpapers", modelData.name)
            }
        }
    }
}
