" Wince Reference Definition for Help uberwin
let s:Log = jer_log#LogFunctions('wince-help-uberwin')
let s:Win = jer_win#WinFunctions()
" TODO: Figure out why lhelpgrep sometimes resizes a bunch of windows

if !exists('g:wince_enable_help') || !g:wince_enable_help
    call s:Log.CFG('Help uberwin disabled')
    finish
endif

" WinceToIdentifyLocHelp relies on getwininfo, and also on getloclist with the
" winid key. So Vim-native winids are required. I see no other way to
" implement WinceToIdentifyLocHelp.
if s:Win.legacy
    call s:Log.ERR('The lochelp uberwin group is not supported with legacy winids')
endif

if !exists('g:wince_help_left')
    let g:wince_help_left = 0
endif

if !exists('g:wince_help_statusline')
    let g:wince_help_statusline = '%!WinceHelpStatusLine()'
endif

if !exists('g:wince_helploc_statusline')
    let g:wince_helploc_statusline = '%!WinceHelpLocStatusLine()'
endif

if !exists('g:wince_help_width')
    let g:wince_help_width = 89
endif

" Callback that opens the help window without a location list
function! WinceToOpenHelp()
    call s:Log.INF('WinceToOpenHelp')
    for winid in WinceStateGetWinidsByCurrentTab()
        if getwinvar(s:Win.id2win(winid), '&ft', '') ==? 'help'
            throw 'Help window already open'
        endif
    endfor

    let prevwinid = s:Win.getid()

    if !exists('t:j_help')
        call s:Log.DBG('Help window has not been closed yet')
        " noautocmd is intentionally left out here so that syntax highlighting
        " is applied
        if g:wince_help_left
            silent vertical topleft help
        else
            silent vertical botright help
        endif
        0goto
    else
        if g:wince_help_left
            noautocmd vertical topleft split
        else
            noautocmd vertical botright split
        endif
    endif

    let &l:scrollbind = 0
    let &l:cursorbind = 0
    execute 'noautocmd vertical resize ' . g:wince_help_width
    let winid = s:Win.getid()

    if exists('t:j_help')
        silent execute 'buffer ' . t:j_help.bufnr
        call WinceStatePostCloseAndReopen(winid, t:j_help)
    endif

    let &winfixwidth = 1

    noautocmd call s:Win.gotoid(prevwinid)

    return [winid]
endfunction

if !s:Win.legacy
    " Callback that opens the help window with a location list
    function! WinceToOpenLocHelp()
        call s:Log.INF('WinceToOpenLocHelp')
        if !exists('t:j_help') || !has_key(t:j_help, 'loclist')
            throw 'No location list for help window'
        endif
        let helpwinid = WinceToOpenHelp()[0]
        call setloclist(helpwinid, t:j_help.loclist.list)
        call setloclist(helpwinid, [], 'a', t:j_help.loclist.what)
        
        let curwinid = s:Win.getid()
        noautocmd call s:Win.gotoid(helpwinid)
        noautocmd lopen
        let &syntax = 'qf'
        let locwinid = s:Win.getid()
        noautocmd call win_gotoid(curwinid)
        
        return [helpwinid, locwinid]
    endfunction
endif

" Callback that closes the help window
function! WinceToCloseHelp()
    call s:Log.INF('WinceToCloseHelp')
    let helpwinid = 0
    for winid in WinceStateGetWinidsByCurrentTab()
        if getwinvar(s:Win.id2win(winid), '&ft', '') ==? 'help'
            let helpwinid = winid
        endif
    endfor

    if !helpwinid
        throw 'Help window is not open'
    endif

    let t:j_help = WinceStatePreCloseAndReopen(helpwinid)
    let t:j_help.bufnr = winbufnr(s:Win.id2win(helpwinid))

    " helpclose fails if the help window is the last window, so use :quit
    " instead
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
        return
    endif

    helpclose
endfunction

