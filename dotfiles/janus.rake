# Copy this file to .janus.rake and use it to specify additional vim bundles 
# that should be installed when running rake.

# e.g.
vim_plugin_task "vim-repeat", "git://github.com/tpope/vim-repeat.git"
vim_plugin_task "vim-matchit", "git://github.com/tsaleh/vim-matchit.git"
vim_plugin_task "vim-textobj-user", "git://github.com/kana/vim-textobj-user.git"
vim_plugin_task "vim-textobj-rubyblock", "git://github.com/nelstrom/vim-textobj-rubyblock.git"
vim_plugin_task "vim-ragtag", "git://github.com/tpope/vim-ragtag.git"
vim_plugin_task "git-grep-vim", "git://github.com/tjennings/git-grep-vim.git"
#  vim_plugin_task "vim-yankring", "git://github.com/chrismetcalf/vim-yankring.git"
vim_plugin_task "vim-tabular", "https://github.com/godlygeek/tabular.git"
# vim_plugin_task "scratch", "http://www.vim.org/scripts/download_script.php?src_id=2050", :plugin
skip_vim_plugin "hammer"
vim_plugin_task "vim-markdown-preview", "git://github.com/nelstrom/vim-markdown-preview.git"
skip_vim_plugin "snipmate"
vim_plugin_task "anders-snipmate", "git://github.com/andersjanmyr/snipmate.vim.git"

