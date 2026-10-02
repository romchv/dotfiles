require("nvim-treesitter").setup({
	-- Directory to install parsers and queries to (prepended to `runtimepath` to have priority)
	install_dir = vim.fn.stdpath("data") .. "/site",
})
local ts = require("nvim-treesitter")

-- Install parsers (replace with your list; call once or on-demand)
ts.install({
	"lua",
	"vim",
	"vimdoc",
	"query",
	"python",
	"javascript",
	"typescript",
	"jsx",
	"tsx",
	"html",
	"css",
	"json",
	"yaml",
	"markdown",
	"markdown_inline",
	"bash",
	"diff",
	"gitattributes",
	"gitcommit",
	"gitignore",
	"dockerfile",
	"styled",
	"rust",
	"c",
	"qmljs",
}, { summary = false }):wait(30000) -- Wait up to 30s; adjust as needed

-- Autocmd to enable features on FileType
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_features", { clear = true }),
	pattern = {
		"lua",
		"vim",
		"vimdoc",
		"query",
		"python",
		"javascript",
		"typescript",
		"tsx",
		"jsx",
		"html",
		"css",
		"json",
		"yaml",
		"markdown",
		"markdown_inline",
		"bash",
		"diff",
		"gitattributes",
		"gitcommit",
		"gitignore",
		"dockerfile",
		"styled",
		"rust",
		"c",
		"qmljs",
	},
	callback = function()
		vim.treesitter.start()
		vim.bo.indentexpr = 'v:lua.require"nvim-treesitter".indent()' -- Enables indent
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "*" },
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
