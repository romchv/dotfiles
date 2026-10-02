-- Volume, brightness, keyboard backlight, and media controls.
-- Uses wpctl (PipeWire), brightnessctl and playerctl (install playerctl for media keys).

local function exec(command)
	return hl.dsp.exec_cmd(command)
end

local locked = { locked = true }
local locked_repeat = { locked = true, repeating = true }

local function with(opts, description)
	local result = { description = description }
	for key, value in pairs(opts) do
		result[key] = value
	end
	return result
end

local SINK = "@DEFAULT_AUDIO_SINK@"
local SOURCE = "@DEFAULT_AUDIO_SOURCE@"
local KBD = "brightnessctl -d '*::kbd_backlight' set "
-- Show Quickshell's brightness OSD (it ignores brightness changes it isn't told about, like hypridle's dimming).
local OSD = " && qs ipc call osd brightness"

-- Volume.
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 " .. SINK .. " 5%+"), with(locked_repeat, "Volume up"))
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume " .. SINK .. " 5%-"), with(locked_repeat, "Volume down"))
hl.bind("XF86AudioMute", exec("wpctl set-mute " .. SINK .. " toggle"), with(locked, "Mute"))
hl.bind("XF86AudioMicMute", exec("wpctl set-mute " .. SOURCE .. " toggle"), with(locked, "Mute microphone"))

-- Display brightness.
hl.bind("XF86MonBrightnessUp", exec("brightnessctl set +5%" .. OSD), with(locked_repeat, "Brightness up"))
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-" .. OSD), with(locked_repeat, "Brightness down"))
hl.bind("SHIFT + XF86MonBrightnessUp", exec("brightnessctl set 100%" .. OSD), with(locked_repeat, "Brightness maximum"))
hl.bind("SHIFT + XF86MonBrightnessDown", exec("brightnessctl set 1%" .. OSD), with(locked_repeat, "Brightness minimum"))

-- Keyboard backlight.
hl.bind("XF86KbdBrightnessUp", exec(KBD .. "+1"), with(locked_repeat, "Keyboard brightness up"))
hl.bind("XF86KbdBrightnessDown", exec(KBD .. "1-"), with(locked_repeat, "Keyboard brightness down"))

-- Precise volume and brightness controls.
hl.bind(
	"ALT + XF86AudioRaiseVolume",
	exec("wpctl set-volume -l 1 " .. SINK .. " 1%+"),
	with(locked_repeat, "Volume up precise")
)
hl.bind(
	"ALT + XF86AudioLowerVolume",
	exec("wpctl set-volume " .. SINK .. " 1%-"),
	with(locked_repeat, "Volume down precise")
)
hl.bind("ALT + XF86MonBrightnessUp", exec("brightnessctl set +1%" .. OSD), with(locked_repeat, "Brightness up precise"))
hl.bind("ALT + XF86MonBrightnessDown", exec("brightnessctl set 1%-" .. OSD), with(locked_repeat, "Brightness down precise"))

-- Media controls.
hl.bind("XF86AudioNext", exec("playerctl next"), with(locked, "Next track"))
hl.bind("ALT + XF86AudioPlay", exec("playerctl next"), with(locked, "Next track"))
hl.bind("XF86AudioPause", exec("playerctl play-pause"), with(locked, "Pause"))
hl.bind("XF86AudioPlay", exec("playerctl play-pause"), with(locked, "Play"))
hl.bind("XF86AudioPrev", exec("playerctl previous"), with(locked, "Previous track"))
hl.bind("ALT + SHIFT + XF86AudioPlay", exec("playerctl previous"), with(locked, "Previous track"))
hl.bind("XF86Eject", exec("eject"), with(locked, "Eject media"))
