" Help window manipulation

call SetLogLevel('help-uberwin', 'warning', 'warning')

" ToIdentifyLocHelp relies on getwininfo, and also on getloclist with the
" winid key. So Vim-native winids are required. I see no other way to
" implement ToIdentifyLocHelp.
if g:legacywinid
    call EchomLog('help-uberwin', 'error', 'The lochelp uberwin group is not supported for Vim versions older than 8.0')
endif

" Callback that opens the help window without a location list
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
        0goto
    else
        noautocmd vertical botright split
    endif

    let &l:scrollbind = 0
    let &l:cursorbind = 0
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

if !g:legacywinid
    " Callback that opens the help window with a location list
    function! ToOpenLocHelp()
        call EchomLog('help-uberwin', 'info', 'ToOpenLocHelp')
        if !exists('t:j_help') || !has_key(t:j_help, 'loclist')
            throw 'No location list for help window'
        endif
        let helpwinid = ToOpenHelp()[0]
        call setloclist(helpwinid, t:j_help.loclist)
        
        let curwinid = Win_getid_cur()
        noautocmd call Win_gotoid(helpwinid)
        noautocmd lopen
        let &syntax = 'qf'
        let locwinid = Win_getid_cur()
        noautocmd call win_gotoid(curwinid)
        
        return [helpwinid, locwinid]
    endfunction
endif

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

if !g:legacywinid
    " Callback that closes the help window with a location list
    function! ToCloseLocHelp()
        call EchomLog('help-uberwin', 'info', 'ToCloseLocHelp')
        let helpwinid = 0
        for winid in WinStateGetWinidsByCurrentTab()
            if getwinvar(Win_id2win(winid), '&ft', '') ==? 'help'
                let helpwinid = winid
            endif
        endfor
        if !helpwinid
            throw 'Help window is not open'
        endif

        if ToIdentifyLocHelp(helpwinid) != 'help'
            throw 'Help window has no location list'
        endif

        " TODO: also preserve the {what} items
        let loclist = getloclist(helpwinid)

        let curwinid = Win_getid_cur()
        noautocmd call Win_gotoid(helpwinid)
        noautocmd lclose
        noautocmd call win_gotoid(curwinid)

        call ToCloseHelp()
        let t:j_help.loclist = loclist
    endfunction
endif

" Callback that returns 'help' if the supplied winid is for the help window
" and has no location list
function! ToIdentifyHelp(winid)
    call EchomLog('help-uberwin', 'debug', 'ToIdentifyHelp ', a:winid)
    if getwinvar(Win_id2win(a:winid), '&ft', '') ==? 'help' &&
   \   get(getloclist(a:winid, {'size':0}), 'size', 0) == 0
        return 'help'
    endif
    return ''
endfunction

if !g:legacywinid
    " Callback that returns 'help' if the supplied winid is for the help window
    " and has a location list, or 'loclist' if the supplied winid is for the
    " location window of a help window
    function! ToIdentifyLocHelp(winid)
        call EchomLog('help-uberwin', 'info', 'ToIdentifyLocHelp ', a:winid)
        if getwinvar(a:winid, '&ft', '') ==? 'help' &&
       \   get(getloclist(a:winid, {'size':0}), 'size', 0) != 0
           return 'help'
        elseif getwininfo(a:winid)[0]['loclist']
            for winnr in range(1,winnr('$'))
                if winnr != win_id2win(a:winid) &&
               \   get(getloclist(winnr, {'winid':0}), 'winid', -1) == a:winid &&
               \   getwinvar(winnr, '&ft', '') ==? 'help'
                    return 'loclist'
                endif
            endfor
        endif
        return ''
    endfunction
endif

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

function! HelpLocStatusLine()
    call EchomLog('help-uberwin', 'debug', 'HelpLocStatusLine')
    let statusline = ''

    " 'Loclist' string
    let statusline .= '%4*[Help-Loclist]'

    " Start truncating
    let statusline .= '%<'

    " Location list number
    let statusline .= '%1*[%{LoclistFieldForStatusline("title")}]'

    " Location list title (from the command that generated the list)
    let statusline .= '%1*[%{LoclistFieldForStatusline("nr")}]'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Column][Current line/Total lines][% of buffer]
    let statusline .= '%4*[%c][%l/%L][%p%%]'

    return statusline
endfunction

" There are two uberwin groups. One for the help window, and a second one for
" the help window and its location list
call WinAddUberwinGroupType('help', ['help'],
                           \['%!HelpStatusLine()'],
                           \'H', 'h', 4,
                           \40,
                           \[89], [-1],
                           \function('ToOpenHelp'),
                           \function('ToCloseHelp'),
                           \function('ToIdentifyHelp'))

