return {
  src = "https://github.com/omacom-io/aether.nvim",
  version = "v3",
  name = "aether",
  colorscheme = "aether",
  setup = function()
    require("aether").setup({
      colors = {
        bg = "{{ background }}",
        dark_bg = "{{ dark_background }}",
        darker_bg = "{{ darker_background }}",
        lighter_bg = "{{ lighter_background }}",

        fg = "{{ foreground }}",
        dark_fg = "{{ dark_foreground }}",
        light_fg = "{{ light_foreground }}",
        bright_fg = "{{ bright_foreground }}",
        muted = "{{ muted }}",

        red = "{{ red }}",
        yellow = "{{ yellow }}",
        orange = "{{ orange }}",
        green = "{{ green }}",
        cyan = "{{ cyan }}",
        blue = "{{ blue }}",
        purple = "{{ purple }}",
        brown = "{{ brown }}",

        bright_red = "{{ bright_red }}",
        bright_yellow = "{{ bright_yellow }}",
        bright_green = "{{ bright_green }}",
        bright_cyan = "{{ bright_cyan }}",
        bright_blue = "{{ bright_blue }}",
        bright_purple = "{{ bright_purple }}",

        accent = "{{ accent }}",
        cursor = "{{ bright_foreground }}",
        foreground = "{{ foreground }}",
        background = "{{ background }}",
        selection = "{{ selection }}",
        selection_foreground = "{{ selection_foreground }}",
        selection_background = "{{ selection_background }}",
      },
    })
  end,
}
