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
Plug 'benknoble/vim-auto-origami', {'on': 'AutoOrigamiFoldColumn'}
Plug 'mbbill/undotree', {'on': 'UndotreeShow'}
Plug 'jeremy-quicklearner/vim-sign-utils', {'on': ['PlaceUtilSigns', 'UnplaceUtilSigns']}
call plug#end()

" Netrw stuff
" Vertically open windows on the right
let g:netrw_altv=1
let g:netrw_preview=1
" Buffer settings: nu and rnu mean numbers and relative numbers
let g:netrw_bufsettings="noma nomod nu rnu nobl nowrap ro"
" Tree view
let g:netrw_liststyle=3

" Auto Origami stuff
let g:auto_origami_foldcolumn=1
augroup AutoOrigami
    autocmd!
    autocmd CursorHold,BufWinEnter,WinEnter *
                \  if &buftype !=# 'terminal'
                \|     execute('AutoOrigamiFoldColumn')
                \| endif
augroup END

" Vim Sign Utils stuff
" Place a sign on the current line
nnoremap <silent> <leader>sr :PlaceUtilSigns Red<cr>
nnoremap <silent> <leader>sg :PlaceUtilSigns Green<cr>
nnoremap <silent> <leader>sy :PlaceUtilSigns Yellow<cr>
nnoremap <silent> <leader>sb :PlaceUtilSigns Blue<cr>
nnoremap <silent> <leader>sm :PlaceUtilSigns Magenta<cr>
nnoremap <silent> <leader>sc :PlaceUtilSigns Cyan<cr>
nnoremap <silent> <leader>sw :PlaceUtilSigns White<cr>
" Place signs on highlighted lines
vnoremap <silent> <leader>sr :PlaceUtilSigns Red<cr>
vnoremap <silent> <leader>sg :PlaceUtilSigns Green<cr>
vnoremap <silent> <leader>sy :PlaceUtilSigns Yellow<cr>
vnoremap <silent> <leader>sb :PlaceUtilSigns Blue<cr>
vnoremap <silent> <leader>sm :PlaceUtilSigns Magenta<cr>
vnoremap <silent> <leader>sc :PlaceUtilSigns Cyan<cr>
vnoremap <silent> <leader>sw :PlaceUtilSigns White<cr>
" Remove signs from the current line
nnoremap <silent> <leader>S :UnplaceUtilSigns<cr>
" Remove signs from highlighted lines
vnoremap <silent> <leader>S :UnplaceUtilSigns<cr>
