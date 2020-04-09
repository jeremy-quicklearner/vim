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

    " Close the location window
    lclose
endfunction

" Callback that returns {'typename':'loclist','supwin':<id>} if the supplied
" winid is for a location window
function! ToIdentifyLoclist(winid)
    if getwininfo(a:winid)[0]['loclist']
        for winnr in range(1,winnr('$'))
            if winnr != win_id2win(a:winid) &&
              \get(getloclist(winnr, {'winid':0}), 'winid', -1) == a:winid
                return {'typename':'loclist', 'supwin': win_getid(winnr)}
            endif
        endfor
    endif
    return {}
endfunction

" The location window is a subwin
call WinAddSubwinGroupType('loclist', ['loclist'],
                          \'Loc', 'Hid', 2, 50, [0],
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
