" Statusline definition
" TODO: Figure out why SetStatusLine sometimes doesn't run after WinResolve
"   - Maybe SetStatusLine's priority is higher than WinResolve's?

" Convert a window-local variable to a string based on a map lookup
" If the variable doesn't exist in the window, return dne
" If the value of the variable isn't in the map, return the value directly
" This function used to be used for location list flags, which are now
" subwin-based. Maybe I'll use it for something else later
function! WinVarAsFlag(name, dne, map)
    if !exists('w:' . a:name)
        return a:dne
    else
        let val = eval('w:' . a:name)
        return get(a:map, val, val)
    endif
endfunction

" Get the diff flag for the current window
function! DiffFlag()
    if &diff
        return '[DIF]'
    else
        return ''
    endif
endfunction

function! SpaceIfArgs()
    if argc() > 1
        return ' '
    else
        return ''
    endif
endfunction

function! SetStatusLine()
    " Always show the status line
    set laststatus=2

    set statusline=

    " Buffer type
    set statusline+=%3*%y

    " Buffer state
    set statusline+=%4*%r
    set statusline+=%4*%m

    " Start truncating
    set statusline+=%<

    " Buffer number
    set statusline+=%1*[%n]

    " Filename
    set statusline+=%1*[%f]

    " Argument status
    set statusline+=%5*%a%{SpaceIfArgs()}%1*

    " Right-justify from now on
    set statusline+=%=%<

    " Subwin flags
    execute 'set statusline+=' . WinSubwinFlags()

    " Diff flag
    set statusline+=%6*%{DiffFlag()}

    " [Column][Current line/Total lines][% of file]
    set statusline+=%3*[%c][%l/%L][%p%%]
endfunction

function! CorrectStatusLine(arg)
    " Don't let Vim override the statusline locally
    call WinDo('setlocal statusline=', '')
endfunction
    

" Register the above function to be called on the next CursorHold event
function! RegisterCorrectStatusLine()
    call RegisterCursorHoldCallback(function('CorrectStatusLine'), "", 0, 1, 0)
endfunction

augroup StatusLine
    autocmd!
    " Set the status line on entering Vim
    autocmd VimEnter * call SetStatusLine()
    " Quickfix and Terminal windows have different statuslines that Vim sets
    " when they open or buffers enter them, so overwrite the statusline
    " after that happens
    autocmd BufWinEnter,TerminalOpen * call RegisterCorrectStatusLine()

    " Also use the statusline for netrw windows
    autocmd FileType netrw call RegisterCorrectStatusLine()
augroup END
