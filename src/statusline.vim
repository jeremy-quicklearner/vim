" Statusline definition

" Convert a window-local variable to a string based on a map lookup
" If the variable doesn't exist in the window, return dne
" If the value of the variable isn't in the map, return the value directly
function! WinVarAsFlag(name, dne, map)
    if !exists('w:' . a:name)
        return a:dne
    else
        let val = eval('w:' . a:name)
        return get(a:map, val, val)
    endif
endfunction

" Get the location window flag for the current window
function! LocWinFlag()
    " If there is a location list, the flag is visible
    if len(getloclist(0)) && &ft !=# 'qf'
        " The flag is [Loc] or [Hid] depending on whether the location window
        " is hidden. If it is hidden but only because a terminal is open, the
        " flag is [Ter]
        return WinVarAsFlag('locwinHidden', '', {0:'[Loc]',1:'[Hid]',2:'[Ter]'})
    else
        return ''
    endif
endfunction

function! SetStatusLine(arg)
    " Always show the status line
    set laststatus=2

    set statusline=""

    " Buffer type
    set statusline+=%3*\%y

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
    set statusline+=%5*%a\ %1*

    " Right-justify from now on
    set statusline+=%=%<

    " Location window flag
    set statusline+=%2*%{LocWinFlag()}

    " [Column][Current line/Total lines][% of file]
    set statusline+=%3*[%c][%l/%L][%p%%]

    " If statusline has a local value, it takes precedence over the global one
    " we just set. So remove it.
    call WinDo('setlocal statusline=', '')
endfunction

" Register the above function to be called on the next CursorHold event
function! RegisterSetLine()
    call RegisterCursorHoldCallback(function('SetStatusLine'), "", 0, 0, 0)
endfunction

augroup StatusLine
    autocmd!
    " Set the status line on entering Vim
    autocmd VimEnter * call SetStatusLine('')
    " Quickfix and Terminal windows have different statuslines that Vim sets
    " when they open or buffers enter them, so overwrite the statusline
    " after that happens
    autocmd BufWinEnter,TerminalOpen * call RegisterSetLine()

    " Also use the statusline for netrw windows
    autocmd FileType netrw call RegisterSetLine()
augroup END
