return {
  src = "https://github.com/yonatanperel/lake-dweller.nvim",
  colorscheme = "lake-dweller",
  setup = function()
    require("lake-dweller").setup({ variant = "pond-dweller" })
  end,
}
