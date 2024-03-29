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
    let statusline =''

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

    " Subwin flags. Skip if wince isn't installed (yet)
    if exists('g:wince_version')
        let statusline .= wince_user#SubwinFlagsForGlobalStatusline()
    endif

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

augroup StatusLine
    autocmd!
    " Apply the command-line window's statusline on entering
    autocmd CmdWinEnter * let &l:statusline = '%!GetCmdwinStatusLine()'
augroup END

" Always show the status line
set laststatus=2

" The default status line is the value of the global statusline option
set statusline=%!GetDefaultStatusLine()
