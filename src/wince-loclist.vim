" Wince Reference Definition for Loclist subwin
let s:Log = jer_log#LogFunctions('wince-loclist-subwin')
" TODO: Figure out why sometimes the syntax highlighting doesn't get applied

" This helper is used in the help uberwin
function! LoclistFieldForStatusline(fieldname)
    call s:Log.DBG('LoclistFieldForStatusline')
    return jer_util#SanitizeForStatusLine('', getloclist(win_getid(),{a:fieldname:0})[a:fieldname])
endfunction

if !exists('g:wince_enable_loclist') || !g:wince_enable_loclist
    call s:Log.CFG('Loclist subwin disabled')
    finish
endif

" WinceToIdentifyLoclist relies on getwininfo, and also on getloclist with the
" winid key. So Vim-native winids are required. I see no other way to implement
" WinceToIdentifyLoclist.
if jer_win#Legacy()
    call s:Log.ERR('The loclist subwin group is not supported with legacy winids')
    finish
endif

if !exists('g:wince_loclist_top')
    let g:wince_loclist_top = 0
endif

if !exists('g:wince_loclist_height')
    let g:wince_loclist_height = 10
endif

if !exists('g:wince_loclist_statusline')
    let g:wince_loclist_statusline = '%!WinceLoclistStatusLine()'
endif

" Callback that opens the location window for the current window
function! WinceToOpenLoclist()
    call s:Log.INF('WinceToOpenLoclist')
    let supwinid = win_getid()

    " Fail if the location window is already open
    let locwinid = get(getloclist(supwinid, {'winid':0}), 'winid', -1)
    if locwinid
        throw 'Window ' . supwinid . ' already has location window ' . locwinid
    endif

    " Before opening the location window, make sure there's enough room. We
    " need at least 12 rows - 10 for the loclist content, one for the supwin
    " statusline, and one for the supwin.
    if winheight(0) <# 12
        throw 'Not enough room'
    endif

    " Open the location window
    if g:wince_loclist_top
        execute 'noautocmd aboveleft lopen ' . g:wince_loclist_height
    else
        execute 'noautocmd belowright lopen ' . g:wince_loclist_height
    endif

    let &syntax = 'qf'

    " lopen also moves the cursor to the location window, so return the
    " current window ID
    let locwinid = win_getid()

    " Go back to the supwin
    noautocmd call win_gotoid(supwinid)

    return [locwinid]
endfunction

" Callback that closes the location list for the current window
function! WinceToCloseLoclist()
    call s:Log.INF('WinceToCloseLoclist')
    let supwinid = win_getid()

    " Fail if the location window is already closed
    let locwinid = get(getloclist(supwinid, {'winid':0}), 'winid', -1)
    if !locwinid
        throw 'Location window for window ' . supwinid . ' does not exist'
    endif

    " lclose fails if the location window is the last window, so use :quit
    " instead
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
        return
    endif

    " When closing the location list, we want its supwin to fill the
    " space left. If there is also a supwin on the other side of the loclist
    " window, Vim may choose to fill the space with that one instead. Setting
    " splitbelow causes Vim to always pick the supwin above via some undocumented
    " behaviour. Conversely, resetting splitbelow causes Vim to always pick
    " the supwin below.
    let oldsb = &splitbelow
    if g:wince_loclist_top
        let &splitbelow = 0
    else
        let &splitbelow = 1
    endif

    " Close the location window
    lclose

    " Restore splitbelow
    let &splitbelow = oldsb
endfunction

" Callback that returns {'typename':'loclist','supwin':<id>} if the supplied
" winid is for a location window that is not the location window of a help
" window
function! WinceToIdentifyLoclist(winid)
    call s:Log.DBG('WinceToIdentifyLoclist ', a:winid)
    if getwininfo(a:winid)[0]['loclist']
        for winnr in range(1,winnr('$'))
            if winnr != win_id2win(a:winid) &&
           \   get(getloclist(winnr, {'winid':0}), 'winid', -1) == a:winid &&
           \   getwinvar(winnr, '&ft', '') !=? 'help'
                return {'typename':'loclist','supwin':win_getid(winnr)}
            endif
        endfor
        return {'typename':'loclist','supwin':-1}
    endif
    return {}
endfunction

" Returns the statusline of the location window
function! WinceLoclistStatusLine()
    call s:Log.DBG('LoclistStatusLine')
    let statusline = ''

    " 'Loclist' string
    let statusline .= '%2*[Loclist]'

    " Start truncating
    let statusline .= '%<'

    " Location list number
    let statusline .= '%1*[%{LoclistFieldForStatusline("title")}]'

    " Location list title (from the command that generated the list)
    let statusline .= '%1*[%{LoclistFieldForStatusline("nr")}]'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Column][Current line/Total lines][% of buffer]
    let statusline .= '%2*[%c][%l/%L][%p%%]'

    return statusline
endfunction

" The location window is a subwin
call WinceAddSubwinGroupType('loclist', ['loclist'],
                          \[g:wince_loclist_statusline],
                          \'L', 'l', 2,
                          \50, [0], [1], !g:wince_loclist_top,
                          \[-1], [g:wince_loclist_height],
                          \function('WinceToOpenLoclist'),
                          \function('WinceToCloseLoclist'),
                          \function('WinceToIdentifyLoclist'))

" For each supwin, make sure the loclist subwin exists if and only if that
" supwin has a location list
function! UpdateLoclistSubwins()
    call s:Log.DBG('UpdateLoclistSubwins')
    for supwinid in WinceModelSupwinIds()
        let locwinexists = WinceModelSubwinGroupExists(supwinid, 'loclist')
        let loclistexists = len(getloclist(supwinid))

        if locwinexists && !loclistexists
            call s:Log.INF('Remove loclist subwin from supwin ', supwinid, ' because it has no location list')
            call WinceRemoveSubwinGroup(supwinid, 'loclist')
            continue
        endif

        if !locwinexists && loclistexists
            call s:Log.INF('Add loclist subwin to supwin ', supwinid, ' because it has a location list')
            call WinceAddSubwinGroup(supwinid, 'loclist', 0, 0)
            continue
        endif
    endfor
endfunction

" Update the loclist subwins after each resolver run, when the state and
" model are certain to be consistent
if !exists('g:wince_loclist_chc')
    let g:wince_loclist_chc = 1
    call jer_chc#Register(function('UpdateLoclistSubwins'), [], 1, 20, 1, 0, 1)
    call WinceAddPostUserOperationCallback(function('UpdateLoclistSubwins'))
endif

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateLoclistSubwins.
if exists('g:wince_disable_loclist_mappings') && g:wince_disable_loclist_mappings
    call s:Log.CFG('Loclist uberwin mappings disabled')
else
    call WinceMappingMapUserOp('<leader>ls', 'call WinceShowSubwinGroup(win_getid(), "loclist", 1)')
    call WinceMappingMapUserOp('<leader>lh', 'call WinceHideSubwinGroup(win_getid(), "loclist")')
    call WinceMappingMapUserOp('<leader>ll', 'let g:wince_map_mode = WinceGotoSubwin(win_getid(), "loclist", "loclist", g:wince_map_mode, 1)')
    call WinceMappingMapUserOp('<leader>lc', 'lexpr [] \| call UpdateLoclistSubwins()')
endif