if !legacywinid
    " The lochelp uberwin has a lower priority value than the help uberwin
    " because we want the Resolver to call its ToIdentify callback first
    call WinAddUberwinGroupType('lochelp', ['help', 'loclist'],
                               \['%!HelpStatusLine()', '%!HelpLocStatusLine()'],
                               \'HL', 'hl', 4,
                               \39,
                               \[89, 89], [-1, 10],
                               \function('ToOpenLocHelp'),
                               \function('ToCloseLocHelp'),
                               \function('ToIdentifyLocHelp'))

    " If there is a help window open that has a location list but not a
    " location window, then the resolver will identify it as a lochelp:help
    " window. Then it won't find any lochelp:loclist window and drop the help
    " window from the model. This is undesirable, because it causes the
    " resolver to close help windows opened with lhelpgrep as well as help
    " windows whose location windows were just closed. Therefore, we need all
    " help windows with location lists to have location windows when the
    " resolver runs.
    " Also, when the resolver stomps 
    function! ResolveLocHelpWindows()
        call EchomLog('help-uberwin', 'info', 'ResolveLocHelpWindows')
        for winid in WinStateGetWinidsByCurrentTab()
            if getwinvar(winid, '&ft', '') !=? 'help'
                continue
            endif

            let haslist = get(getloclist(winid, {'size':0}), 'size', 0) != 0
            let haswin = get(getloclist(winid, {'winid':-1}), 'winid', -1) != 0

            if haslist && !haswin
                let curwinid = Win_getid_cur()
                noautocmd call Win_gotoid(winid)
                noautocmd lopen
                let &syntax = 'qf'
                noautocmd call win_gotoid(curwinid)
            elseif !haslist && haswin
                let curwinid = Win_getid_cur()
                noautocmd call Win_gotoid(winid)
                noautocmd lclose
                noautocmd call win_gotoid(curwinid)
            endif

            " There can only be one help window onscreen. Don't bother with
            " the other windows
            break
        endfor
    endfunction
    call RegisterCursorHoldCallback(function('ResolveLocHelpWindows'), [], 0, -50, 1, 0, 1)

    " Disallow help and lochelp uberwin groups from existing simultaneously in
    " the model
    function! MutexHelpUberwins()
        call EchomLog('help-uberwin', 'info', 'MutexHelpUberwins')
        let helpexists = WinModelUberwinGroupExists('help')
        let lochelpexists = WinModelUberwinGroupExists('lochelp')

        if !helpexists || !lochelpexists
            return
        endif

        call EchomLog('help-uberwin', 'debug', 'Help and Lochelp both present')
        let helphidden =  WinModelUberwinGroupIsHidden('help')
        let lochelphidden =  WinModelUberwinGroupIsHidden('lochelp')

        if helphidden && !lochelphidden
            call EchomLog('help-uberwin', 'debug', 'Only Help is hidden. Removing')
            call WinRemoveUberwinGroup('help')
            return
        elseif !helphidden && lochelphidden
            call EchomLog('help-uberwin', 'debug', 'Only Lochelp is hidden. Removing')
            call WinRemoveUberwinGroup('lochelp')
            return
        endif

        if has_key(t:j_help, 'loclist')
            call EchomLog('help-uberwin', 'debug', 'Both hidden and loclist exists. Removing Help')
            call WinRemoveUberwinGroup('help')
        else
            call EchomLog('help-uberwin', 'debug', 'Both hidden and no loclist. Removing Lochelp')
            call WinRemoveUberwinGroup('lochelp')
        endif
    endfunction
    call RegisterCursorHoldCallback(function('MutexHelpUberwins'), [], 0, 30, 1, 0, 1)
endif

augroup HelpUberwin
    autocmd!
    autocmd VimEnter, TabNew * let t:j_help = {}
augroup END

" Mappings
if g:legacywinid
    call WinMappingMapUserOp('<leader>hs', 'call WinAddOrShowUberwinGroup("help")')
    call WinMappingMapUserOp('<leader>hc', 'call WinHideUberwinGroup("help")')
    call WinMappingMapUserOp('<leader>hh', 'call WinAddOrGotoUberwin("help","help")')
else
    function! WinAddOrShowHelp()
        call EchomLog('help-uberwin', 'info', 'WinAddOrShowHelp')
        if exists('t:j_help') && has_key(t:j_help, 'loclist')
            call WinAddOrShowUberwinGroup('lochelp')
        else
            call WinAddOrShowUberwinGroup('help')
        endif
    endfunction
    function! WinHideHelp()
        call EchomLog('help-uberwin', 'info', 'WinHideHelp')
        if WinModelUberwinGroupExists('lochelp')
            call WinHideUberwinGroup('lochelp')
        else
            call WinHideUberwinGroup('help')
        endif
    endfunction
    function! WinAddOrGotoHelp()
        call EchomLog('help-uberwin', 'info', 'WinAddOrGotoHelp')
        if WinModelUberwinGroupExists('lochelp')
            call WinAddOrGotoUberwin('lochelp', 'help')
        else
            call WinAddOrGotoUberwin('help', 'help')
        endif
    endfunction
    function! WinAddOrGotoHelpLoc()
        call EchomLog('help-uberwin', 'info', 'WinAddOrGotoHelpLoc')
        if exists('t:j_help') && has_key(t:j_help, 'loclist')
            call WinAddOrGotoUberwin('lochelp', 'loclist')
        endif
    endfunction
    call WinMappingMapUserOp('<leader>hs', 'call WinAddOrShowHelp()')
    call WinMappingMapUserOp('<leader>hc', 'call WinHideHelp()')
    call WinMappingMapUserOp('<leader>hh', 'call WinAddOrGotoHelp()')
    call WinMappingMapUserOp('<leader>hl', 'call WinAddOrGotoHelpLoc()')
endif
