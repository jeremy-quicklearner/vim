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
function! GetDefaultStatusLine()
    let statusline=''

    " Buffer type
    let statusline .= '%3*%y'

    " Buffer state
    let statusline .= '%4*%r'
    let statusline .= '%4*%m'

    " Start truncating
    let statusline .= '%<'

    " Buffer number
    let statusline .= '%1*[%n]'

    " Filename
    let statusline .= '%1*[%f]'

    " Argument status
    let statusline .= '%5*%a' . SpaceIfArgs() . '%1*'

    " Right-justify from now on
    let statusline .= '%=%<'

    " Subwin flags
    let statusline .= WinceSubwinFlags()

    " Diff flag
    let statusline .= '%6*' . DiffFlag()

    " [Column][Current line/Total lines][% of file]
    let statusline .= '%3*[%c][%l/%L][%p%%]'

    return statusline
endfunction

function! GetCmdwinStatusLine()
    let statusline = ''

    " 'Preview' string
    let statusline .= '%7*[Command-Line]'

    " Start truncating
    let statusline .= '%<'

    " Buffer number
    let statusline .= '%1*[%n]'

    " Reminder
    let statusline .= '[<cr> to execute][<C-c> to cancel]'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Column][Current line/Total lines][% of buffer]
    let statusline .= '%7*[%c][%l/%L][%p%%]'

    return statusline
endfunction


" The window engine dictates that some windows have non-default status lines.
" It defers to the default by returning an empty string that won't supersede
" the global default statusline
function! SetSpecificStatusLine()
    execute 'let &l:statusline = "' . WinceNonDefaultStatusLine() . '"'
endfunction

function! CorrectAllStatusLines()
    let currwin=winnr()
    windo call SetSpecificStatusLine()
    execute currwin . 'wincmd w'
endfunction

" Register the above function to be called on the next CursorHold event
function! RegisterCorrectStatusLines()
    call jer_chc#Register(function('CorrectAllStatusLines'), [], 0, 1, 0, 0, 0)
endfunction

augroup StatusLine
    autocmd!
    " Quickfix and Terminal windows have different statuslines that Vim sets
    " when they open or buffers enter them, so overwrite all non-default
    " statuslines after that happens
    autocmd BufWinEnter,TerminalOpen * call RegisterCorrectStatusLines()

    " Apply the command-line window's statusline on entering
    autocmd CmdWinEnter * let &l:statusline = '%!GetCmdwinStatusLine()'

    " Netrw windows also have local statuslines that get set by some autocmd
    " someplace. Overwrite them as well.
    autocmd FileType netrw call RegisterCorrectStatusLines()
augroup END

" Always show the status line
set laststatus=2

" The default status line is the value of the global statusline option
set statusline=%!GetDefaultStatusLine()
