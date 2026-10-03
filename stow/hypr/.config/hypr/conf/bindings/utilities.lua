-- Screenshots, color picker, zoom and lock.
-- Expects mainMod to be defined beforehand. Uses grim, slurp, wl-copy and hyprpicker.

local function exec(command)
	return hl.dsp.exec_cmd(command)
end

-- Screenshots go to the clipboard.
hl.bind("PRINT", exec('grim -g "$(slurp)" - | wl-copy'), { description = "Screenshot (region)" })
hl.bind("SHIFT + PRINT", exec("grim - | wl-copy"), { description = "Screenshot (full screen)" })
hl.bind(mainMod .. " + PRINT", exec("pkill hyprpicker || hyprpicker -a"), { description = "Color picker" })

hl.bind(mainMod .. " + CTRL + Z", function()
	local zoom = hl.get_config("cursor.zoom_factor") or 1
	hl.config({ cursor = { zoom_factor = zoom + 1 } })
end, { description = "Zoom in" })

hl.bind(mainMod .. " + CTRL + ALT + Z", function()
	hl.config({ cursor = { zoom_factor = 1 } })
end, { description = "Reset zoom" })

-- Needs a locker that listens to logind (e.g. hypridle + hyprlock).
hl.bind(mainMod .. " + CTRL + L", exec("loginctl lock-session"), { description = "Lock system" })

-- Quickshell (IpcHandlers in ~/.config/quickshell).
hl.bind(mainMod .. " + SPACE", exec("qs ipc call launcher toggle"), { description = "App launcher" })
hl.bind(mainMod .. " + ESCAPE", exec("qs ipc call power toggle"), { description = "Power menu" })
hl.bind(mainMod .. " + K", exec("qs ipc call keybinds toggle"), { description = "Keybind cheatsheet" })
hl.bind(mainMod .. " + CTRL + Q", exec("qs ipc call calculator toggle"), { description = "Calculator" })
hl.bind(mainMod .. " + CTRL + N", exec("qs ipc call nightlight toggle"), { description = "Toggle night light" })
hl.bind(mainMod .. " + CTRL + C", exec("qs ipc call claude toggle"), { description = "Claude Code limits" })

-- Laptops only: the bar shows no battery elsewhere.
local battery = os.execute("ls /sys/class/power_supply | grep -q ^BAT")
if battery == true or battery == 0 then
	hl.bind(mainMod .. " + CTRL + P", exec("qs ipc call battery toggle"), { description = "Battery info" })
end
hl.bind(mainMod .. " + SHIFT + SPACE", exec("qs ipc call bar toggle"), { description = "Toggle bar" })
hl.bind(mainMod .. " + COMMA", exec("qs ipc call notifications dismiss"), { description = "Dismiss notification" })
hl.bind(
	mainMod .. " + SHIFT + COMMA",
	exec("qs ipc call notifications dismissAll"),
	{ description = "Dismiss all notifications" }
)
hl.bind(
	mainMod .. " + CTRL + COMMA",
	exec("qs ipc call notifications toggleDnd"),
	{ description = "Toggle Do Not Disturb" }
)
