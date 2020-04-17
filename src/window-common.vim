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

" Closes all uberwins with priority higher than a given, and returns a list of
" group types closed. The model is unchanged.
function! WinCommonCloseUberwinsWithHigherPriority(priority)
    let grouptypenames = WinModelUberwinGroupTypeNamesByMinPriority(a:priority)
    for grouptypename in grouptypenames
        call WinStateCloseUberwinsByGroupType(g:uberwingrouptype[grouptypename])
    endfor
    return grouptypenames
endfunction

" Reopens uberwins that were closed by WinCommonCloseUberwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenUberwins(grouptypenames)
    for grouptypename in a:grouptypenames
        let winids = WinStateOpenUberwinsByGroupType(
       \    g:uberwingrouptype[a:grouptypename]
       \)
        call WinModelChangeUberwinIds(grouptypename, winids)

        let dims = WinStateGetWinDimensionsList(winids)
        call WinModelChangeUberwinGroupDimensions(grouptypename, dims)
    endfor
endfunction

" Closes all subwins for a given supwin with priority higher than a given, and
" returns a list of group types closed. The model is unchanged.
function! WinCommonCloseSubwinsWithHigherPriority(supwinid, priority)
    let grouptypenames = WinModelSubwinGroupTypeNamesByMinPriority(a:supwinid, a:priority)
    for grouptypename in grouptypenames
        call WinStateCloseSubwinsByGroupType(a:supwinid, g:subwingrouptype[grouptypename])
    endfor
    return grouptypenames
endfunction


" Reopens subwins that were closed by WinCommonCloseSubwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenSubwins(supwinid, grouptypenames)
    for grouptypename in a:grouptypenames
        let winids = WinStateOpenSubwinsByGroupType(
       \    a:supwinid,
       \    g:subwingrouptype[grouptypename]
       \)
        call WinModelChangeSubwinIds(a:supwinid, grouptypename, winids)

        let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
        let dims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
        call WinModelChangeSubwinGroupDimensions(a:supwinid, grouptypename, dims)
    endfor
endfunction

" Closes and reopens all shown subwins of a given supwin with priority higher
" than a given
function! WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(supwinid, priority)
    let grouptypenames = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, a:priority)
    call WinCommonReopenSubwins(a:supwinid, grouptypenames)

    let dims = WinStateGetWinDimensions(a:supwinid)
    call WinModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

" Closes and reopens all shown subwins of a given supwin
function! WinCommonCloseAndReopenAllShownSubwinsBySupwin(supwinid)
    call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(a:supwinid, -1)
endfunction

" Closes and reopens all shown subwins in the current tab
function! WinCommonCloseAndReopenAllShownSubwins()
    for supwinid in WinModelSupwinIds()
        call WinCommonCloseAndReopenAllShownSubwinsBySupwin(supwinid)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged subwins of a non-hidden subwin group
function! WinCommonAfterimageSubwinsByInfo(supwinid, grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    " Each subwin type can be individually afterimaging, so deal with them one
    " by one
    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        " Don't afterimage non-afterimaging subwins
        if !g:subwingrouptype[a:grouptypename].afterimaging[typeidx]
            continue
        endif

        " Don't afterimage subwins that are already afterimaged
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        if WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            continue
        endif

        " To make sure the subwins are in a good state, start from their supwin
        " noautocmd is used here because undotree has autocmds that fire on
        " WinLeave and close the diff window
        noautocmd call WinStateMoveCursorToWinid(a:supwinid)

        " Get the subwin ID
        let subwinid = WinModelIdByInfo({
       \    'category': 'subwin',
       \    'supwin': a:supwinid,
       \    'grouptype': a:grouptypename,
       \    'typename': typename
       \})

        " Afterimage the subwin in the state
        let aibuf = WinStateAfterimageWindow(subwinid)

        " Afterimage the subwin in the model
        call WinModelAfterimageSubwin(a:supwinid, a:grouptypename, typename, aibuf)
    endfor
endfunction

" Close and reopen all subwins in a group if any of them are afterimaged
function! WinCommonDeafterimageSubwinsByInfo(supwinid, grouptypename)
    " TODO: stub
endfunction
