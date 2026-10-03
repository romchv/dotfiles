hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.window_rule({
	name = "supress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Tag all windows for default opacity (apps can override with -default-opacity tag).
hl.window_rule({
	match = { class = ".*" },
	tag = "+default-opacity",
})

-- Apply default opacity after apps have had a chance to opt out.
hl.window_rule({
	match = { tag = "default-opacity" },
	opacity = "0.985 0.96",
})

-- Bitwarden
hl.window_rule({
	match = { class = "^(Bitwarden|chrome-nngceckbapebfimnlniiiahkandclblb-Default)$" },
	no_screen_share = true,
	tag = "+floating-window",
})

-- Browser tags and styling.
hl.window_rule({
	match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-(browser|origin))" },
	tag = "+chromium-based-browser",
})

hl.window_rule({
	match = { class = "([fF]irefox|zen|librewolf)" },
	tag = "+firefox-based-browser",
})

hl.window_rule({
	match = { tag = "chromium-based-browser" },
	tag = "-default-opacity",
	tile = true,
	opacity = "1.0 0.985",
})

hl.window_rule({
	match = { tag = "firefox-based-browser" },
	tag = "-default-opacity",
	opacity = "1.0 0.985",
})

-- Float LocalSend and fzf file picker.
hl.window_rule({
	match = { class = "(Share|localsend)" },
	float = true,
})

hl.window_rule({
	match = { class = "localsend" },
	size = { 1100, 700 },
})

-- Picture-in-picture overlays.
hl.window_rule({
	match = { title = "(Picture.?in.?[Pp]icture)" },
	tag = "+pip",
})

hl.window_rule({
	match = { tag = "pip" },
	tag = "-default-opacity",
	float = true,
	pin = true,
	size = { 600, 338 },
	keep_aspect_ratio = true,
	border_size = 0,
	opacity = "1 1",
	move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})

-- Remove the 1px border around the slurp region selection used by screenshots.
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true, animation = "none" })

-- Qemu
hl.window_rule({
	match = { class = "qemu" },
	tag = "-default-opacity",
	opacity = "1 1",
})

-- Steam
hl.window_rule({
	match = { class = "steam" },
	float = true,
	idle_inhibit = "fullscreen",
})

hl.window_rule({
	match = { class = "steam", title = "Steam" },
	center = true,
	size = { 1100, 700 },
})

hl.window_rule({
	match = { class = "steam.*" },
	tag = "-default-opacity",
	opacity = "1 1",
})

hl.window_rule({
	match = { class = "steam", title = "Friends List" },
	size = { 460, 800 },
})

-- Packet Tracer: every window shares one class, so float them all (device
-- config windows, dialogs) and tile only the main window, told apart by title.
hl.window_rule({
	match = { class = "PacketTracer" },
	float = true,
	center = true,
	tag = "+packet-tracer-device",
})

hl.window_rule({
	match = { class = "PacketTracer", title = "^Cisco Packet Tracer" },
	float = false,
	tile = true,
})

-- Device windows are titled with the bare device name; the main window and
-- dialogs ("Confirm Delete -- Cisco Packet Tracer") keep their own size.
hl.window_rule({
	match = { class = "PacketTracer", title = ".*Cisco Packet Tracer.*" },
	tag = "-packet-tracer-device",
})

hl.window_rule({
	match = { tag = "packet-tracer-device" },
	size = { 900, 700 },
})

-- Tag terminals so themes, bindings and other rules can single them out.
-- The class is matched in full, so foot's other app-id needs spelling out.
hl.window_rule({
	match = { class = "(Alacritty|kitty|foot|org\\.codeberg\\.dnkl\\.foot)" },
	tag = "+terminal",
})

-- Floating windows.
hl.window_rule({
	match = { tag = "floating-window" },
	float = true,
})

hl.window_rule({
	match = { tag = "floating-window" },
	center = true,
})

hl.window_rule({
	match = { tag = "floating-window" },
	size = { 875, 600 },
})

hl.window_rule({
	match = {
		class = "(org.omarchy.btop|org.omarchy.terminal|org.omarchy.bash|org.codeberg.dnkl.foot|org.gnome.NautilusPreviewer|org.gnome.Evince|Omarchy|About|TUI.float|imv|mpv)",
	},
	tag = "+floating-window",
})

-- Quickshell's calculator (SUPER+CTRL+Q): floats, centered, at its own size, opaque.
hl.window_rule({
	match = { class = "^org\\.quickshell$", title = "^Calculator$" },
	float = true,
	center = true,
	tag = "-default-opacity",
})

-- The portal only ever shows dialogs: file pickers, screen shares, permission
-- prompts, so every one of its windows belongs in the floating treatment,
-- whatever the app that asked for it titled it.
hl.window_rule({
	match = { class = "xdg-desktop-portal-gtk" },
	tag = "+floating-window",
})

hl.window_rule({
	match = {
		class = "(sublime_text|DesktopEditors|org.gnome.Nautilus)",
		title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
	},
	tag = "+floating-window",
})

-- No transparency on media windows.
hl.window_rule({
	match = {
		class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
	},
	tag = "-default-opacity",
})

hl.window_rule({
	match = {
		class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
	},
	opacity = "1 1",
})

-- Popped window rounding.
hl.window_rule({
	match = { tag = "pop" },
	rounding = 8,
})

-- Prevent idle while open.
hl.window_rule({
	match = { tag = "noidle" },
	idle_inhibit = "always",
})
