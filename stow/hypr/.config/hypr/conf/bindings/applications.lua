-- Application bindings.
-- Expects mainMod, terminal, fileManager and browser to be defined beforehand.

local function exec(command)
	return hl.dsp.exec_cmd(command)
end

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

-- Focus the first window whose class or title matches pattern (case-insensitive
-- regex), otherwise run command.
local function launch_or_focus(pattern, command)
	return "addr=$(hyprctl clients -j | jq -r --arg p "
		.. shell_quote(pattern)
		.. ' \'.[] | select((.class | test($p; "i")) or (.title | test($p; "i"))) | .address\' | head -n1); '
		.. 'if [ -n "$addr" ]; then '
		.. 'hyprctl dispatch "hl.dsp.focus({ window = \\"address:$addr\\" })" >/dev/null 2>&1'
		.. ' || hyprctl dispatch focuswindow "address:$addr"; '
		.. "else "
		.. command
		.. "; fi"
end

-- Open a URL as a standalone app window (Chromium-based browsers).
local function webapp(url)
	return browser .. " --app=" .. shell_quote(url)
end

-- Chromium names app windows after the URL host, e.g. brave-web.whatsapp.com__-Default.
local function webapp_or_focus(url)
	local host = url:match("^https?://([^/]+)"):gsub("%.", "\\.")
	return launch_or_focus(host, webapp(url))
end

local function tui(command)
	return terminal .. " -e " .. command
end

-- Essential applications.
hl.bind(mainMod .. " + RETURN", exec(terminal), { description = "Terminal" })
hl.bind(mainMod .. " + SHIFT + RETURN", exec(browser), { description = "Browser" })
hl.bind(mainMod .. " + SHIFT + F", exec(fileManager), { description = "File manager" })
hl.bind(mainMod .. " + SHIFT + B", exec(browser), { description = "Browser" })
hl.bind(mainMod .. " + SHIFT + ALT + B", exec(browser .. " --incognito"), { description = "Browser (private)" })
hl.bind(mainMod .. " + SHIFT + N", exec(tui("nvim")), { description = "Editor" })

-- Applications and TUIs.
-- hl.bind(mainMod .. " + SHIFT + M", exec(launch_or_focus("^spotify$", "spotify")), { description = "Music" })
-- hl.bind(mainMod .. " + SHIFT + D", exec(tui("lazydocker")), { description = "Docker" })
hl.bind(mainMod .. " + CTRL + T", exec(tui("btop")), { description = "Activity" })
-- Audio, Bluetooth and Wi-Fi open the bar's Quickshell menus.
hl.bind(mainMod .. " + CTRL + A", exec("qs ipc call audio toggle"), { description = "Audio" })
hl.bind(mainMod .. " + CTRL + B", exec("qs ipc call bluetooth toggle"), { description = "Bluetooth" })
hl.bind(mainMod .. " + CTRL + W", exec("qs ipc call wifi toggle"), { description = "Wi-Fi" })

-- Web apps.
hl.bind(mainMod .. " + SHIFT + A", exec(webapp("https://chatgpt.com")), { description = "ChatGPT" })
hl.bind(mainMod .. " + SHIFT + C", exec(webapp("https://claude.ai")), { description = "Claude" })
hl.bind(mainMod .. " + CTRL + M", exec(webapp("https://mail.proton.me")), { description = "Proton Mail" })
hl.bind(
	mainMod .. " + SHIFT + ALT + G",
	exec(webapp_or_focus("https://web.whatsapp.com/")),
	{ description = "WhatsApp" }
)
hl.bind(mainMod .. " + SHIFT + S", exec(webapp_or_focus("https://maps.google.com/")), { description = "Google Maps" })
