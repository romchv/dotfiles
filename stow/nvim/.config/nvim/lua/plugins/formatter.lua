require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		json = { "fixjson" },
		markdown = { "markdownlint-cli2" },
		shell = { "shfmt" },
	},

	-- Optional: format on save (very common)
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback", -- use LSP formatter first if available, then conform
	},

	default_format_opts = {
		lsp_format = "fallback",
	},
})

-- Manual format keymap (nice to have)
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
