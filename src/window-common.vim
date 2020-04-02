" Window manipulation code common to resolve function and user operations
" See window.vim

" Returns a data structure that encodes information about the window that the
" cursor is in
function! WinCommonGetCursorWinInfo()
    return WinModelInfoById(WinStateGetCursorWinId())
endfunction

" Moves the cursor to a window remembered with WinCommonGetCursorWinInfo, if it still
" exists
function! WinCommonRestoreCursorWinInfo(info)
    let winid = WinModelIdByInfo(a:info)
    if winid > 0
        call WinStateMoveCursorToWinid(winid)
    endif
endfunction

" Closes and reopens all uberwins with priority higher than a given
function! WinCommonCloseAndReopenUberwinsWithHigherPriority(priority)
    let grouptypenames = WinModelUberwinGroupTypeNamesByMinPriority(a:priority)
    for grouptypename in grouptypenames
        call WinStateCloseUberwinsByGroupType(g:uberwingrouptype[grouptypename])
        let winids = WinStateOpenUberwinsByGroupType(
       \    g:uberwingrouptype[grouptypename]
       \)
        call WinModelChangeUberwinIds(grouptypename, winids)
    endfor
endfunction

" Closes and reopens all subwins with priority higher than a given
function! WinCommonCloseAndReopenSubwinsWithHigherPriority(supwinid, priority)
    let grouptypenames = WinModelSubwinGroupTypeNamesByMinPriority(a:supwinid, a:priority)
    for grouptypename in grouptypenames
        call WinStateCloseSubwinsByGroupType(a:supwinid, g:subwingrouptype[grouptypename])
        let winids = WinStateOpenSubwinsByGroupType(
       \    a:supwinid,
       \    g:subwingrouptype[grouptypename]
       \)
        call WinModelChangeSubwinIds(a:supwinid, grouptypename, winids)
    endfor
endfunction
