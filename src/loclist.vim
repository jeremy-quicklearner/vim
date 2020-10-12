" Location list and location window manipulation
call SetLogLevel('loclist-subwin', 'warning', 'warning')

" ToIdentifyLoclist relies on getwininfo, and also on getloclist with the
" winid key. So Vim-native winids are required. I see no other way to implement
" ToIdentifyLoclist.
if g:legacywinid
    call EchomLog('loclist-subwin', 'error', 'The loclist subwin group is not supported for Vim versions older than 8.0')
    finish
endif

" Callback that opens the location window for the current window
function! ToOpenLoclist()
    call EchomLog('loclist-subwin', 'info', 'ToOpenLoclist')
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
    noautocmd lopen
    let &syntax = 'qf'

    " lopen also moves the cursor to the location window, so return the
    " current window ID
    let locwinid = win_getid()

    " Go back to the supwin
    noautocmd call win_gotoid(supwinid)

    return [locwinid]
endfunction

" Callback that closes the location list for the current window
function! ToCloseLoclist()
    call EchomLog('loclist-subwin', 'info', 'ToCloseLoclist')
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

    " When closing the location list, we want the supwin above it to fill the
    " space left. If there is also a supwin below, Vim may choose to fill the
    " space with that one instead of the one above. Setting splitbelow causes
    " Vim to always pick the supwin above via some undocumented behaviour.
    let oldsb = &splitbelow
    let &splitbelow = 1

    " Close the location window
    lclose

    " Restore splitbelow
    let &splitbelow = oldsb
endfunction

" Callback that returns {'typename':'loclist','supwin':<id>} if the supplied
" winid is for a location window that is not the location window of a help
" window
function! ToIdentifyLoclist(winid)
    call EchomLog('loclist-subwin', 'debug', 'ToIdentifyLoclist ', a:winid)
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

function! LoclistFieldForStatusline(fieldname)
    call EchomLog('loclist-subwin', 'debug', 'LoclistFieldForStatusline')
    return SanitizeForStatusLine('', getloclist(win_getid(),{a:fieldname:0})[a:fieldname])
endfunction

" Returns the statusline of the location window
function! LoclistStatusLine()
    call EchomLog('loclist-subwin', 'debug', 'LoclistStatusLine')
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
call WinAddSubwinGroupType('loclist', ['loclist'],
                          \['%!LoclistStatusLine()'],
                          \'L', 'l', 2,
                          \50, [0],
                          \[-1], [10],
                          \function('ToOpenLoclist'),
                          \function('ToCloseLoclist'),
                          \function('ToIdentifyLoclist'))

" For each supwin, make sure the loclist subwin exists if and only if that
" supwin has a location list
function! UpdateLoclistSubwins()
    call EchomLog('loclist-subwin', 'debug', 'UpdateLoclistSubwins')
    for supwinid in WinModelSupwinIds()
        let locwinexists = WinModelSubwinGroupExists(supwinid, 'loclist')
        let loclistexists = len(getloclist(supwinid))

        if locwinexists && !loclistexists
            call EchomLog('loclist-subwin', 'info', 'Remove loclist subwin from supwin ', supwinid, ' because it has no location list')
            call WinRemoveSubwinGroup(supwinid, 'loclist')
            continue
        endif

        if !locwinexists && loclistexists
            call EchomLog('loclist-subwin', 'info', 'Add loclist subwin to supwin ', supwinid, ' because it has a location list')
            call WinAddSubwinGroup(supwinid, 'loclist', 0, 0)
            continue
        endif
    endfor
endfunction

" Update the loclist subwins after each resolver run, when the state and
" model are certain to be consistent
if !exists('g:j_loclist_chc')
    let g:j_loclist_chc = 1
    call RegisterCursorHoldCallback(function('UpdateLoclistSubwins'), [], 1, 20, 1, 0, 1)
    call WinAddPostUserOperationCallback(function('UpdateLoclistSubwins'))
endif

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateLoclistSubwins.
call WinMappingMapUserOp('<leader>ls', 'call WinShowSubwinGroup(win_getid(), "loclist", 1)')
call WinMappingMapUserOp('<leader>lh', 'call WinHideSubwinGroup(win_getid(), "loclist")')
call WinMappingMapUserOp('<leader>ll', 'call WinGotoSubwin(win_getid(), "loclist", "loclist", 1)')
call WinMappingMapUserOp('<leader>lc', 'lexpr [] \| call UpdateLoclistSubwins()')
