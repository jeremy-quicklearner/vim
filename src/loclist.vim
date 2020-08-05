" Location list and location window manipulation
call SetLogLevel('loclist-subwin', 'info', 'warning')

" ToIdentifyLoclist relies on getwininfo, and also on getloclist with the
" winid key. So Vim-native winids are required.. I see no other way to implement
" ToIdentifyLoclist.
if g:legacywinid
    call EchomLog('loclist-subwin', 'error', 'The loclist subwin group is not supported for Vim versions older than 8.0')
    finish
endif

" Callback that opens the location window for the current window
function! ToOpenLoclist()
    call EchomLog('loclist-subwin', 'info', 'ToOpenLoclist')
    let supwinnr = winnr()
    let supwinid = Win_getid_cur()

    " Fail if the location window is already open
    let locwinid = get(getloclist(supwinnr, {'winid':0}), 'winid', -1)
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
    let locwinid = Win_getid_cur()

    " Go back to the supwin
    noautocmd call Win_gotoid(supwinid)

    return [locwinid]
endfunction

" Callback that closes the location list for the current window
function! ToCloseLoclist()
    call EchomLog('loclist-subwin', 'info', 'ToCloseLoclist')
    let supwinnr = winnr()
    let supwinid = Win_getid_cur()

    " Fail if the location window is already closed
    let locwinid = get(getloclist(supwinnr, {'winid':0}), 'winid', -1)
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
" winid is for a location window
function! ToIdentifyLoclist(winid)
    call EchomLog('loclist-subwin', 'debug', 'ToIdentifyLoclist ', a:winid)
    if getwininfo(a:winid)[0]['loclist']
        for winnr in range(1,winnr('$'))
            if winnr != Win_id2win(a:winid) &&
           \   get(getloclist(winnr, {'winid':0}), 'winid', -1) == a:winid
                return {'typename':'loclist','supwin':Win_getid(winnr)}
            endif
        endfor
        return {'typename':'loclist','supwin':-1}
    endif
    return {}
endfunction

function! LoclistFieldForStatusline(fieldname)
    call EchomLog('loclist-subwin', 'debug', 'LoclistFieldForStatusline')
    return SanitizeForStatusLine('', getloclist(winnr(),{a:fieldname:0})[a:fieldname])
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
        let loclistexists = len(getloclist(Win_id2win(supwinid)))

        if locwinexists && !loclistexists
            call EchomLog('loclist-subwin', 'info', 'Remove loclist subwin from supwin ', supwinid, ' because it has no location list')
            call WinRemoveSubwinGroup(supwinid, 'loclist')
            continue
        endif

        if !locwinexists && loclistexists
            call EchomLog('loclist-subwin', 'info', 'Add loclist subwin to supwin ', supwinid, ' because it has a location list')
            call WinAddSubwinGroup(supwinid, 'loclist', 0)
            continue
        endif
    endfor
endfunction

" Update the loclist subwins after each resolver run, when the state and
" model are certain to be consistent
if !exists('g:j_loclist_chc')
    let g:j_loclist_chc = 1
    call RegisterCursorHoldCallback(function('UpdateLoclistSubwins'), [], 1, 20, 1, 1)
endif

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateLoclistSubwins.
nnoremap <silent> <leader>lc :lexpr []<cr>
nnoremap <silent> <leader>ls :call WinShowSubwinGroup(Win_getid_cur(), 'loclist')<cr>
nnoremap <silent> <leader>lh :call WinHideSubwinGroup(Win_getid_cur(), 'loclist')<cr>
nnoremap <silent> <leader>ll :call WinGotoSubwin(Win_getid_cur(), 'loclist', 'loclist')<cr>
