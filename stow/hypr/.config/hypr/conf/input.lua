hl.config({
	input = {
		kb_layout = "us,us",
		kb_variant = ",intl",
		kb_model = "",
		-- kb_options = "grp:alt_shift_toggle,caps:escape",
		kb_options = "grp:caps:escape",
		kb_rules = "",

		follow_mouse = 1,
		sensitivity = 0,

		repeat_rate = 40,
		repeat_delay = 250,
		numlock_by_default = true,

		touchpad = {
			natural_scroll = false,
			clickfinger_behavior = true,
			scroll_factor = 0.4,
		},
	},

	misc = {
		key_press_enables_dpms = true,
		mouse_move_enables_dpms = true,
	},
})

hl.window_rule({
	name = "terminal-scroll",
	match = { class = "(Alacritty|kitty|foot)" },
	scroll_touchpad = 1.5,
})
