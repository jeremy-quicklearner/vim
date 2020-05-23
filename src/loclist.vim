" Location list and location window manipulation

" Callback that opens the location window for the current window
function! ToOpenLoclist()
    let supwinnr = winnr()
    let supwinid = win_getid()

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
    lopen

    " lopen also moves the cursor to the location window, so return the
    " current window ID
    return [win_getid()]
endfunction

" Callback that closes the location list for the current window
function! ToCloseLoclist()
    let supwinnr = winnr()
    let supwinid = win_getid()

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
    " space
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
    if getwininfo(a:winid)[0]['loclist']
        for winnr in range(1,winnr('$'))
            if winnr != win_id2win(a:winid) &&
           \   get(getloclist(winnr, {'winid':0}), 'winid', -1) == a:winid
                return {'typename':'loclist','supwin':win_getid(winnr)}
            endif
        endfor
        return {'typename':'loclist','supwin':-1}
    endif
    return {}
endfunction

function! LoclistFieldForStatusline(fieldname)
    return SanitizeForStatusLine('', getloclist(win_getid(),{a:fieldname:0})[a:fieldname])
endfunction

" Returns the statusline of the location window
function! LoclistStatusLine()
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
    for supwinid in WinModelSupwinIds()
        let locwinexists = WinModelSubwinGroupExists(supwinid, 'loclist')
        let loclistexists = len(getloclist(supwinid))

        if locwinexists && !loclistexists
            call WinRemoveSubwinGroup(supwinid, 'loclist')
            continue
        endif

        if !locwinexists && loclistexists
            call WinAddSubwinGroup(supwinid, 'loclist', 0)
            continue
        endif
    endfor
endfunction

" Update the loclist subwins when new supwins are added
call WinAddSupwinsAddedResolveCallback(function('UpdateLoclistSubwins'))

" Update the loclist subwins whenever a loclist is changed
augroup Loclist
    autocmd!
    autocmd QuickFixCmdPost * call UpdateLoclistSubwins()
augroup END

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateLoclistSubwins.
nnoremap <silent> <leader>lc :lexpr []<cr>
nnoremap <silent> <leader>ls :call WinShowSubwinGroup(win_getid(), 'loclist')<cr>
nnoremap <silent> <leader>lh :call WinHideSubwinGroup(win_getid(), 'loclist')<cr>
nnoremap <silent> <leader>ll :call WinGotoSubwin(win_getid(), 'loclist', 'loclist')<cr>
