import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Keypad calculator: SUPER+CTRL+Q (`qs ipc call calculator toggle`). The
// expression builds up above the result and stays there after =. PRG mode
// works on whole numbers and shows the value in HEX, DEC and BIN at once;
// the highlighted row is the base you type in.
// Keys: digits, a-f, + - * / % ( ) . type; Enter or = evaluates; Backspace
// deletes, Delete clears; Tab switches the input base (PRG); Ctrl+M switches
// mode; Ctrl+C copies the result; Esc closes.
// A floating window, not an overlay: Hyprland floats and centers it on the
// focused monitor (conf/windowrules.lua) and it stays where it is put; drag
// it by the header or with SUPER+drag. Independent of Panels, so opening the
// launcher or another overlay doesn't close it.
Scope {
    id: root

    property bool shown: false

    IpcHandler {
        target: "calculator"

        function toggle(): void {
            root.shown = !root.shown;
        }
        function open(): void {
            root.shown = true;
        }
        function close(): void {
            root.shown = false;
        }
    }

    // The window only exists while open, so every open starts fresh.
    LazyLoader {
        active: root.shown

        FloatingWindow {
            id: calc

            property bool programmer: false
            property int base: 10
            property string expr: "" // what is being typed, with * / - operators
            property string shownExpr: "" // the evaluated expression, kept above its result
            property bool evaluated: false
            property bool carried: false // expr is a value carried over by a mode or base switch
            property string error: ""
            property real value: 0 // last complete result: the display and the base rows
            readonly property var preview: Calc.evaluate(expr, base)
            readonly property var section: Style.launcher
            readonly property var bases: [16, 10, 2]
            readonly property var baseNames: ({ 16: "HEX", 10: "DEC", 2: "BIN" })
            // omacalc's order; both modes keep the operators and = in the last column.
            readonly property var standardKeys: ["AC", "±", "%", "÷", "7", "8", "9", "×", "4", "5", "6", "−", "1", "2", "3", "+", "0", ".", "⌫", "="]
            readonly property var programmerKeys: ["D", "E", "F", "AC", "÷", "A", "B", "C", "(", "×", "7", "8", "9", ")", "−", "4", "5", "6", "⌫", "+", "1", "2", "3", "0", "="]

            // While typing, the result follows each complete expression.
            onPreviewChanged: {
                if (preview.ok)
                    value = preview.value;
                else if (expr === "" && !evaluated)
                    value = 0;
            }

            function allowed(ch) {
                if ("0123456789ABCDEF".includes(ch))
                    return parseInt(ch, 16) < base;
                if (ch === "." || ch === "%")
                    return !programmer;
                return "+-*/()".includes(ch);
            }

            function input(ch) {
                if (!allowed(ch))
                    return;
                error = "";
                if (evaluated || carried) {
                    evaluated = false;
                    carried = false;
                    shownExpr = "";
                    // A number starts a new calculation; an operator continues from the result.
                    if (!"+-*/%)".includes(ch))
                        expr = "";
                }
                if ("+*/".includes(ch)) {
                    if (expr === "")
                        expr = "0";
                    expr = expr.replace(/[-+*/]+$/, "");
                } else if (ch === "-") {
                    expr = expr.replace(/[-+]$/, "");
                } else if (ch === "%") {
                    if (!/[0-9.)]$/.test(expr))
                        return;
                } else if (ch === ".") {
                    if (/\.[0-9]*$/.test(expr))
                        return;
                    if (!/[0-9]$/.test(expr))
                        ch = "0.";
                }
                expr += ch;
            }

            function backspace() {
                error = "";
                evaluated = false;
                carried = false;
                shownExpr = "";
                expr = expr.slice(0, -1);
            }

            function clear() {
                error = "";
                evaluated = false;
                carried = false;
                shownExpr = "";
                expr = "";
                value = 0;
            }

            function equals() {
                const r = Calc.evaluate(expr, base);
                if (!r.ok) {
                    if (r.error !== "Incomplete")
                        error = r.error;
                    return;
                }
                evaluated = true;
                shownExpr = Calc.pretty(expr);
                // Keep the result as the start of the next expression.
                const raw = Calc.raw(r.value, base);
                expr = raw.includes("e") ? "" : raw;
                value = r.value;
            }

            // ± on the number being typed: drops or adds its minus, or flips the operator before it.
            function toggleSign() {
                const m = expr.match(/[0-9A-F.]+$/);
                if (!m)
                    return;
                const before = expr.slice(0, expr.length - m[0].length);
                const prev = before.slice(-1);
                const unaryMinus = prev === "-" && (before.length === 1 || /[-+*/(]/.test(before.slice(-2, -1)));
                if (unaryMinus)
                    expr = before.slice(0, -1) + m[0];
                else if (prev === "-" || prev === "+")
                    expr = before.slice(0, -1) + (prev === "-" ? "+" : "-") + m[0];
                else
                    expr = before + "-" + m[0];
                error = "";
                evaluated = false;
                carried = false;
                shownExpr = "";
            }

            // Switching base carries the current value over as a whole number.
            function setBase(b) {
                const n = Math.trunc(value);
                error = "";
                evaluated = false;
                carried = false;
                shownExpr = "";
                base = b;
                expr = n !== 0 ? Calc.raw(n, b) : "";
                value = n;
                // Shown and usable with an operator, but the next digit starts a new number.
                carried = expr !== "";
            }

            function setMode(prg) {
                programmer = prg;
                setBase(10);
            }

            function cycleBase(delta) {
                setBase(bases[(bases.indexOf(base) + delta + bases.length) % bases.length]);
            }

            function press(label) {
                switch (label) {
                case "AC":
                    clear();
                    break;
                case "⌫":
                    backspace();
                    break;
                case "±":
                    toggleSign();
                    break;
                case "=":
                    equals();
                    break;
                case "÷":
                    input("/");
                    break;
                case "×":
                    input("*");
                    break;
                case "−":
                    input("-");
                    break;
                default:
                    input(label);
                }
            }

            function copy() {
                Quickshell.execDetached(["wl-copy", "--", Calc.raw(value, base)]);
            }

            // Matched by the Calculator window rule; the size follows the content.
            title: "Calculator"
            implicitWidth: keypad.columns * keypad.keyWidth + keypad.spacing * (keypad.columns - 1) + card.pad * 2
            implicitHeight: column.implicitHeight + card.pad * 2
            minimumSize: Qt.size(implicitWidth, implicitHeight)
            maximumSize: Qt.size(implicitWidth, implicitHeight)
            color: "transparent"
            onClosed: root.shown = false

            Item {
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    const text = event.text;
                    if (event.key === Qt.Key_Escape)
                        root.shown = false;
                    else if (ctrl && event.key === Qt.Key_C)
                        calc.copy();
                    else if (ctrl && event.key === Qt.Key_M)
                        calc.setMode(!calc.programmer);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || text === "=")
                        calc.equals();
                    else if (event.key === Qt.Key_Backspace)
                        calc.backspace();
                    else if (event.key === Qt.Key_Delete)
                        calc.clear();
                    else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        if (calc.programmer)
                            calc.cycleBase(event.key === Qt.Key_Backtab ? -1 : 1);
                    } else if (!ctrl && text.length === 1 && "0123456789abcdefABCDEF.+-*/%()xX".includes(text))
                        calc.input(text === "x" || text === "X" ? "*" : text.toUpperCase());
                    else
                        return;
                    event.accepted = true;
                }
            }

            Surface {
                id: card

                readonly property int pad: Style.space.popupPadding

                section: calc.section
                anchors.fill: parent
                // Opaque, unlike the launcher it takes its colors from; Hyprland draws the border.
                color: calc.section.background ?? "black"
                border.width: 0

                ColumnLayout {
                    id: column

                    anchors.fill: parent
                    anchors.margins: card.pad
                    spacing: Style.space.md

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space.sm

                        Chip {
                            label: "STD"
                            selected: !calc.programmer
                            onClicked: calc.setMode(false)
                        }

                        Chip {
                            label: "PRG"
                            selected: calc.programmer
                            onClicked: calc.setMode(true)
                        }

                        // Empty header space moves the window.
                        MouseArea {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            cursorShape: Qt.SizeAllCursor
                            onPressed: calc.startSystemMove()
                        }

                        StyledText {
                            text: "Ctrl+C copy"
                            size: Style.font.caption
                            color: calc.section.text
                            opacity: 0.5
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: Style.space.lg
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        text: (calc.evaluated ? calc.shownExpr + " =" : Calc.pretty(calc.expr)) || " "
                        size: Style.font.subtitle
                        color: calc.section.text
                        opacity: 0.5
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Style.font.displayLarge * 1.4
                        horizontalAlignment: Text.AlignRight
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Style.font.title
                        elide: Text.ElideLeft
                        text: calc.error || Calc.format(calc.value, calc.base)
                        size: calc.error ? Style.font.heading : Style.font.displayLarge
                        color: calc.error ? (Style.colors.red ?? calc.section.text) : calc.section.text
                    }

                    // PRG: the value in every base; click a row to type in that base.
                    Repeater {
                        model: calc.programmer ? calc.bases : []

                        Rectangle {
                            id: baseRow

                            required property int modelData
                            readonly property bool selected: modelData === calc.base

                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(Style.space.popupRowHeight, digits.implicitHeight + Style.space.md * 2)
                            radius: Style.radius
                            color: selected ? Style.alpha(calc.section.selectedBackground, calc.section.selectedBackgroundAlpha) : "transparent"
                            border.width: selected ? 1 : 0
                            border.color: Style.alpha(calc.section.selectedBorder, calc.section.selectedBorderAlpha)

                            StyledText {
                                id: name
                                anchors.left: parent.left
                                anchors.leftMargin: Style.space.rowPaddingX
                                anchors.verticalCenter: parent.verticalCenter
                                text: calc.baseNames[baseRow.modelData]
                                size: Style.font.caption
                                color: calc.section.text
                                opacity: baseRow.selected ? 1 : 0.5
                            }

                            StyledText {
                                id: digits
                                anchors.left: name.right
                                anchors.leftMargin: Style.space.lg
                                anchors.right: parent.right
                                anchors.rightMargin: Style.space.rowPaddingX
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                wrapMode: Text.WrapAnywhere
                                text: Calc.format(calc.value, baseRow.modelData)
                                color: calc.section.text
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: calc.setBase(baseRow.modelData)
                            }
                        }
                    }

                    // Divides the display from the keypad, as on omacalc.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Style.space.sm
                        implicitHeight: 1
                        color: Style.alpha(calc.section.text, 0.15)
                    }

                    Grid {
                        id: keypad

                        // Slightly wider than tall, as on omacalc; the window's width follows from them.
                        readonly property int keyWidth: Math.round(Style.space.launcherRowHeight * 1.65)
                        readonly property int keyHeight: Math.round(Style.space.launcherRowHeight * 1.4)

                        Layout.fillWidth: true
                        Layout.topMargin: Style.space.sm
                        columns: calc.programmer ? 5 : 4
                        spacing: Style.space.xl

                        Repeater {
                            model: calc.programmer ? calc.programmerKeys : calc.standardKeys

                            CalcKey {
                                required property string modelData

                                width: keypad.keyWidth
                                height: keypad.keyHeight
                                label: modelData
                                accent: modelData === "="
                                // Everything but the operator column is the number pad.
                                dark: !"÷×−+=".includes(modelData)
                                textColor: calc.section.text
                                enabled: modelData.length !== 1 || !"0123456789ABCDEF".includes(modelData) || calc.allowed(modelData)
                                onClicked: calc.press(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // STD / PRG switch, highlighted like a selected picker row.
    component Chip: Rectangle {
        id: chip

        property string label: ""
        property bool selected: false
        readonly property var section: Style.launcher

        signal clicked

        implicitWidth: chipText.implicitWidth + Style.space.lg * 2
        implicitHeight: chipText.implicitHeight + Style.space.xs * 2
        radius: Style.radius
        color: selected ? Style.alpha(section.selectedBackground, section.selectedBackgroundAlpha) : "transparent"
        border.width: selected ? 1 : 0
        border.color: Style.alpha(section.selectedBorder, section.selectedBorderAlpha)

        StyledText {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            size: Style.font.caption
            color: chip.section.text
            opacity: chip.selected ? 1 : 0.5
        }

        MouseArea {
            anchors.fill: parent
            onClicked: chip.clicked()
        }
    }
}
