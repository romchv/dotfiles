return {
  src = "https://github.com/ficcdaf/ashen.nvim",
  colorscheme = "ashen",
  setup = function()
    -- Let the terminal's background show through.
    require("ashen").setup({ transparent = true })
  end,
}
