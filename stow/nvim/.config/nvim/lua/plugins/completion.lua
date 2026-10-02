require("luasnip.loaders.from_vscode").lazy_load()
require("blink.cmp").setup({
	keymap = {
		preset = "default",
		["<Tab>"] = false,
		["S-Tab"] = false,
		["<C-f>"] = { "snippet_forward", "scroll_documentation_down", "fallback" },
		["<C-b>"] = { "snippet_backward", "scroll_documentation_up", "fallback" },
	},
	signature = {
		enabled = true,
	},
	appearance = {
		nerd_font_variant = "mono",
	},
	completion = {
		documentation = { auto_show = false },
		menu = {
			border = "rounded",
			enabled = true,
			auto_show = true,
			draw = {
				treesitter = { "lsp" },
				columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
			},
		},
	},
	snippets = { preset = "luasnip" },
	sources = { default = { "lsp", "path", "snippets", "buffer" } },

	fuzzy = {
		implementation = "prefer_rust_with_warning",
		prebuilt_binaries = { download = true },
	},
})

require("luasnip").filetype_extend("typescriptreact", { "javascriptreact" })
