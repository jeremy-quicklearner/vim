" Window-related cosmetic changes

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

