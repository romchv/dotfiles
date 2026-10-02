-- Pick the monitor layout for this machine: a built-in panel (eDP) means laptop.
local laptop = os.execute("ls /sys/class/drm | grep -q eDP")

if laptop == true or laptop == 0 then
	require("conf.monitors-laptop")
else
	require("conf.monitors-desktop")
end
