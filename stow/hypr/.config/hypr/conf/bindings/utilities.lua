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

-- Not ported (Omarchy-only), free to rebind to your own tools:
--   menus (SUPER+ALT+SPACE, SUPER+CTRL+C/O/H/S/R,
--     XF86PowerOff, SUPER+SHIFT+code:201, background SUPER+CTRL+SPACE, theme SUPER+SHIFT+CTRL+SPACE),
--   keybinding viewers (SUPER+ALT+K, SUPER+CTRL+K), emojis (SUPER+CTRL+E),
--   calculator (SUPER+CTRL+Q, XF86Calculator),
--   bar panels (SUPER+CTRL+A/B/D/W/P, SUPER+CTRL+ALT+D, SUPER+CTRL+1..9),
--   window transparency/gaps/square toggles (SUPER+[SHIFT/CTRL]+BACKSPACE),
--   idle/nightlight toggles (SUPER+CTRL+I/N), laptop display (SUPER+CTRL+[ALT]+Delete), lid switch,
--   screen recording (ALT+PRINT), OCR (SUPER+CTRL+PRINT), webcam overlay (SUPER+ALT+code:34/35),
--   transcode (SUPER+CTRL+PERIOD), reminders (SUPER+CTRL+ALT+R, SUPER+SHIFT+CTRL+R),
--   time/battery/weather notifications (SUPER+CTRL+ALT+T/B/W), agent (SUPER+SHIFT+CTRL+A),
--   region-picker keyboard controls.
-- Activity (btop, SUPER+CTRL+T) moved to applications.lua.
