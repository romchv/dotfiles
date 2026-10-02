-- Window, workspace, group and monitor bindings.
-- Expects mainMod to be defined beforehand.

local function bind(keys, description, dispatcher, options)
	local opts = options or {}
	opts.description = description
	hl.bind(keys, dispatcher, opts)
end

bind(mainMod .. " + W", "Close window", hl.dsp.window.close())
bind(
	"CTRL + ALT + DELETE",
	"Close all windows",
	hl.dsp.exec_cmd(
		"hyprctl clients -j | jq -r '.[].address' | while read -r addr; do "
			.. 'hyprctl dispatch "hl.dsp.window.close({ window = \\"address:$addr\\" })" >/dev/null 2>&1'
			.. ' || hyprctl dispatch closewindow "address:$addr"; done'
	)
)

bind(mainMod .. " + J", "Toggle window split", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + P", "Pseudo window", hl.dsp.window.pseudo())
bind(mainMod .. " + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(mainMod .. " + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))

bind(mainMod .. " + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
bind(mainMod .. " + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
bind(mainMod .. " + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
bind(mainMod .. " + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

-- code:10..19 are the number row keys 1..0, independent of keyboard layout.
for workspace = 1, 10 do
	local key = "code:" .. tostring(workspace + 9)
	bind(
		mainMod .. " + " .. key,
		"Switch to workspace " .. workspace,
		hl.dsp.focus({ workspace = tostring(workspace) })
	)
	bind(
		mainMod .. " + SHIFT + " .. key,
		"Move window to workspace " .. workspace,
		hl.dsp.window.move({ workspace = tostring(workspace) })
	)
	bind(
		mainMod .. " + SHIFT + ALT + " .. key,
		"Move window silently to workspace " .. workspace,
		hl.dsp.window.move({ workspace = tostring(workspace), follow = false })
	)
end

bind(mainMod .. " + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
bind(
	mainMod .. " + ALT + S",
	"Move window to scratchpad",
	hl.dsp.window.move({ workspace = "special:scratchpad", follow = false })
)

bind(mainMod .. " + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

bind(mainMod .. " + SHIFT + ALT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
bind(mainMod .. " + SHIFT + ALT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
bind(mainMod .. " + SHIFT + ALT + UP", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
bind(mainMod .. " + SHIFT + ALT + DOWN", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

bind(mainMod .. " + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
bind(mainMod .. " + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
bind(mainMod .. " + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
bind(mainMod .. " + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
bind("ALT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
bind("ALT + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
bind("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

-- code:20 / code:21 are the "-" and "=" keys.
bind(mainMod .. " + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
bind(mainMod .. " + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
bind(mainMod .. " + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
bind(mainMod .. " + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

bind(
	mainMod .. " + ALT + code:20",
	"Expand window left a little",
	hl.dsp.window.resize({ x = -25, y = 0, relative = true })
)
bind(
	mainMod .. " + ALT + code:21",
	"Shrink window left a little",
	hl.dsp.window.resize({ x = 25, y = 0, relative = true })
)
bind(
	mainMod .. " + SHIFT + ALT + code:20",
	"Shrink window up a little",
	hl.dsp.window.resize({ x = 0, y = -25, relative = true })
)
bind(
	mainMod .. " + SHIFT + ALT + code:21",
	"Expand window down a little",
	hl.dsp.window.resize({ x = 0, y = 25, relative = true })
)

bind(
	mainMod .. " + CTRL + code:20",
	"Expand window left a lot",
	hl.dsp.window.resize({ x = -300, y = 0, relative = true })
)
bind(
	mainMod .. " + CTRL + code:21",
	"Shrink window left a lot",
	hl.dsp.window.resize({ x = 300, y = 0, relative = true })
)
bind(
	mainMod .. " + CTRL + SHIFT + code:20",
	"Shrink window up a lot",
	hl.dsp.window.resize({ x = 0, y = -300, relative = true })
)
bind(
	mainMod .. " + CTRL + SHIFT + code:21",
	"Expand window down a lot",
	hl.dsp.window.resize({ x = 0, y = 300, relative = true })
)

bind(mainMod .. " + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))

bind(mainMod .. " + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

bind(mainMod .. " + G", "Toggle window grouping", hl.dsp.group.toggle())
bind(mainMod .. " + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))

bind(mainMod .. " + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
bind(mainMod .. " + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
bind(mainMod .. " + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
bind(mainMod .. " + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))

bind(mainMod .. " + ALT + TAB", "Next window in group", hl.dsp.group.next())
bind(mainMod .. " + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())

bind(mainMod .. " + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
bind(mainMod .. " + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

bind(mainMod .. " + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
bind(mainMod .. " + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())

for index = 1, 5 do
	bind(
		mainMod .. " + ALT + code:" .. tostring(index + 9),
		"Switch to group window " .. index,
		hl.dsp.group.active({ index = index })
	)
end

-- Not ported (Omarchy-only): tiled full screen (SUPER+CTRL+F), pop window out (SUPER+O),
-- save/restore window width (SUPER+ALT+Home / SUPER+Home), workspace layout toggle (SUPER+L),
-- monitor scaling up/down (SUPER+SLASH / SUPER+ALT+SLASH).