if !s:Win.legacy
    " Callback that closes the help window with a location list
    function! WinceToCloseLocHelp()
        call s:Log.INF('WinceToCloseLocHelp')
        let helpwinid = 0
        for winid in WinceStateGetWinidsByCurrentTab()
            if getwinvar(s:Win.id2win(winid), '&ft', '') ==? 'help'
                let helpwinid = winid
            endif
        endfor
        if !helpwinid
            throw 'Help window is not open'
        endif

        if WinceToIdentifyLocHelp(helpwinid) != 'help'
            throw 'Help window has no location list'
        endif

        let loclist = {'list':getloclist(helpwinid)}
        let loclist.what = getloclist(helpwinid, {'changedtick':0,'context':0,'efm':'','idx':0,'title':''})

        let curwinid = s:Win.getid()
        noautocmd call s:Win.gotoid(helpwinid)
        noautocmd lclose
        noautocmd call win_gotoid(curwinid)

        call WinceToCloseHelp()
        let t:j_help.loclist = loclist
    endfunction
endif

" Callback that returns 'help' if the supplied winid is for the help window
" and has no location list
function! WinceToIdentifyHelp(winid)
    call s:Log.DBG('WinceToIdentifyHelp ', a:winid)
    if getwinvar(s:Win.id2win(a:winid), '&ft', '') ==? 'help' &&
   \   get(getloclist(a:winid, {'size':0}), 'size', 0) == 0
        return 'help'
    endif
    return ''
endfunction

if !s:Win.legacy
    " Callback that returns 'help' if the supplied winid is for the help window
    " and has a location list, or 'loclist' if the supplied winid is for the
    " location window of a help window
    function! WinceToIdentifyLocHelp(winid)
        call s:Log.INF('WinceToIdentifyLocHelp ', a:winid)
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

function! WinceHelpStatusLine()
    call s:Log.DBG('HelpStatusLine')
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

function! WinceHelpLocStatusLine()
    call s:Log.DBG('HelpLocStatusLine')
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
call WinceAddUberwinGroupType('help', ['help'],
                           \[g:wince_help_statusline],
                           \'H', 'h', 4,
                           \40, [0],
                           \[g:wince_help_width], [-1],
                           \function('WinceToOpenHelp'),
                           \function('WinceToCloseHelp'),
                           \function('WinceToIdentifyHelp'))

if !s:Win.legacy
    " The lochelp uberwin has a lower priority value than the help uberwin
    " because we want the Resolver to call its ToIdentify callback first
    call WinceAddUberwinGroupType('lochelp', ['help', 'loclist'],
                               \[g:wince_help_statusline, g:wince_helploc_statusline],
                               \'HL', 'hl', 4,
                               \39, [1, 1],
                               \[g:wince_help_width, g:wince_help_width], [-1, 10],
                               \function('WinceToOpenLocHelp'),
                               \function('WinceToCloseLocHelp'),
                               \function('WinceToIdentifyLocHelp'))

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
        call s:Log.INF('ResolveLocHelpWindows')
        for winid in WinceStateGetWinidsByCurrentTab()
            if getwinvar(winid, '&ft', '') !=? 'help'
                continue
            endif

            let haslist = get(getloclist(winid, {'size':0}), 'size', 0) != 0
            let haswin = get(getloclist(winid, {'winid':-1}), 'winid', -1) != 0

            if haslist && !haswin
                let curwinid = s:Win.getid()
                noautocmd call s:Win.gotoid(winid)
                noautocmd lopen
                let &syntax = 'qf'
                noautocmd call win_gotoid(curwinid)
            elseif !haslist && haswin
                let curwinid = s:Win.getid()
                noautocmd call s:Win.gotoid(winid)
                noautocmd lclose
                noautocmd call win_gotoid(curwinid)
            endif

            " There can only be one help window onscreen. Don't bother with
            " the other windows
            break
        endfor
    endfunction
    call jer_chc#Register(function('ResolveLocHelpWindows'), [], 0, -50, 1, 0, 1)

    " Disallow help and lochelp uberwin groups from existing simultaneously in
    " the model
    function! MutexHelpUberwins()
        call s:Log.INF('MutexHelpUberwins')
        let helpexists = WinceModelUberwinGroupExists('help')
        let lochelpexists = WinceModelUberwinGroupExists('lochelp')

        if !helpexists || !lochelpexists
            return
        endif

        call s:Log.DBG('Help and Lochelp both present')
        let helphidden =  WinceModelUberwinGroupIsHidden('help')
        let lochelphidden =  WinceModelUberwinGroupIsHidden('lochelp')

        if helphidden && !lochelphidden
            call s:Log.DBG('Only Help is hidden. Removing')
            call WinceRemoveUberwinGroup('help')
            return
        elseif !helphidden && lochelphidden
            call s:Log.DBG('Only Lochelp is hidden. Removing')
            call WinceRemoveUberwinGroup('lochelp')
            return
        endif

        if has_key(t:j_help, 'loclist')
            call s:Log.DBG('Both hidden and loclist exists. Removing Help')
            call WinceRemoveUberwinGroup('help')
        else
            call s:Log.DBG('Both hidden and no loclist. Removing Lochelp')
            call WinceRemoveUberwinGroup('lochelp')
        endif
    endfunction
    call jer_chc#Register(function('MutexHelpUberwins'), [], 0, 30, 1, 0, 1)
