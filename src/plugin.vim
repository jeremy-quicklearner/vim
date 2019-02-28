" Plugin management

" External stuff directory
let s:vimDir = expand('<sfile>:p:h:h')
let s:extDir = s:vimDir . '/ext'
let s:plugScriptName = s:extDir . '/autoload/plug.vim'

" Make sure Vim-Plug is installed
" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
if empty(glob(s:extDir . '/autoload/plug.vim'))
    execute 'silent !curl -fLo ' . s:plugScriptName . ' --create-dirs ' .
        \ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

" Install any missing plugins
" https://github.com/junegunn/vim-plug/wiki/extra#automatically-install-missing-plugins-on-startup
autocmd VimEnter *
    \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
    \|     PlugInstall --sync
    \| endif

" Load plugins
call plug#begin()
Plug 'justinmk/vim-syntax-extra'
call plug#end()
