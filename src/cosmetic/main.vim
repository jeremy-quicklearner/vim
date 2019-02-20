" Cosmetic adjustments

" Terminal colours
set t_Co=8
set t_Sb=[4%dm
set t_Sf=[3%dm

" For code, colour columns 80 and 81
" TODO: Clean this up
" TODO: Don't colour the columns in quickfix windows
augroup ColumnLimit
    autocmd!
    highlight ColorColumn ctermfg=White ctermbg=Green
    autocmd BufReadPost,BufNewFile *.vim,*.h,*.c,*.cpp,*.py,*.sh let &colorcolumn="81,82"
augroup END

" Syntax highlighting
syntax enable
source <sfile>:p:h/textcolour.vim

" Window stuff
source <sfile>:p:h/window.vim

" Context-sensitive stuff
source <sfile>:p:h/contextcolour.vim

" Line numbers
augroup LineNumbers
    autocmd!
    autocmd BufWinEnter * set number
    autocmd BufWinEnter * set numberwidth=4
augroup END

" Highlight search results everywhere
set hlsearch
set incsearch

