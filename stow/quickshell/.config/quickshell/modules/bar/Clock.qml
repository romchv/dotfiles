import QtQuick
import Quickshell
import qs.config

// Time; click to show the date instead, click again for the time.
BarButton {
    id: root

    property bool showDate: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, showDate ? "dddd d MMMM yyyy" : "HH:mm")
    size: Style.font.body
    onClicked: showDate = !showDate
}
