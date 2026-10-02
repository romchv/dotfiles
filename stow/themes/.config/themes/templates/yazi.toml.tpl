# Only the UI chrome is set here; everything else (file types, icons) comes
# from yazi's preset, which uses the terminal's ANSI palette from foot.

[mgr]
cwd             = { fg = "{{ accent }}" }
find_keyword    = { fg = "{{ yellow }}", bold = true, italic = true, underline = true }
find_position   = { fg = "{{ magenta }}", bg = "reset", bold = true, italic = true }
marker_copied   = { fg = "{{ green }}", bg = "{{ green }}" }
marker_cut      = { fg = "{{ red }}", bg = "{{ red }}" }
marker_marked   = { fg = "{{ cyan }}", bg = "{{ cyan }}" }
marker_selected = { fg = "{{ accent }}", bg = "{{ accent }}" }
count_copied    = { fg = "{{ background }}", bg = "{{ green }}" }
count_cut       = { fg = "{{ background }}", bg = "{{ red }}" }
count_selected  = { fg = "{{ background }}", bg = "{{ accent }}" }
border_style    = { fg = "{{ muted }}" }

[indicator]
parent  = { fg = "{{ foreground }}", bg = "{{ selection }}" }
current = { fg = "{{ bright_foreground }}", bg = "{{ selection }}", bold = true }
preview = { underline = true }

[tabs]
active   = { fg = "{{ background }}", bg = "{{ accent }}", bold = true }
inactive = { fg = "{{ accent }}", bg = "{{ lighter_background }}" }

[mode]
normal_main = { fg = "{{ background }}", bg = "{{ accent }}", bold = true }
normal_alt  = { fg = "{{ accent }}", bg = "{{ lighter_background }}" }
select_main = { fg = "{{ background }}", bg = "{{ magenta }}", bold = true }
select_alt  = { fg = "{{ magenta }}", bg = "{{ lighter_background }}" }
unset_main  = { fg = "{{ background }}", bg = "{{ red }}", bold = true }
unset_alt   = { fg = "{{ red }}", bg = "{{ lighter_background }}" }

[status]
perm_sep        = { fg = "{{ muted }}" }
perm_type       = { fg = "{{ green }}" }
perm_read       = { fg = "{{ yellow }}" }
perm_write      = { fg = "{{ red }}" }
perm_exec       = { fg = "{{ cyan }}" }
progress_label  = { fg = "{{ foreground }}", bold = true }
progress_normal = { fg = "{{ accent }}", bg = "{{ lighter_background }}" }
progress_error  = { fg = "{{ red }}", bg = "{{ lighter_background }}" }

[which]
cand            = { fg = "{{ accent }}" }
rest            = { fg = "{{ muted }}" }
desc            = { fg = "{{ magenta }}" }
separator_style = { fg = "{{ muted }}" }
border          = { fg = "{{ accent }}" }

[confirm]
border = { fg = "{{ accent }}" }
title  = { fg = "{{ accent }}" }

[spot]
border   = { fg = "{{ accent }}" }
title    = { fg = "{{ accent }}" }
tbl_col  = { fg = "{{ accent }}" }
tbl_cell = { fg = "{{ yellow }}", reversed = true }

[notify]
title_info  = { fg = "{{ green }}" }
title_warn  = { fg = "{{ yellow }}" }
title_error = { fg = "{{ red }}" }

[pick]
border = { fg = "{{ accent }}" }
active = { fg = "{{ magenta }}", bold = true }

[input]
border = { fg = "{{ accent }}" }

[cmp]
border = { fg = "{{ accent }}" }

[tasks]
border  = { fg = "{{ accent }}" }
hovered = { fg = "{{ magenta }}", bold = true }

[help]
border  = { fg = "{{ accent }}" }
chord   = { fg = "{{ cyan }}" }
hovered = { fg = "{{ bright_foreground }}", bg = "{{ selection }}", bold = true }
