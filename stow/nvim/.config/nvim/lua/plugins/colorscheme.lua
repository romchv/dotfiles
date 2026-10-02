-- Colorscheme comes from theme-switch (~/.config/themes). The current theme's
-- neovim.lua returns { src, version?, name?, colorscheme, setup? }; it is
-- reloaded whenever theme-switch writes a new one.
local dir = vim.fn.expand("~/.local/state/theme/current")

local function apply()
	local ok, theme = pcall(dofile, dir .. "/neovim.lua")
	if not ok or type(theme) ~= "table" then
		vim.cmd("colorscheme habamax")
		return
	end

	local mode = "dark"
	local f = io.open(dir .. "/colors.toml")
	if f then
		mode = f:read("*a"):match('mode%s*=%s*"(%a+)"') or mode
		f:close()
	end
	vim.o.background = mode

	vim.pack.add({ { src = theme.src, name = theme.name, version = theme.version } }, { confirm = false })
	vim.cmd("highlight clear")
	if theme.setup then
		theme.setup()
	end
	vim.cmd.colorscheme(theme.colorscheme)
end

apply()

local timer = vim.uv.new_timer()
local watcher = vim.uv.new_fs_event()
if watcher then
	watcher:start(dir, {}, function(_, file)
		if file == "neovim.lua" then
			timer:start(100, 0, vim.schedule_wrap(apply))
		end
	end)
end
