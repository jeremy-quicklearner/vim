" Cosmetic adjustments

" For code, colour columns
augroup ColumnLimit
    autocmd!
    execute "autocmd FileType " . g:jeremyColouredColumnFileTypes .
           \" setlocal colorcolumn=" . g:jeremyColouredColumns
augroup END

" Indicate the active window
augroup ActiveWindow
    autocmd!

    " Relative numbers
    autocmd WinEnter * set relativenumber
    autocmd WinLeave * set norelativenumber
    autocmd BufWinEnter <buffer>  set relativenumber

    " No cursor line
    autocmd WinEnter * set nocursorline
    autocmd WinLeave * set cursorline
augroup END

" Line numbers
augroup LineNumbers
    autocmd!
    autocmd BufWinEnter * set number
    autocmd BufWinEnter * set numberwidth=1
augroup END

" Show the sign column only if there are signs
set signcolumn=auto

" Highlight search results everywhere
set hlsearch
set incsearch

" Use my colour scheme
colorscheme jeremy
