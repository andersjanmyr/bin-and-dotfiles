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
# skip_vim_plugin "hammer"
# vim_plugin_task "vim-markdown-preview", "git://github.com/nelstrom/vim-markdown-preview.git"
skip_vim_plugin "command_t"
skip_vim_plugin "snipmate"

vim_plugin_task "anders-snipmate", "git://github.com/andersjanmyr/snipmate.vim.git"
# vim_plugin_task "scratch", "http://www.vim.org/scripts/download_script.php?src_id=2050"
vim_plugin_task "nginx" do
  sh 'curl http://www.vim.org/scripts/download_script.php?src_id=14376 > syntax/nginx.vim'
end
vim_plugin_task 'jslint-patch' do
  sh 'curl https://raw.github.com/douglascrockford/JSLint/master/jslint.js > ftplugin/javascript/jslint/jslint-core.js'
end

vim_plugin_task 'autoclose-vim', 'git://github.com/Townk/vim-autoclose.git'

vim_plugin_task 'github-colors' do
  sh 'curl https://raw.github.com/xonecas/github-vim-colorscheme/master/github.vim> colors/github.vim'
end

vim_plugin_task 'vim-jade', 'git://github.com/digitaltoad/vim-jade.git'

vim_plugin_task 'vim-stylus', 'git://github.com/wavded/vim-stylus.git

