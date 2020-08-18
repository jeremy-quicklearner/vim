" Help window manipulation

call SetLogLevel('help-uberwin', 'info', 'warning')

" Callback that opens the help window
function! ToOpenHelp()
    call EchomLog('help-uberwin', 'info', 'ToOpenHelp')
    for winid in WinStateGetWinidsByCurrentTab()
        if getwinvar(Win_id2win(winid), '&ft', '') ==? 'help'
            throw 'Help window already open'
        endif
    endfor

    let prevwinid = Win_getid_cur()

    if !exists('t:j_help')
        call EchomLog('help-uberwin', 'debug', 'Help window has not been closed yet')
        " noautocmd is intentionally left out here so that syntax highlighting
        " is applied
        silent vertical botright help
    else
        noautocmd vertical botright split
    endif

    let &l:scrollbind = 0
    noautocmd vertical resize 89
    let winid = Win_getid_cur()

    if exists('t:j_help')
        silent execute 'buffer ' . t:j_help.bufnr
        call WinStatePostCloseAndReopen(winid, t:j_help)
    endif

    let &winfixwidth = 1

    noautocmd call Win_gotoid(prevwinid)

    return [winid]
endfunction

" Callback that closes the help window
function! ToCloseHelp()
    call EchomLog('help-uberwin', 'info', 'ToCloseHelp')
    let helpwinid = 0
    for winid in WinStateGetWinidsByCurrentTab()
        if getwinvar(Win_id2win(winid), '&ft', '') ==? 'help'
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
    if getwinvar(Win_id2win(a:winid), '&ft', '') ==? 'help'
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

augroup HelpUberwin
    autocmd!
    autocmd VimEnter, TabNew * let t:j_help = {}
augroup END

" Mappings
nnoremap <silent> <leader>hc :call WinHideUberwinGroup('help')<cr>
nnoremap <silent> <leader>hs :call WinShowUberwinGroup('help')<cr>
nnoremap <silent> <leader>hh :call WinAddOrGotoUberwin('help','help')<cr>