endif

augroup WinceHelp
    autocmd!
    autocmd VimEnter, TabNew * let t:j_help = {}
augroup END

" Mappings
if s:Win.legacy
    if exists('g:wince_disable_help_mappings') && g:wince_disable_help_mappings
        call s:Log.CFG('Help uberwin mappings disabled')
    else
        call WinceMappingMapUserOp('<leader>hs', 'call WinceAddOrShowUberwinGroup("help")')
        call WinceMappingMapUserOp('<leader>hc', 'call WinceHideUberwinGroup("help")')
        call WinceMappingMapUserOp('<leader>hh', 'let g:wince_map_mode = WinceAddOrGotoUberwin("help","help",g:wince_map_mode)')
    endif
else
    function! WinceAddOrShowHelp()
        call s:Log.INF('WinceAddOrShowHelp')
        if exists('t:j_help') && has_key(t:j_help, 'loclist')
            call WinceAddOrShowUberwinGroup('lochelp')
        else
            call WinceAddOrShowUberwinGroup('help')
        endif
    endfunction
    function! WinceHideHelp()
        call s:Log.INF('WinceHideHelp')
        if WinceModelUberwinGroupExists('lochelp')
            call WinceHideUberwinGroup('lochelp')
        else
            call WinceHideUberwinGroup('help')
        endif
    endfunction
    function! WinceAddOrGotoHelp(startmode)
        call s:Log.INF('WinceAddOrGotoHelp ', a:startmode)
        if WinceModelUberwinGroupExists('lochelp')
            return WinceAddOrGotoUberwin('lochelp', 'help', a:startmode)
        else
            return WinceAddOrGotoUberwin('help', 'help', a:startmode)
        endif
        return a:startmode
    endfunction
    function! WinceAddOrGotoHelpLoc(startmode)
        call s:Log.INF('WinceAddOrGotoHelpLoc')
        if exists('t:j_help') && has_key(t:j_help, 'loclist')
            return WinceAddOrGotoUberwin('lochelp', 'loclist', a:startmode)
        endif
        return a:startmode
    endfunction
    if exists('g:wince_disable_help_mappings') && g:wince_disable_help_mappings
        call s:Log.CFG('Help uberwin mappings disabled')
    else
        call WinceMappingMapUserOp('<leader>hs', 'call WinceAddOrShowHelp()')
        call WinceMappingMapUserOp('<leader>hc', 'call WinceHideHelp()')
        call WinceMappingMapUserOp('<leader>hh', 'let g:wince_map_mode = WinceAddOrGotoHelp(g:wince_map_mode)')
        call WinceMappingMapUserOp('<leader>hl', 'let g:wince_map_mode = WinceAddOrGotoHelpLoc(g:wince_map_mode)')
    endif
endif
