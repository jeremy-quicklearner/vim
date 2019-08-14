" Cosmetic adjustments

" For code, colour columns
augroup ColumnLimit
    autocmd!
    execute "autocmd FileType " . g:jeremyColouredColumnFileTypes .
        \ " setlocal colorcolumn=" .
        \ g:jeremyColouredColumns
augroup END

" Setup the status line
function! SetStatusLine()
    " Always show the status line
    setlocal laststatus=2
    set statusline=""
    " Buffer type
    execute('setlocal statusline+=%3*\%y')
    " Buffer state
    execute('setlocal statusline+=%4*%r')
    execute('setlocal statusline+=%4*%m%<')
    " Filename
    execute('setlocal statusline+=%1*\ %f\ ')
    " Argument status
    execute('setlocal statusline+=%4*%a%1*')
    " Long space
    setlocal statusline+=%=

    " If the location list for this window is populated, indicate it
    if len(getloclist(0)) && &ft !=# 'qf'
        execute('setlocal statusline+=%2*[L]')
    endif

    " Current line / Total lines (% of file)
    execute('setlocal statusline+=%3*[%c]')
    setlocal statusline+=[%l/%L][%p%%]
endfunction

" Setup the status line
augroup StatusLine
    autocmd!
    autocmd VimEnter,BufWinEnter,TerminalOpen,QuickFixCmdPost * call SetStatusLine()

    " Also use the statusline for netrw windows
    autocmd FileType netrw call SetStatusLine()
augroup END

" Indicate the active window
augroup ActiveWindow
    autocmd!

    " Relative numbers
    autocmd WinEnter * set relativenumber
    autocmd WinLeave * set norelativenumber
    autocmd VimEnter * setlocal relativenumber

    " No cursor line
    autocmd WinEnter * set nocursorline
    autocmd WinLeave * set cursorline
augroup END

" Line numbers
augroup LineNumbers
    autocmd BufWinEnter * set number
    autocmd BufWinEnter * set numberwidth=1

" Show the sign column only if there are signs
set signcolumn=auto

" Highlight search results everywhere
set hlsearch
set incsearch

" Use my colour scheme
colorscheme jeremy
