" Entry point
" Paths must come first because it influences where Vim will search for other
" scripts
source <sfile>:p:h/paths.vim

" Util must be available to all of my code
source <sfile>:p:h/util.vim

" Subwindow/Uberwindow infrastructure should be available to plugins
source <sfile>:p:h/window.vim

" Anything I do should take precedence over anything a plugin does
source <sfile>:p:h/plugin.vim

" Specific categories of functionality get their own files
source <sfile>:p:h/quickfix.vim
source <sfile>:p:h/loclist.vim
" Statusline and tabline are last because they may display information from
" the others
source <sfile>:p:h/statusline.vim
source <sfile>:p:h/tabline.vim

" Broader categories get their own files
source <sfile>:p:h/cosmetic.vim
source <sfile>:p:h/formatting.vim

" Even broader categories also get their own files
source <sfile>:p:h/commands.vim
source <sfile>:p:h/mappings.vim

" Do I even need to say anything about this?
source <sfile>:p:h/miscellaneous.vim
