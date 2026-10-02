-- Universal clipboard: SUPER+C/V/X work in every app, including terminals.
-- Expects mainMod to be defined beforehand.

-- Tag terminal windows so they can be singled out below (terminals copy/paste
-- with CTRL+Insert / SHIFT+Insert instead of CTRL+C / CTRL+V).
--
-- Send the shortcut as a down/up pair: Hyprland's send_shortcut can leave
-- synthetic key state stuck/repeating.
-- https://github.com/hyprwm/Hyprland/discussions/14099
local function send_shortcut_once(mods, key)
	return function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

		hl.timer(function()
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
		end, { timeout = 50, type = "oneshot" })
	end
end

-- Dynamic tags carry a trailing "*".
local function active_window_is_terminal()
	local window = hl.get_active_window()
	if not window then
		return false
	end

	for _, tag in ipairs(window.tags or {}) do
		if tag:gsub("%*$", "") == "terminal" then
			return true
		end
	end

	return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
	return function()
		if active_window_is_terminal() then
			send_shortcut_once(terminal_mods, terminal_key)()
		else
			send_shortcut_once(default_mods, default_key)()
		end
	end
end

hl.bind(
	mainMod .. " + C",
	universal_clipboard_shortcut("CTRL", "C", "CTRL", "Insert"),
	{ description = "Universal copy" }
)
hl.bind(
	mainMod .. " + V",
	universal_clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"),
	{ description = "Universal paste" }
)
hl.bind(mainMod .. " + X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })

-- Not ported (Omarchy-only): clipboard manager (SUPER+CTRL+V). Install cliphist
-- and bind it to a launcher of your choice if you want one.
