" Cosmetic adjustments

" For code, colour columns 80 and 81
" TODO: Clean this up
" TODO: Don't colour the columns in quickfix windows
augroup ColumnLimit
    autocmd!
    autocmd BufReadPost,BufNewFile,BufWinEnter *.vim,*.h,*.c,*.cpp,*.py,*.sh
        \ let &colorcolumn="81,82"
augroup END

" Rulers
set ruler

" Always show the status line
set laststatus=2

" Indicate the active window
augroup ActiveWindow
    autocmd!

    " Relative numbers
    highlight CursorLineNr ctermfg=White
    autocmd BufWinEnter * set relativenumber
    autocmd WinEnter * set relativenumber
    autocmd WinLeave * set norelativenumber

    " Status line colour for active window
    highlight StatusLine ctermfg=Green
    highlight StatusLineTerm ctermbg=Green ctermfg=Black
    
    " Status line colour for inactive windows
    highlight StatusLineNC ctermfg=White
    highlight StatusLineTermNC ctermbg=White ctermfg=Black

augroup END


" Line numbers
augroup LineNumbers
    autocmd!
    autocmd BufWinEnter * set number
    autocmd BufWinEnter * set numberwidth=4
augroup END

" Fold column
set foldcolumn=1

" Highlight search results everywhere
set hlsearch
set incsearch

" Use my colour scheme
colorscheme jeremy
