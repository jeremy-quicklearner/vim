" Statusline definition

" Setup the status line
" This function operates on one window because indicator flags like [L] only
" appear in some windows
function! SetStatusLine()
    " Always show the status line
    setlocal laststatus=2

    set statusline=""
    " Buffer type
    execute('setlocal statusline+=%3*\%y')
    " Buffer state
    execute('setlocal statusline+=%4*%r')
    execute('setlocal statusline+=%4*%m%<')
    " Buffer number
    execute('setlocal statusline+=%1*[%n]')
    " Filename
    execute('setlocal statusline+=%1*[%f]\ ')
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

" Setup the status line for every window
augroup StatusLine
    autocmd!
    autocmd VimEnter,BufWinEnter,TerminalOpen,QuickFixCmdPost * call SetStatusLine()

    " Also use the statusline for netrw windows
    autocmd FileType netrw call SetStatusLine()
augroup END

