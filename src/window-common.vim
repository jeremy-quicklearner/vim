" Window manipulation code common to resolve function and user operations
" See window.vim

" Returns a data structure that encodes information about the window that the
" cursor is in
function! WinCommonGetCursorPosition()
    call EchomLog('window-common', 'debug', 'WinCommonGetCursorPosition')
    return {
   \    'win':WinModelInfoById(WinStateGetCursorWinId()),
   \    'cur':WinStateGetCursorPosition()
   \}
endfunction

" Returns true if winids listed in in the model for an uberwin group exist in
" the state
function! WinCommonUberwinGroupExistsInState(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonUberwinGroupExistsInState ' . a:grouptypename)
    let winids = WinModelUberwinIdsByGroupTypeName(a:grouptypename)
    return WinStateWinExists(winids[0])
endfunction

" Returns true if winids listed in the model for a subwin group exist in the
" state
function! WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonSubwinGroupExistsInState ' . a:supwinid . ':' . a:grouptypename)
    let winids = WinModelSubwinIdsByGroupTypeName(a:supwinid, a:grouptypename)
    return WinStateWinExists(winids[0])
endfunction

" Returns false if the dimensions in the model of any uberwin in a shown group of
" a given type are dummies or inconsistent with the state. True otherwise.

function! WinCommonUberwinGroupDimensionsMatch(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonUberwinGroupDimensionsMatch ' . a:grouptypename)
    for typename in WinModelUberwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('window-common', 'verbose', 'Check uberwin ' . a:grouptypename . ':' . typename)
        let mdims = WinModelUberwinDimensions(a:grouptypename, typename)
        if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
            call EchomLog('window-common', 'debug', 'Uberwin ' . a:grouptypename . ':' . typename . ' has dummy dimensions')
            return 0
        endif
        let winid = WinModelIdByInfo({
       \    'category':'uberwin',
       \    'grouptype':a:grouptypename,
       \    'typename':typename
       \})
        let sdims = WinStateGetWinDimensions(winid)
        if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
            call EchomLog('window-common', 'debug', 'Uberwin ' . a:grouptypename . ':' . typename . ' has inconsistent non-dummy dimensions')
            return 0
        endif
    endfor
    call EchomLog('window-common', 'debug', 'No dimensional inconsistency found for uberwin group ' . a:grouptypename)
    return 1
endfunction

" Returns false if the dimensions in the model of a given supwin are dummies
" or inconsistent with the state. True otherwise.
function! WinCommonSupwinDimensionsMatch(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonSupwinDimensionsMatch ' . a:supwinid)
    let mdims = WinModelSupwinDimensions(a:supwinid)
    if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
        call EchomLog('window-common', 'debug', 'Supwin ' . a:supwinid . ' has dummy dimensions')
        return 0
    endif
    let sdims = WinStateGetWinDimensions(a:supwinid)
    if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
        call EchomLog('window-common', 'debug', 'Supwin ' . a:supwinid . ' has inconsistent non-dummy dimensions')
        return 0
    endif
    call EchomLog('window-common', 'debug', 'No dimensional inconsistency found for supwin ' . a:supwinid)
    return 1
endfunction

" Returns false if the dimensions in the model of any subwin in a shown group of
" a given type for a given supwin are dummies or inconsistent with the state.
" True otherwise.
function! WinCommonSubwinGroupDimensionsMatch(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonSubwinGroupDimensionsMatch ' . a:supwinid . ':' . a:grouptypename)
    for typename in WinModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('window-common', 'verbose', 'Check subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename)
        let mdims = WinModelSubwinDimensions(a:supwinid, a:grouptypename, typename)
        if mdims.relnr ==# 0 || mdims.w ==# -1 || mdims.h ==# -1
            call EchomLog('window-common', 'debug', 'Subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' has dummy dimensions')
            return 0
        endif
        let winid = WinModelIdByInfo({
       \    'category':'subwin',
       \    'supwin': a:supwinid,
       \    'grouptype':a:grouptypename,
       \    'typename':typename
       \})
        let sdims = WinStateGetWinDimensions(winid)
        let snr = WinStateGetWinnrByWinid(a:supwinid)
        if sdims.nr !=# snr + mdims.relnr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
            call EchomLog('window-common', 'debug', 'Subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' has inconsistent non-dummy dimensions')
            return 0
        endif
    endfor
    call EchomLog('window-common', 'debug', 'No dimensional inconsistency found for subwin group ' . a:supwinid . ':' . a:grouptypename)
    return 1
endfunction

" Get the window ID of the topmost leftmost supwin
function! WinCommonFirstSupwinId()
    call EchomLog('window-common', 'debug', 'WinCommonFirstSupwinId')
    let minsupwinnr = 0
    let minsupwinid = 0
    for supwinid in WinModelSupwinIds()
        if !WinStateWinExists(supwinid)
            call EchomLog('window-common', 'verbose', 'Skipping non-state-present supwin ' . supwinid)
            continue
        endif
        call EchomLog('window-common', 'verbose', 'Check supwin ' . supwinid)
        let winnr = WinStateGetWinnrByWinid(supwinid)
        if minsupwinnr ==# 0 || minsupwinnr > winnr
            call EchomLog('window-common', 'verbose', 'Supwin ' . supwinid . ' has lowest winnr so far: ' . winnr)
            let minsupwinnr = winnr
            let minsupwinid = supwinid
        endif
    endfor
    call EchomLog('window-common', 'debug', 'Supwin with lowest winnr is ' . minsupwinid)
    return minsupwinid
endfunction

" Get the window ID of the first uberwin in the lowest-priority shown uberwin
" group
function! WinCommonFirstUberwinInfo()
    call EchomLog('window-common', 'debug', 'WinCommonFirstUberwinInfo')
    let grouptypenames = WinModelShownUberwinGroupTypeNames()
    if empty(grouptypenames)
        call EchomLog('window-common', 'debug', 'No uberwins are open')
        return {'category':'none','id':0}
    endif
    let grouptypename = grouptypenames[0]
    let typename = g:uberwingrouptype[grouptypename].typenames[0]
    call EchomLog('window-common', 'debug', 'Selected uberwin ' . grouptypename . ':' . typename . ' as first uberwin')
    return {
   \    'category':'uberwin',
   \    'grouptype':grouptypename,
   \    'typename':typename
   \}
endfunction

" Given a cursor position remembered with WinCommonGetCursorPosition, return
" either the same position or an updated one if it doesn't exist anymore
function! WinCommonReselectCursorWindow(oldpos)
    call EchomLog('window-common', 'debug', 'WinCommonReselectCursorWindow ' . string(a:oldpos))
    let pos = a:oldpos

    " If the cursor is in a nonexistent or hidden subwin, try to select its supwin
    if pos.category ==# 'subwin' && (
   \   !WinModelSubwinGroupExists(pos.supwin, pos.grouptype) ||
   \   WinModelSubwinGroupIsHidden(pos.supwin, pos.grouptype))
        call EchomLog('window-common', 'debug', 'Cursor is in nonexistent or hidden subwin. Attempt to select its supwin: ' . pos.supwin)
        let pos = {'category':'supwin','id':pos.supwin}
    endif

    " If all we have is a window ID, try looking it up
    if pos.category ==# 'none' || pos.category ==# 'supwin'
        call EchomLog('window-common', 'debug', 'Validate winid ' . pos.id . ' by model lookup')
        let pos = WinModelInfoById(pos.id)
    endif

    " If we still have just a window ID, or if the cursor is in a nonexistent
    " supwin, nonexistent uberwin, or hidden uberwin, try to select the first supwin
    if pos.category ==# 'none' ||
   \   (pos.category ==# 'supwin' && !WinModelSupwinExists(pos.id)) ||
   \   (pos.category ==# 'uberwin' && !WinModelUberwinGroupExists(pos.grouptype)) ||
   \   (pos.category ==# 'uberwin' && WinModelUberwinGroupIsHidden(pos.grouptype))
        call EchomLog('window-common', 'debug', 'Cursor position fallback to first supwin')
        let firstsupwinid = WinCommonFirstSupwinId()
        if firstsupwinid
            call EchomLog('window-common', 'debug', 'First supwin is ' . firstsupwinid)
            let pos = {'category':'supwin','id':firstsupwinid}
        endif
    endif

    " If we still have just a window ID, there are no supwins and therefore
    " also no subwins. Try to select the first uberwin.
    if pos.category ==# 'none' ||
   \   (pos.category ==# 'supwin' && !WinModelSupwinExists(pos.id))
        call EchomLog('window-common', 'debug', 'Cursor position fallback to first uberwin')
        let pos = WinCommonFirstUberwinInfo()
    endif

    " If we still have no window ID, then there are no windows
    if pos.category ==# 'none'
        throw "No windows exist. Cannot select a window for the cursor."
    endif

    " At this point, a window has been chosen based only on the model. But if
    " the model and state are inconsistent, the window may not be open in the
    " state.
    call EchomLog('window-common', 'debug', 'Cursor position selected based on model: ' . string(pos))
    let winexistsinstate = WinStateWinExists(WinModelIdByInfo(pos))

    " If a non-open subwin was selected, select its supwin
    if !winexistsinstate && pos.category ==# 'subwin'
        call EchomLog('window-common', 'debug', 'Cursor position is a state-closed subwin. Attempt to select its supwin: ' . pos.supwin)
        let pos = {'category':'supwin','id':pos.supwin}
        let winexistsinstate = WinStateWinExists(WinModelIdByInfo(pos))
    endif

    " If a non-open supwin was selected. select the first supwin
    if !winexistsinstate && pos.category ==# 'supwin'
        call EchomLog('window-common', 'debug', 'Cursor position is a state-closed supwin. Fallback to first supwin')
        let firstsupwinid = WinCommonFirstSupwinId()
        if firstsupwinid
            call EchomLog('window-common', 'debug', 'First supwin is ' . firstsupwinid)
            let pos = {'category':'supwin','id':firstsupwinid}
        endif
        let winexistsinstate = WinStateWinExists(WinModelIdByInfo(pos))
    endif

    " If we still haven't selected an open supwin, there are no open supwins.
    " Select the first uberwin.
    if !winexistsinstate 
        call EchomLog('window-common', 'debug', 'Cursor position fallback to first uberwin')
        let pos = WinCommonFirstUberwinInfo()
        let winexistsinstate = WinStateWinExists(WinModelIdByInfo(pos))
    endif

    " If we still have no window ID, then we're out of ideas
    if !winexistsinstate
        throw "No windows from the model are open in the state. Cannot select a window for the cursor."
    endif

    call EchomLog('window-common', 'verbose', 'Reselected cursor position ' . string(pos))
    return pos
endfunction

" Freeze the width and height of all nonsupwins. Return information about the
" frozen windows' previous settings so that they can later be thawed
function! WinCommonFreezeAllNonSupwinSizes()
    call EchomLog('window-common', 'debug', 'WinCommonFreezeAllNonSupwinSizes')
    let immunewinids = []
    for supwinid in WinModelSupwinIds()
        call EchomLog('window-common', 'verbose', 'Supwin ' . supwinid . ' is immune from freezing')
        call add(immunewinids, str2nr(supwinid))
    endfor

    let prefreeze = {}
    for winid in WinStateGetWinidsByCurrentTab()
        if index(immunewinids, str2nr(winid)) < 0
            call EchomLog('window-common', 'verbose', 'Freeze ' . winid)
            let prefreeze[winid] = WinStateFreezeWindowSize(winid)
        endif
    endfor
    
    call EchomLog('window-common', 'verbose', 'Frozen: ' . string(prefreeze))
    return prefreeze
endfunction

" Freeze the width and height of all windows except for a given supwin and its
" subwins. Return information about the frozen windows' previous settings so
" that they can later be thawed
function! WinCommonFreezeAllWindowSizesOutsideSupwin(immunesupwinid)
    call EchomLog('window-common', 'debug', 'WinCommonFreezeAllWindowSizesOutsideSupwin ' . a:immunesupwinid)
    let immunewinids = [str2nr(a:immunesupwinid)]
    for subwinid in WinModelShownSubwinIdsBySupwinId(a:immunesupwinid)
        call EchomLog('window-common', 'verbose', 'Subwin ' . subwinid . ' is immune from freezing')
        call add(immunewinids, str2nr(subwinid))
    endfor

    let prefreeze = {}
    for winid in WinStateGetWinidsByCurrentTab()
        if index(immunewinids, str2nr(winid)) < 0
            call EchomLog('window-common', 'verbose', 'Freeze ' . winid)
            let prefreeze[winid] = WinStateFreezeWindowSize(winid)
        endif
    endfor
    
    call EchomLog('window-common', 'verbose', 'Frozen: ' . string(prefreeze))
    return prefreeze
endfunction

" Thaw the height and width of all windows that were frozen with
" WinCommonFreezeAllWindowSizesOutsideSupwin() or
" WinCommonFreezeAllNonSupwinSizes()
function! WinCommonThawWindowSizes(prefreeze)
    call EchomLog('window-common', 'debug', 'WinCommonThawWindowSizes')
    for winid in keys(a:prefreeze)
        call EchomLog('window-common', 'verbose', 'Thaw ' . winid . ':' . string(a:prefreeze[winid]))
        call WinStateThawWindowSize(winid, a:prefreeze[winid])
    endfor
endfunction

" Moves the cursor to a window remembered with WinCommonGetCursorPosition. If
" the window no longer exists, go to the next best window as selected by
" WinCommonReselectCursorWindow
function! WinCommonRestoreCursorPosition(info)
    call EchomLog('window-common', 'debug', 'WinCommonRestoreCursorPosition ' . string(a:info))
    let newpos = WinCommonReselectCursorWindow(a:info.win)
    call EchomLog('window-common', 'debug', 'Reselected cursor position: ' . string(newpos))
    let winid = WinModelIdByInfo(newpos)
    call WinStateMoveCursorToWinid(winid)
    " TODO: Only do this is we didn't reselect
    call WinStateRestoreCursorPosition(a:info.cur)
endfunction

" Wrapper for WinStateCloseUberwinsByGroupType that freezes windows whose
" dimensions shouldn't change
function! WinCommonCloseUberwinsByGroupTypeName(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonCloseUberwinsByGroupTypeName ' . a:grouptypename)
    " When windows are closed, Vim needs to choose which other windows to
    " expand to fill the free space. Sometimes Vim makes choices I don't like, such
    " as expanding other uberwins. So before closing the uberwin,
    " freeze the height and width of every window outside the uberwin group
    let prefreeze = WinCommonFreezeAllNonSupwinSizes()
    try
        let grouptype = g:uberwingrouptype[a:grouptypename]
        call EchomLog('window-common', 'debug', 'State-closing uberwin group ' . a:grouptypename)
        call WinStateCloseUberwinsByGroupType(grouptype)
    finally
        call WinCommonThawWindowSizes(prefreeze)
    endtry
endfunction

" When windows are opened, Vim needs to choose which other windows to shrink
" to make room. Sometimes Vim makes choices I don't like, such as equalizing
" windows along the way. This function can be called before opening a window,
" to remember the dimensions of all the windows that are already open. The
" remembered dimensions can then be somewhat restored using
" WinCommonRestoreMaxDimensions
function! WinCommonPreserveDimensions()
    call EchomLog('window-common', 'debug', 'WinCommonPreserveDimensions')
    let winids = WinStateGetWinidsByCurrentTab()
    let dims = WinStateGetWinDimensionsList(winids)
    let windims = {}
    for idx in range(len(winids))
        let windims[winids[idx]] = dims[idx]
    endfor
    call EchomLog('window-common', 'verbose', 'Preserved dimensions: ' . string(windims))
    return windims
endfunction

" Restore dimensions remembered with WinCommonPreserveDimensions
function! WinCommonRestoreMaxDimensions(windims)
    call EchomLog('window-common', 'debug', 'WinCommonRestoreMaxDimensions')
    for winid in keys(a:windims)
        if !WinStateWinExists(winid)
            call EchomLog('window-common', 'verbose', Window ' . winid . ' no longer exists')
            continue
        endif
        call EchomLog('window-common', 'verbose', 'Restoring dimensions for ' . winid . ': ' . string(a:windims[winid]))
        let olddims = a:windims[winid]
        let newdims = WinStateGetWinDimensions(winid)
        if olddims.w <# newdims.w
            call EchomLog('window-common', 'debug', 'Set width for window ' . winid . ' to ' . olddims.w)
            call WinStateMoveCursorToWinid(winid)
            call WinStateWincmd(olddims.w, '|')
        endif
        if olddims.h <# newdims.h
            call EchomLog('window-common', 'debug', 'Set height for window ' . winid . ' to ' . olddims.h)
            call WinStateMoveCursorToWinid(winid)
            call WinStateWincmd(olddims.h, '_')
        endif
    endfor
endfunction

" Record the dimensions of all windows in the model
function! WinCommonRecordAllDimensions()
    call EchomLog('window-common', 'debug', 'WinCommonRecordAllDimensions')
    " Record all uberwin dimensions in the model
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        try
            let winids = WinModelUberwinIdsByGroupTypeName(grouptypename)
            let dims = WinStateGetWinDimensionsList(winids)
            call EchomLog('window-common', 'debug', 'Write state dimensions of uberwin group ' . grouptypename . ' to model: ' . string(dims))
            call WinModelChangeUberwinGroupDimensions(grouptypename, dims)
        catch /.*/
            call EchomLog('window-common', 'warning', 'WinCommonRecordAllDimensions found uberwin group ' . grouptypename . ' inconsistent:')
            call EchomLog('window-common', 'warning', v:throwpoint)
            call EchomLog('window-common', 'warning', v:exception)
        endtry
    endfor

    " Record all supwin dimensions in the model
    for supwinid in WinModelSupwinIds()
        try
            let dim = WinStateGetWinDimensions(supwinid)
            call EchomLog('window-common', 'debug', 'Write state dimensions of supwin ' . supwinid . ' to model: ' . string(dim))
            call WinModelChangeSupwinDimensions(supwinid, dim.nr, dim.w, dim.h)
        catch
            call EchomLog('window-common', 'warning', 'WinCommonRecordAllDimensions found supwin ' . supwinid . ' inconsistent:')
            call EchomLog('window-common', 'warning', v:throwpoint)
            call EchomLog('window-common', 'warning', v:exception)
        endtry

    " Record all subwin dimensions in the model
        let supwinnr = WinStateGetWinnrByWinid(supwinid)
        for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            try
                let winids = WinModelSubwinIdsByGroupTypeName(supwinid, grouptypename)
                let dims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
                call EchomLog('window-common', 'debug', 'Write state dimensions of subwin group ' . supwinid . ':' . grouptypename . ' to model: ' . string(dims))
                call WinModelChangeSubwinGroupDimensions(supwinid, grouptypename, dims)
            catch /.*/
                call EchomLog('window-common', 'warning', 'WinCommonRecordAllDimensions found subwin group ' . grouptypename . ' for supwin ' . supwinid . ' inconsistent:')
                call EchomLog('window-common', 'warning', v:throwpoint)
                call EchomLog('window-common', 'warning', v:exception)
            endtry
        endfor
    endfor
endfunction

" Wrapper for WinStateOpenUberwinsByGroupType that freezes windows whose
" dimensions shouldn't change and ensures no windows get bigger
function! WinCommonOpenUberwins(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonOpenUberwins ' . a:grouptypename)
    let prefreeze = WinCommonFreezeAllNonSupwinSizes()
    try
        let windims = WinCommonPreserveDimensions()
        try
            let grouptype = g:uberwingrouptype[a:grouptypename]
            let winids = WinStateOpenUberwinsByGroupType(grouptype)

        finally
            call WinCommonRestoreMaxDimensions(windims)
        endtry

    finally
        call WinCommonThawWindowSizes(prefreeze)
    endtry
    call EchomLog('window-common', 'verbose', 'Opened uberwin group ' . a:grouptypename . ' with winids ' . string(winids))
    return winids
endfunction

" Closes all uberwins with priority higher than a given, and returns a list of
" group types closed. The model is unchanged.
function! WinCommonCloseUberwinsWithHigherPriority(priority)
    call EchomLog('window-common', 'debug', 'WinCommonCloseUberwinsWithHigherPriority ' . a:priority)
    let grouptypenames = WinModelUberwinGroupTypeNamesByMinPriority(a:priority)
    let preserved = []

    " grouptypenames is reversed so that we close uberwins in descending
    " priority order. See comments in WinCommonCloseSubwinsWithHigherPriority
    for grouptypename in reverse(copy(grouptypenames))
        call EchomLog('window-common', 'verbose', 'Uberwin group ' . grouptypename . ' has higher priority')
        let pre = WinCommonPreCloseAndReopenUberwins(grouptypename)
        call add(preserved, {'grouptypename':grouptypename,'pre':pre})
        call WinCommonCloseUberwinsByGroupTypeName(grouptypename)
    endfor
    return reverse(copy(preserved))
endfunction

" Reopens uberwins that were closed by WinCommonCloseUberwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenUberwins(preserved)
    call EchomLog('window-common', 'debug', 'WinCommonReopenUberwins')
    for grouptype in a:preserved
        call EchomLog('window-common', 'debug', 'Reopening preserved uberwin group ' . grouptype.grouptypename)
        try
            let winids = WinCommonOpenUberwins(grouptype.grouptypename)
            call EchomLog('window-common', 'verbose', 'Reopened uberwin group ' . grouptype.grouptypename . ' with winids ' . string(winids))
            call WinModelChangeUberwinIds(grouptype.grouptypename, winids)
            call WinCommonPostCloseAndReopenUberwins(
           \    grouptype.grouptypename,
           \    grouptype.pre
           \)

            let dims = WinStateGetWinDimensionsList(winids)
            call WinModelChangeUberwinGroupDimensions(grouptype.grouptypename, dims)
        catch /.*/
            call EchomLog('window-common', 'WinCommonReopenUberwins failed to open ' . grouptype.grouptypename . ' uberwin group:')
            call EchomLog('window-common', 'warning', v:throwpoint)
            call EchomLog('window-common', 'warning', v:exception)
            call WinModelHideUberwins(grouptype.grouptypename)
        endtry
    endfor
endfunction

" Wrapper for WinStateCloseSubwinsByGroupType that falls back to
" WinStateCloseWindow if any subwins in the group are afterimaged and freezes
" windows whose dimensions shouldn't change
function! WinCommonCloseSubwins(supwinid, grouptypename)
    " When windows are closed, Vim needs to choose which other windows to
    " stretch to fill the empty space left. Sometimes Vim makes choices I
    " don't like, such as filling space left behind by subwins with
    " supwins other than the closed subwin's supwin. So before closing the
    " subwin, freeze the height and width of every window except the
    " supwin of the subwin being closed and its other subwins.
    call EchomLog('window-common', 'debug', 'WinCommonCloseSubwins ' . a:supwinid . ':' . a:grouptypename)
    let prefreeze = WinCommonFreezeAllWindowSizesOutsideSupwin(a:supwinid)
    try
        if WinModelSubwinGroupHasAfterimagedSubwin(a:supwinid, a:grouptypename)
            call EchomLog('window-common', 'debug', 'Subwin group ' . a:supwinid . ':' . a:grouptypename . ' is partially afterimaged. Stomping subwins individually.')
            for subwinid in WinModelSubwinIdsByGroupTypeName(
           \    a:supwinid,
           \    a:grouptypename
           \)
                call EchomLog('window-common', 'verbose', 'Stomp subwin ' . subwinid)
                call WinStateCloseWindow(subwinid)
            endfor

            " Here, afterimaged subwins are removed from the state but not from
            " the model. If they are opened again, they will not be afterimaged in
            " the state. So deafterimage them in the model.
            call WinModelDeafterimageSubwinsByGroup(a:supwinid, a:grouptypename)
        else
            call EchomLog('window-common', 'debug', 'Subwin group ' . a:supwinid . ':' . a:grouptypename . ' is not afterimaged. Closing via toClose')
            let grouptype = g:subwingrouptype[a:grouptypename]
            call WinStateCloseSubwinsByGroupType(a:supwinid, grouptype)
        endif

    finally
        call WinCommonThawWindowSizes(prefreeze)
    endtry
endfunction

" Wrapper for WinStateOpenSubwinsByGroupType that freezes windows whose
" dimensions shouldn't change
function! WinCommonOpenSubwins(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonOpenSubwins ' . a:supwinid . ':' . a:grouptypename)
    let prefreeze = WinCommonFreezeAllWindowSizesOutsideSupwin(a:supwinid)
    try
        let grouptype = g:subwingrouptype[a:grouptypename]
        let winids = WinStateOpenSubwinsByGroupType(a:supwinid, grouptype)

    finally
        call WinCommonThawWindowSizes(prefreeze)
    endtry

    call EchomLog('window-common', 'verbose', 'Opened subwin group ' . a:supwinid . ':' . a:grouptypename . ' with winids ' . string(winids))
    return winids
endfunction

" Closes all subwins for a given supwin with priority higher than a given, and
" returns a list of group types closed. The model is unchanged.
function! WinCommonCloseSubwinsWithHigherPriority(supwinid, priority)
    call EchomLog('window-common', 'debug', 'WinCommonCloseSubwinsWithHigherPriority ' . a:supwinid . ' ' . a:priority)
    let grouptypenames = WinModelSubwinGroupTypeNamesByMinPriority(
   \    a:supwinid,
   \    a:priority
   \)
    let preserved = []

    " grouptypenames is reversed because Vim sometimes makes strange decisions
    " when deciding which windows will fill the space left behind by a window
    " that closes. Assuming that subwins in ascending priority open from the
    " outside in (which is the intent underpinning the notion of subwin
    " priorities), closing them in descending priority order means closing
    " them from the inside out. This means that a subwin will never have to
    " stretch to fill the space left behind - only the supwin will stretch.
    " I don't fully understand why, but relaxing that constraint and allowing
    " subwins to stretch causes strange behaviour with other supwins filling
    " the space left by subwins closing after they have stretched.
    for grouptypename in reverse(copy(grouptypenames))
        call EchomLog('window-common', 'verbose', 'Subwin group ' . grouptypename . ' has higher priority')
        let pre = WinCommonPreCloseAndReopenSubwins(a:supwinid, grouptypename)
        call add(preserved, {'grouptypename':grouptypename,'pre':pre})
        call WinCommonCloseSubwins(a:supwinid, grouptypename)
    endfor
    return reverse(copy(preserved))
endfunction

" Reopens subwins that were closed by WinCommonCloseSubwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenSubwins(supwinid, preserved)
    call EchomLog('window-common', 'debug', 'WinCommonReopenSubwins ' . a:supwinid)
    for grouptype in a:preserved
        call EchomLog('window-common', 'debug', 'Reopening preserved supwin group ' . a:supwinid . ':' . grouptype.grouptypename)
        try
            let winids = WinCommonOpenSubwins(
           \    a:supwinid,
           \    grouptype.grouptypename
           \)
            call EchomLog('window-common', 'verbose', 'Reopened subwin group ' . a:supwinid . ':' . grouptype.grouptypename . ' with winids ' . string(winids))
            call WinModelChangeSubwinIds(a:supwinid, grouptype.grouptypename, winids)
            call WinCommonPostCloseAndReopenSubwins(
           \    a:supwinid,
           \    grouptype.grouptypename,
           \    grouptype.pre
           \)
            call WinModelDeafterimageSubwinsByGroup(
           \    a:supwinid,
           \    grouptype.grouptypename
           \)

            let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
            let dims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
            call WinModelChangeSubwinGroupDimensions(
           \    a:supwinid,
           \    grouptype.grouptypename,
           \    dims
           \)
        catch /.*/
            call EchomLog('window-common', 'warning', 'WinCommonReopenSubwins failed to open ' . grouptype.grouptypename . ' subwin group for supwin ' . a:supwinid . ':')
            call EchomLog('window-common', 'warning', v:throwpoint)
            call EchomLog('window-common', 'warning', v:exception)
            call WinModelHideSubwins(a:supwinid, grouptype.grouptypename)
        endtry
    endfor
endfunction

function! WinCommonPreCloseAndReopenUberwins(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonPreCloseAndReopenUberwins ' . a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    let preserved = {}
    let curwinid = WinStateGetCursorWinId()
    try
        for typename in g:uberwingrouptype[a:grouptypename].typenames
            let winid = WinModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            let preserved[typename] = WinStatePreCloseAndReopen(winid)
            call EchomLog('window-common', 'verbose', 'Preserved uberwin ' . a:grouptypename . ':' . typename . ' with winid ' . winid . ': ' . string(preserved[typename]))
        endfor
    finally
        call WinStateMoveCursorToWinidSilently(curwinid)
    endtry
    return preserved
endfunction

function! WinCommonPostCloseAndReopenUberwins(grouptypename, preserved)
    call EchomLog('window-common', 'debug', 'WinCommonPostCloseAndReopenUberwins ' . a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    let curwinid = WinStateGetCursorWinId()
    try
        for typename in keys(a:preserved)
            let winid = WinModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            call EchomLog('window-common', 'verbose', 'Restore uberwin ' . a:grouptypename . ':' . typename . ' with winid ' . winid . ': ' . string(a:preserved[typename]))
            call WinStatePostCloseAndReopen(winid, a:preserved[typename])
        endfor
    finally
        call WinStateMoveCursorToWinidSilently(curwinid)
    endtry
endfunction

function! WinCommonPreCloseAndReopenSubwins(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonPreCloseAndReopenSubwins ' . a:supwinid . ':' . a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    let preserved = {}
    let curwinid = WinStateGetCursorWinId()
        for typename in g:subwingrouptype[a:grouptypename].typenames
            let winid = WinModelIdByInfo({
           \    'category': 'subwin',
           \    'supwin': a:supwinid,
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            let preserved[typename] = WinStatePreCloseAndReopen(winid)
            call EchomLog('window-common', 'verbose', 'Preserved subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' with winid ' . winid . ': ' . string(preserved[typename]))
        endfor
    call WinStateMoveCursorToWinidSilently(curwinid)
    return preserved
endfunction

function! WinCommonPostCloseAndReopenSubwins(supwinid, grouptypename, preserved)
    call EchomLog('window-common', 'debug', 'WinCommonPostCloseAndReopenSubwins ' . a:supwinid . ':' . a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    let curwinid = WinStateGetCursorWinId()
        for typename in keys(a:preserved)
            let winid = WinModelIdByInfo({
           \    'category': 'subwin',
           \    'supwin': a:supwinid,
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            call EchomLog('window-common', 'verbose', 'Restore subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' with winid ' . winid . ': ' . string(a:preserved[typename]))
            call WinStatePostCloseAndReopen(winid, a:preserved[typename])
        endfor
    call WinStateMoveCursorToWinidSilently(curwinid)
endfunction

" Closes and reopens all shown subwins of a given supwin with priority higher
" than a given
function! WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(supwinid, priority)
    call EchomLog('window-common', 'debug', 'WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin ' . a:supwinid . ', ' . a:priority)
    let preserved = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, a:priority)
    call EchomLog('window-common', 'verbose', 'Preserved subwins across close-and-reopen: ' . string(preserved))
    call WinCommonReopenSubwins(a:supwinid, preserved)

    let dims = WinStateGetWinDimensions(a:supwinid)
    call EchomLog('window-common', 'verbose', 'New dimensions of closed-and-reopened subwins: ' . string(dims))
    call WinModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

" Closes and reopens all shown subwins of a given supwin
function! WinCommonCloseAndReopenAllShownSubwinsBySupwin(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonCloseAndReopenAllShownSubwinsBySupwin ' . a:supwinid)
    call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(a:supwinid, -1)
endfunction

" Afterimages all afterimaging non-afterimaged subwins of a non-hidden subwin group
function! WinCommonAfterimageSubwinsByInfo(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonAfterimageSubwinsByInfo ' . a:supwinid . ':' . a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    " Don't bother even moving to the supwin if all the afterimaging subwins in
    " the group are already afterimaged
    let afterimagingneeded = 0
    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        if g:subwingrouptype[a:grouptypename].afterimaging[typeidx] &&
       \   !WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call EchomLog('window-common', 'debug', 'Subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' needs afterimaging')
            let afterimagingneeded = 1
            break
        endif
        call EchomLog('window-common', 'verbose', 'Subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' is already afterimaged')
    endfor
    if !afterimagingneeded
        call EchomLog('window-common', 'debug', 'Subwin group ' . a:supwinid . ':' . a:grouptypename . ' already contains only afterimaged subwins')
        return
    endif

    " To make sure the subwins are in a good state, start from their supwin
    call WinStateMoveCursorToWinid(a:supwinid)

    " Each subwin type can be individually afterimaging, so deal with them one
    " by one
    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        " Don't afterimage non-afterimaging subwins
        if !g:subwingrouptype[a:grouptypename].afterimaging[typeidx]
            call EchomLog('window-common', 'verbose', 'Subwin type ' . a:grouptypename . ':' . g:subwingrouptype[a:grouptypename].typenames[typeidx] . ' does not afterimage')
            continue
        endif

        " Don't afterimage subwins that are already afterimaged
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        if WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call EchomLog('window-common', 'debug', 'Subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' is already afterimaged')
            continue
        endif
        
        " Get the subwin ID
        let subwinid = WinModelIdByInfo({
       \    'category': 'subwin',
       \    'supwin': a:supwinid,
       \    'grouptype': a:grouptypename,
       \    'typename': typename
       \})

        call EchomLog('window-common', 'debug', 'Afterimaging subwin ' . a:supwinid . ':' . a:grouptypename . ':' . typename . ' with winid ' . subwinid)

        " Afterimage the subwin in the state
        let aibuf = WinStateAfterimageWindow(subwinid)

        " Afterimage the subwin in the model
        call WinModelAfterimageSubwin(a:supwinid, a:grouptypename, typename, aibuf)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged shown subwins of a supwin
function! WinCommonAfterimageSubwinsBySupwin(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonAfterimageSubwinsBySupwin ' . a:supwinid)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        call WinCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged shown subwins of a subwin
" unless they belong to a given group
function! WinCommonAfterimageSubwinsBySupwinExceptOne(supwinid, excludedgrouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonAfterimageSubwinsBySupwinExceptOne ' . a:supwinid . ':' . a:excludedgrouptypename)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        if grouptypename !=# a:excludedgrouptypename
            call WinCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
        endif
    endfor
endfunction

" Closes all subwin groups of a supwin that contain afterimaged subwins and reopens
" them as non-afterimaged
function! WinCommonDeafterimageSubwinsBySupwin(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonDeafterimageSubwinsBySupwin ' . a:supwinid)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        call EchomLog('window-common', 'verbose', 'Subwin group ' . a:supwinid . ':' . grouptypename)
        if WinModelSubwinGroupHasAfterimagedSubwin(a:supwinid, grouptypename)
            call EchomLog('window-common', 'debug', ' Closing-and-reopening subwin groups of supwin ' . a:supwinid . ' starting with partially afterimaged group ' . grouptypename)
            let priority = g:subwingrouptype[grouptypename].priority
            call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
           \    a:supwinid,
           \    priority - 1
           \)
            return
        endif
    endfor
endfunction

function! WinCommonUpdateAfterimagingByCursorWindow(curwin)
    call EchomLog('window-common', 'debug', 'WinCommonUpdateAfterimagingByCursorWindow ' . string(a:curwin))
    " If the given cursor is in a window that doesn't exist, place it in a
    " window that does exist
    let finalpos = WinCommonReselectCursorWindow(a:curwin)

    " If the cursor's position is in an uberwin, afterimage
    " all shown afterimaging subwins of all supwins
    if finalpos.category ==# 'uberwin'
        call EchomLog('window-common', 'debug', 'Cursor position is uberwin. Afterimaging all subwins of all supwins.')
        for supwinid in WinModelSupwinIds()
            call WinCommonAfterimageSubwinsBySupwin(supwinid)
        endfor

    " If the cursor's position is in a supwin, afterimage all
    " shown afterimaging subwins of all supwins except the one with
    " the cursor. Deafterimage all shown afterimaging subwins of the
    " supwin with the cursor.
    elseif finalpos.category ==# 'supwin'
        call EchomLog('window-common', 'debug', 'Cursor position is supwin ' . finalpos.id . '. Afterimaging all subwins of all other supwins')
        for supwinid in WinModelSupwinIds()
            if supwinid !=# finalpos.id
                call WinCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
        call EchomLog('window-common', 'debug', 'Cursor position is supwin ' . finalpos.id . '. Deafterimaging all its subwins. ')
        call WinCommonDeafterimageSubwinsBySupwin(finalpos.id)

    " If the cursor's position is in a subwin, afterimage all
    " shown afterimaging subwins of all supwins except the one with
    " the subwin with the cursor. Also afterimage all shown
    " afterimaging subwins of the supwin with the subwin with the
    " cursor except for the ones in the group with the subwin with
    " the cursor. If the cursor is in a group with an afterimaging
    " subwin, Deafterimage that group. I had fun writing this
    " comment.
    elseif finalpos.category ==# 'subwin'
        call EchomLog('window-common', 'debug', 'Cursor position is subwin ' . finalpos.supwin . ':' . finalpos.grouptype . ':' . finalpos.typename . '. Afterimaging all subwins of all other supwins.')
        for supwinid in WinModelSupwinIds()
            if supwinid !=# finalpos.supwin
                call WinCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
        call EchomLog('window-common', 'debug', 'Cursor position is subwin ' . finalpos.supwin . ':' . finalpos.grouptype . ':' . finalpos.typename . '. Afterimaging all subwins of supwin ' . finalpos.supwin . ' except those in group ' . finalpos.supwin . ':' . finalpos.grouptype)
        call WinCommonDeafterimageSubwinsBySupwin(finalpos.supwin)
        call WinCommonAfterimageSubwinsBySupwinExceptOne(
                    \    finalpos.supwin,
                    \    finalpos.grouptype
                    \)

    else
       throw 'Cursor final position ' . string(finalpos) . ' is neither uberwin nor supwin nor subwin'
    endif
endfunction

function! s:DoWithout(curwin, callback, args, nouberwins, nosubwins)
    call EchomLog('window-common', 'debug', 'DoWithout ' . string(a:curwin) . ', ' . string(a:callback) . ', ' . string(a:args) . ', [' . a:nouberwins . ',' . a:nosubwins . ']')
    let supwinids = WinModelSupwinIds()
    let closedsubwingroupsbysupwin = {}
    for supwinid in supwinids
        let closedsubwingroupsbysupwin[supwinid] = []
    endfor

    let info = WinCommonGetCursorPosition()
    call EchomLog('window-common', 'debug', 'Cursor position before removals is ' . string(info))

    if a:nosubwins && !empty(supwinids)
        let startwith = supwinids[0]

        " If the cursor is in a supwin, start with it
        if a:curwin.category ==# 'supwin'
            call EchomLog('window-common', 'verbose', 'Cursor is in supwin ' . a:curwin.id . '. Its subwins will be closed first')
            let startwith = str2nr(a:curwin.id)

        " If the cursor is in a subwin, start with its supwin
        elseif a:curwin.category ==# 'subwin'
            call EchomLog('window-common', 'verbose', 'Cursor is in subwin ' . a:curwin.supwin . ':' . a:curwin.grouptype . ':' . a:curwin.typename . '. Subwins of supwin ' . a:curwin.supwin . ' will be closed first')
            let startwith = str2nr(a:curwin.supwin)
        endif

        call remove(supwinids, index(supwinids, startwith))
        call insert(supwinids, startwith)

        call EchomLog('window-common', 'debug', 'Closing all subwins')
        for supwinid in supwinids
             let closedsubwingroupsbysupwin[supwinid] = 
            \    WinCommonCloseSubwinsWithHigherPriority(supwinid, -1)
        endfor
    endif

    try
        let closeduberwingroups = []
        if a:nouberwins
            call EchomLog('window-common', 'debug', 'Closing all uberwins')
            let closeduberwingroups = WinCommonCloseUberwinsWithHigherPriority(-1)
        endif
        try
            if type(a:curwin) ==# v:t_dict
                let winid = WinModelIdByInfo(a:curwin)
                if WinStateWinExists(winid)
                    call EchomLog('window-common', 'debug', 'Cursor window still exists. Moving to it.')
                    call WinStateMoveCursorToWinid(winid)
                endif
            endif
            call EchomLog('window-common', 'verbose', 'Invoking callback ' . string(a:callback) . ' with args ' . string(a:args))
            let retval = call(a:callback, a:args)
            call EchomLog('window-common', 'verbose', 'Callback gave return value ' . string(retval))
            let info = WinCommonGetCursorPosition()
            call EchomLog('window-common', 'debug', 'New cursor position after callback is ' . string(info))

        finally
            call EchomLog('window-common', 'debug', 'Reopening all uberwins')
            call WinCommonReopenUberwins(closeduberwingroups)
        endtry

    finally
        call EchomLog('window-common', 'debug', 'Reopening all subwins')
        for supwinid in supwinids
            call EchomLog('window-common', 'verbose', 'Reopening all subwins of supwin ' . supwinid)
            call WinCommonReopenSubwins(supwinid, closedsubwingroupsbysupwin[supwinid])
            let dims = WinStateGetWinDimensions(supwinid)
            call EchomLog('window-common', 'verbose', 'Supwin dimensions after reopening its subwins: ' . string(dims))
            " Afterimage everything after finishing with each supwin to avoid collisions
            call EchomLog('window-common', 'verbose', 'Afterimaging all reopened subwins of supwin ' . supwinid . ' to avoid collisions with the next supwin')
            call WinCommonAfterimageSubwinsBySupwin(supwinid)
            call WinModelChangeSupwinDimensions(supwinid, dims.nr, dims.w, dims.h)
        endfor
        call WinCommonRestoreCursorPosition(info)
        call WinCommonUpdateAfterimagingByCursorWindow(info.win)
    endtry
    return retval
endfunction
function! WinCommonDoWithoutUberwins(curwin, callback, args)
    call EchomLog('window-common', 'debug', 'WinCommonDoWithoutUberwins ' . string(a:curwin) . ', ' . string(a:callback) . ', ' . string(a:args))
    return s:DoWithout(a:curwin, a:callback, a:args, 1, 0)
endfunction

function! WinCommonDoWithoutSubwins(curwin, callback, args)
    call EchomLog('window-common', 'debug', 'WinCommonDoWithoutSubwins ' . string(a:curwin) . ', ' . string(a:callback) . ', ' . string(a:args))
    return s:DoWithout(a:curwin, a:callback, a:args, 0, 1)
endfunction

function! WinCommonDoWithoutUberwinsOrSubwins(curwin, callback, args)
    call EchomLog('window-common', 'debug', 'WinCommonDoWithoutUberwinsOrSubwins ' . string(a:curwin) . ', ' . string(a:callback) . ', ' . string(a:args))
    return s:DoWithout(a:curwin, a:callback, a:args, 1, 1)
endfunction

function! s:Nop()
    call EchomLog('window-common', 'debug', 'Nop')
endfunction

" Closes and reopens all shown subwins in the current tab, afterimaging the
" afterimaging ones that need it
function! WinCommonCloseAndReopenAllShownSubwins(curwin)
    call EchomLog('window-common', 'debug', 'WinCommonCloseAndReopenAllShownSubwins ' . string(a:curwin))
     call WinCommonDoWithoutSubwins(a:curwin, function('s:Nop'), [])
endfunction

" Returns a statusline-friendly string that will evaluate to the correct
" colour and flag for the given subwin group
" This code is awkward because statusline expressions cannot recurse
function! WinCommonSubwinFlagStrByGroup(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonSubwinFlagStrByGroup ' . a:grouptypename)
    let flagcol = WinModelSubwinFlagCol(a:grouptypename)
    let winidexpr = 'WinStateGetCursorWinId()'
    let flagexpr = 'WinModelSubwinFlagByGroup(' .
   \               winidexpr .
   \               ",'" .
   \               a:grouptypename .
   \               "')"
    return '%' . flagcol . '*%{' . flagexpr . '}'
endfunction
