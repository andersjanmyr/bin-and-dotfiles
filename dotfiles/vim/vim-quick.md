mA                  Store location in reg A
`A                  Jump to A
``                  Goto last jump
`.                  Goto last change

qa                  New macro into a
qA                  Append to macro a
:< >@a              Execute macro a on each line

ciw Ctrl-R 0        Replace word with yank register
daw                 Delete word
:t                  Copy a line

&                   Repeat last substitution.
g&                  Repeat substitution across all lines

@:                  Rerun last command
Ctrl-R Ctrl-W       Word under cursor
Ctrl-R /            Last search term
Ctrl-R =            Calculate register

