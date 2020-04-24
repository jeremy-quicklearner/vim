" Statusline definition

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

" Set the status line for a supwin
function! SetDefaultStatusLine()
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

" The window engine dictates that some windows have non-default status lines.
" It defers to the default by returning an empty string that won't supersede
" the global default statusline
function! SetSpecificStatusLine()
    execute 'setlocal statusline=' . WinNonDefaultStatusLine()
endfunction

function! CorrectAllStatusLines(arg)
    call WinDo('call SetSpecificStatusLine()', '')
endfunction

" Register the above function to be called on the next CursorHold event
function! RegisterCorrectStatusLines()
    call RegisterCursorHoldCallback(function('CorrectAllStatusLines'), "", 0, 1, 0)
endfunction

augroup StatusLine
    autocmd!
    " Quickfix and Terminal windows have different statuslines that Vim sets
    " when they open or buffers enter them, so overwrite all non-default
    " statuslines after that happens
    autocmd BufWinEnter,TerminalOpen * call RegisterCorrectStatusLines()

    " Netrw windows also have local statuslines that get set by some autocmd
    " someplace. Overwrite them as well.
    autocmd FileType netrw call RegisterCorrectStatusLines()
augroup END

" The default status line is the value of the global statusline option
call SetDefaultStatusLine()
