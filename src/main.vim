" Entry point. setup.sh modifies ~/.vimrc by adding a direct invocation of this
" script

" Paths must come first because it influences where Vim will search for other
" scripts
source <sfile>:p:h/paths.vim

" Things that need to be done early on
source <sfile>:p:h/pre.vim

" Plugins need to be available for autoloading, so set them up first
source <sfile>:p:h/plugin.vim

" Statusline and Tabline come after the Uberwindow/Subwindow groups because
" all groups need to be registered before the default statusline (with subwin
" flags) is generated.
" Currently, Wince is source directly from plugin.vim
" TODO: Figure out a fix for this
source <sfile>:p:h/statusline.vim
source <sfile>:p:h/tabline.vim

" Broader categories of functionality get their own files
source <sfile>:p:h/cosmetic.vim
source <sfile>:p:h/formatting.vim

" Even broader categories also get their own files
source <sfile>:p:h/commands.vim
source <sfile>:p:h/mappings.vim

" Do I even need to say anything about this?
source <sfile>:p:h/miscellaneous.vim

