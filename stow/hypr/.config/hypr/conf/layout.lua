hl.config({
	dwindle = {
		preserve_split = true,
		force_split = 2,
	},

	scrolling = {
		column_width = 0.49,
	},

	master = {
		new_status = "master",
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		disable_scale_notification = true,
		focus_on_activate = true,
		anr_missed_pings = 3,
		on_focus_under_fullscreen = 1,
		initial_workspace_tracking = 0,
		-- Let a fresh shell re-acquire the session lock after the lock client
		-- died, so omarchy-restart-shell can recover the LOCK failsafe.
		allow_session_lock_restore = true,
	},

	cursor = {
		hide_on_key_press = true,
		warp_on_change_workspace = 1,
	},

	binds = {
		hide_special_on_workspace_change = true,
	},
})
