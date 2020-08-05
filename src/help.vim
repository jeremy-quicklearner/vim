" Help window manipulation

" The help uberwin is intended to only ever be opened by native commands like
" help and helpgrep - no user operations. Therefore the window engine code
" interacts with it only via the resolver and ToOpenHelp only ever gets called
" when the resolver closes and reopens the window. So the implementation of
" ToOpenHelp assumes that ToCloseHelp has recently been called.
" TODO: Add a default behaviour that just opens the help
call SetLogLevel('help-uberwin', 'info', 'warning')

augroup HelpUberwin
    autocmd!
    autocmd VimEnter, TabNew * let t:j_help = {}
augroup END

" Callback that opens the help window
function! ToOpenHelp()
    call EchomLog('help-uberwin', 'info', 'ToOpenHelp')
    if empty(t:j_help)
       throw 'Help window has not been closed yet'
    endif

    for winid in WinStateGetWinidsByCurrentTab()
        " This check is intentionally case-insensitive
        if getwinvar(Win_id2win(winid), '&ft', '') == 'help'
            throw 'Help window already open'
        endif
    endfor

    let prevwinid = Win_getid_cur()
    noautocmd vertical botright 89 split
    noautocmd silent execute 'buffer ' . t:j_help.bufnr
    let winid = Win_getid_cur()
    call WinStatePostCloseAndReopen(winid, t:j_help)
    let &winfixwidth = 1

    noautocmd call Win_gotoid(prevwinid)

    return [winid]
endfunction

" Callback that closes the help window
function! ToCloseHelp()
    call EchomLog('help-uberwin', 'info', 'ToCloseHelp')
    let helpwinid = 0
    for winid in WinStateGetWinidsByCurrentTab()
        if getwinvar(Win_id2win(winid), '&ft', '') == 'help'
            let helpwinid = winid
        endif
    endfor

    if !helpwinid
        throw 'Help window is not open'
    endif

    let t:j_help = WinStatePreCloseAndReopen(helpwinid)
    let t:j_help.bufnr = winbufnr(Win_id2win(helpwinid))

    " helpclose fails if the help window is the last window, so use :quit
    " instead
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
        return
    endif

    helpclose
endfunction

" Callback that returns 'help' if the supplied winid is for the help window
function! ToIdentifyHelp(winid)
    call EchomLog('help-uberwin', 'debug', 'ToIdentifyHelp ', a:winid)
    if getwinvar(Win_id2win(a:winid), '&ft', '') == 'help'
        return 'help'
    endif
    return ''
endfunction

function! HelpStatusLine()
    call EchomLog('help-uberwin', 'debug', 'HelpStatusLine')
    let statusline = ''

    " 'Help' string
    let statusline .= '%4*[Help]'

    " Start truncating
    let statusline .= '%<'

    " Buffer number
    let statusline .= '%1*[%n]'

    " Filename
    let statusline .= '%1*[%f]'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Column][Current line/Total lines][% of buffer]
    let statusline .= '%4*[%c][%l/%L][%p%%]'

    return statusline
endfunction

" The help window is an uberwin
call WinAddUberwinGroupType('help', ['help'],
                           \['%!HelpStatusLine()'],
                           \'H', 'h', 4,
                           \40,
                           \[89], [-1],
                           \function('ToOpenHelp'),
                           \function('ToCloseHelp'),
                           \function('ToIdentifyHelp'))

" Mappings
nnoremap <silent> <leader>hc :call WinRemoveUberwinGroup('help')<cr>
nnoremap <silent> <leader>hs :call WinShowUberwinGroup('help')<cr>
nnoremap <silent> <leader>hh :call WinGotoUberwin('help','help')<cr>
