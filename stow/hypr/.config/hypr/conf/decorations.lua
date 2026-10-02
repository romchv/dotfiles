local active_border_color = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
local inactive_border_color = "rgba(595959aa)"

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,

		col = {
			active_border = active_border_color,
			inactive_border = inactive_border_color,
		},

		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 0,

		shadow = {
			enabled = false,
		},

		blur = {
			enabled = false,
		},
	},

	group = {
		col = {
			border_active = active_border_color,
			border_inactive = inactive_border_color,
		},

		groupbar = {
			font_size = 12,
			font_family = "monospace",
			font_weight_active = "ultraheavy",
			font_weight_inactive = "normal",
			indicator_height = 1,
			indicator_gap = 5,
			height = 22,
			gaps_in = 5,
			gaps_out = 0,
			text_color = "rgb(ffffff)",
			text_color_inactive = "rgba(ffffff90)",
			col = {
				active = "rgba(00000040)",
				inactive = "rgba(00000020)",
			},
			gradients = true,
			gradient_rounding = 0,
			gradient_round_only_edges = false,
		},
	},
})
