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
    call EchomLog('window-common', 'debug', 'WinCommonUberwinGroupExistsInState ', a:grouptypename)
    let winids = WinModelUberwinIdsByGroupTypeName(a:grouptypename)
    return WinStateWinExists(winids[0])
endfunction

" Returns true if winids listed in the model for a subwin group exist in the
" state
function! WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonSubwinGroupExistsInState ', a:supwinid, ':', a:grouptypename)
    let winids = WinModelSubwinIdsByGroupTypeName(a:supwinid, a:grouptypename)
    return WinStateWinExists(winids[0])
endfunction

" Returns false if the dimensions in the model of any uberwin in a shown group of
" a given type are dummies or inconsistent with the state. True otherwise.

function! WinCommonUberwinGroupDimensionsMatch(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonUberwinGroupDimensionsMatch ', a:grouptypename)
    for typename in WinModelUberwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('window-common', 'verbose', 'Check uberwin ', a:grouptypename, ':', typename)
        let mdims = WinModelUberwinDimensions(a:grouptypename, typename)
        if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
            call EchomLog('window-common', 'debug', 'Uberwin ', a:grouptypename, ':', typename, ' has dummy dimensions')
            return 0
        endif
        let winid = WinModelIdByInfo({
       \    'category':'uberwin',
       \    'grouptype':a:grouptypename,
       \    'typename':typename
       \})
        let sdims = WinStateGetWinDimensions(winid)
        if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
            call EchomLog('window-common', 'debug', 'Uberwin ', a:grouptypename, ':', typename, ' has inconsistent non-dummy dimensions')
            return 0
        endif
    endfor
    call EchomLog('window-common', 'debug', 'No dimensional inconsistency found for uberwin group ', a:grouptypename)
    return 1
endfunction

" Returns false if the dimensions in the model of a given supwin are dummies
" or inconsistent with the state. True otherwise.
function! WinCommonSupwinDimensionsMatch(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonSupwinDimensionsMatch ', a:supwinid)
    let mdims = WinModelSupwinDimensions(a:supwinid)
    if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
        call EchomLog('window-common', 'debug', 'Supwin ', a:supwinid, ' has dummy dimensions')
        return 0
    endif
    let sdims = WinStateGetWinDimensions(a:supwinid)
    if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
        call EchomLog('window-common', 'debug', 'Supwin ', a:supwinid, ' has inconsistent non-dummy dimensions')
        return 0
    endif
    call EchomLog('window-common', 'debug', 'No dimensional inconsistency found for supwin ', a:supwinid)
    return 1
endfunction

" Returns false if the dimensions in the model of any subwin in a shown group of
" a given type for a given supwin are dummies or inconsistent with the state.
" True otherwise.
function! WinCommonSubwinGroupDimensionsMatch(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonSubwinGroupDimensionsMatch ', a:supwinid, ':', a:grouptypename)
    for typename in WinModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('window-common', 'verbose', 'Check subwin ', a:supwinid, ':', a:grouptypename, ':', typename)
        let mdims = WinModelSubwinDimensions(a:supwinid, a:grouptypename, typename)
        if mdims.relnr ==# 0 || mdims.w ==# -1 || mdims.h ==# -1
            call EchomLog('window-common', 'debug', 'Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' has dummy dimensions')
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
            call EchomLog('window-common', 'debug', 'Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' has inconsistent non-dummy dimensions')
            return 0
        endif
    endfor
    call EchomLog('window-common', 'debug', 'No dimensional inconsistency found for subwin group ', a:supwinid, ':', a:grouptypename)
    return 1
endfunction

" Get the window ID of the topmost leftmost supwin
function! WinCommonFirstSupwinId()
    call EchomLog('window-common', 'debug', 'WinCommonFirstSupwinId')
    let minsupwinnr = 0
    let minsupwinid = 0
    for supwinid in WinModelSupwinIds()
        if !WinStateWinExists(supwinid)
            call EchomLog('window-common', 'verbose', 'Skipping non-state-present supwin ', supwinid)
            continue
        endif
        call EchomLog('window-common', 'verbose', 'Check supwin ', supwinid)
        let winnr = WinStateGetWinnrByWinid(supwinid)
        if minsupwinnr ==# 0 || minsupwinnr > winnr
            call EchomLog('window-common', 'verbose', 'Supwin ', supwinid, ' has lowest winnr so far: ', winnr)
            let minsupwinnr = winnr
            let minsupwinid = supwinid
        endif
    endfor
    call EchomLog('window-common', 'debug', 'Supwin with lowest winnr is ', minsupwinid)
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
    call EchomLog('window-common', 'debug', 'Selected uberwin ', grouptypename, ':', typename, ' as first uberwin')
    return {
   \    'category':'uberwin',
   \    'grouptype':grouptypename,
   \    'typename':typename
   \}
endfunction

" Given a cursor position remembered with WinCommonGetCursorPosition, return
" either the same position or an updated one if it doesn't exist anymore
function! WinCommonReselectCursorWindow(oldpos)
    call EchomLog('window-common', 'debug', 'WinCommonReselectCursorWindow ', a:oldpos)
    let pos = a:oldpos

    " If the cursor is in a nonexistent or hidden subwin, try to select its supwin
    if pos.category ==# 'subwin' && (
   \   !WinModelSubwinGroupExists(pos.supwin, pos.grouptype) ||
   \   WinModelSubwinGroupIsHidden(pos.supwin, pos.grouptype))
        call EchomLog('window-common', 'debug', 'Cursor is in nonexistent or hidden subwin. Attempt to select its supwin: ', pos.supwin)
        let pos = {'category':'supwin','id':pos.supwin}
    endif

    " If all we have is a window ID, try looking it up
    if pos.category ==# 'none' || pos.category ==# 'supwin'
        call EchomLog('window-common', 'debug', 'Validate winid ', pos.id, ' by model lookup')
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
            call EchomLog('window-common', 'debug', 'First supwin is ', firstsupwinid)
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

    " If we still have no window ID, then there are no windows in the model
    " and an informed decision can't be made.
    if pos.category ==# 'none'
        return a:oldpos
    endif

    " At this point, a window has been chosen based only on the model. But if
    " the model and state are inconsistent, the window may not be open in the
    " state.
    call EchomLog('window-common', 'debug', 'Cursor position selected based on model: ', pos)
    let winexistsinstate = WinStateWinExists(WinModelIdByInfo(pos))

    " If a non-open subwin was selected, select its supwin
    if !winexistsinstate && pos.category ==# 'subwin'
        call EchomLog('window-common', 'debug', 'Cursor position is a state-closed subwin. Attempt to select its supwin: ', pos.supwin)
        let pos = {'category':'supwin','id':pos.supwin}
        let winexistsinstate = WinStateWinExists(WinModelIdByInfo(pos))
    endif

    " If a non-open supwin was selected. select the first supwin
    if !winexistsinstate && pos.category ==# 'supwin'
        call EchomLog('window-common', 'debug', 'Cursor position is a state-closed supwin. Fallback to first supwin')
        let firstsupwinid = WinCommonFirstSupwinId()
        if firstsupwinid
            call EchomLog('window-common', 'debug', 'First supwin is ', firstsupwinid)
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

    call EchomLog('window-common', 'verbose', 'Reselected cursor position ', pos)
    return pos
endfunction

" Fix the scroll position of all windows such that opening and closing new windows
" won't change them. ('Shield' them). Return information about the shielded windows'
" previous fixedness so that they can later be unshielded. Exclude some
" windows.
function! WinCommonShieldAllWindows(excludedwinids)
    call EchomLog('window-common', 'debug', 'WinCommonShieldAllWindows')
    let supwinids = copy(WinModelSupwinIds())

    let preshield = {}
    for winid in WinStateGetWinidsByCurrentTab()
        if index(a:excludedwinids, str2nr(winid)) >=# 0
            continue
        endif
        let onlyscroll = (index(supwinids, str2nr(winid)) >= 0)
        call EchomLog('window-common', 'verbose', 'Shield ', winid, ' ' . onlyscroll)
        let preshield[winid] = WinStateShieldWindow(winid, onlyscroll)
    endfor
    
    call EchomLog('window-common', 'verbose', 'Shielded: ', preshield)
    return preshield
endfunction

" Unshield windows that were shielded with WinCommonShieldAllWindows()
function! WinCommonUnshieldWindows(preshield)
    call EchomLog('window-common', 'debug', 'WinCommonUnshieldWindows')
    for winid in keys(a:preshield)
        if WinStateWinExists(winid)
            call EchomLog('window-common', 'verbose', 'Unshield ', winid, ':', a:preshield[winid])
            call WinStateUnshieldWindow(winid, a:preshield[winid])
        else
            call EchomLog('window-common', 'verbose', 'Window ', winid, ' does not exist in state and so cannot be unshielded')
        endif
    endfor
endfunction

" Moves the cursor to a window remembered with WinCommonGetCursorPosition. If
" the window no longer exists, go to the next best window as selected by
" WinCommonReselectCursorWindow
function! WinCommonRestoreCursorPosition(info)
    call EchomLog('window-common', 'debug', 'WinCommonRestoreCursorPosition ', a:info)
    let newpos = WinCommonReselectCursorWindow(a:info.win)
    call EchomLog('window-common', 'debug', 'Reselected cursor position: ', newpos)
    " If we failed to reselect, we fail to restore
    if newpos.category ==# 'none'
        return
    endif
    let winid = WinModelIdByInfo(newpos)
    call WinStateMoveCursorToWinid(winid)
    if WinModelIdByInfo(a:info.win) ==# WinModelIdByInfo(newpos)
        call WinStateRestoreCursorPosition(a:info.cur)
    endif
endfunction

" Wrapper for WinStateCloseUberwinsByGroupType that shields windows whose
" dimensions shouldn't change and validates that the windows it removes from
" the state are the ones associated with the correct uberwin group type in the
" model
function! WinCommonCloseUberwinsByGroupTypeName(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonCloseUberwinsByGroupTypeName ', a:grouptypename)
    " When windows are closed, Vim needs to choose which other windows to
    " expand to fill the free space and how to change those windows' scroll
    " positions. Sometimes Vim makes choices I don't like, such as scrolling
    " down in the windows it expands. So before closing the uberwin, fix the
    " scroll position of every window except the ones being closed.
    " Do ***NOT*** optimize this by not excluding the windows being closed! It
    " leads to trouble.
    " While the scrollbind option is said to be window-local in Vim's Help, a
    " particularly nasty undocumented behaviour applies when a scrollbound window
    " is closed: Vim preserves the scrollbind option for that window's buffer and
    " then applies it to the next window that the buffer enters. That's what
    " would happen here: WinCommonShieldAllWindows() would set scrollbind on
    " the uberwins, then WinStateCloseUberwinsByGroupType would close them.
    " Vim would internally preserve scrollbind for the uberwins' buffers,
    " which could then be opened in other windows causing scrollbind to be
    " restored to those windows. Now we have scrollbind set for windows that
    " should not have it set, and a very confused user.
    let uberwinids = WinModelUberwinIdsByGroupTypeName(a:grouptypename)
    let preshield = WinCommonShieldAllWindows(uberwinids)
    try
        let grouptype = g:uberwingrouptype[a:grouptypename]
        let preclosewinids = WinStateGetWinidsByCurrentTab()
        for winid in uberwinids
            if index(preclosewinids, str2nr(winid)) < 0
                throw 'Model uberwin ID ' . winid . ' from group ' . a:grouptypename . ' not present in state'
            endif
        endfor
        call EchomLog('window-common', 'debug', 'State-closing uberwin group ', a:grouptypename)
        call WinStateCloseUberwinsByGroupType(grouptype)
        let postclosewinids = WinStateGetWinidsByCurrentTab()
        for winid in preclosewinids
            let isuberwinid = (index(uberwinids, str2nr(winid)) >= 0)
            let ispresent = (index(postclosewinids, str2nr(winid)) >= 0)
            if !isuberwinid && !ispresent
                throw 'toClose callback of uberwin group type ' . a:grouptypename . ' closed window ' . winid . ' which was not a member of uberwin group ' . a:grouptypename
            endif
            if isuberwinid && ispresent
                throw 'toClose callback of uberwin group type ' . a:grouptypename . ' did not close uberwin ' . winid
            endif
        endfor
    finally
        call WinCommonUnshieldWindows(preshield)
    endtry
endfunction

" When windows are opened, Vim needs to choose which other windows to shrink
" to make room. Sometimes Vim makes choices I don't like, such as equalizing
" windows along the way. This function can be called before opening a window,
" to remember the dimensions of all the windows that are already open. The
" remembered dimensions can then be somewhat restored using
" WinCommonRestoreDimensions
function! WinCommonPreserveDimensions()
    call EchomLog('window-common', 'debug', 'WinCommonPreserveDimensions')
    let winids = WinStateGetWinidsByCurrentTab()
    let dims = WinStateGetWinDimensionsList(winids)
    let windims = {}
    for idx in range(len(winids))
        let windims[winids[idx]] = dims[idx]
    endfor
    call EchomLog('window-common', 'verbose', 'Preserved dimensions: ', windims)
    return windims
endfunction

function! s:CompareWinidsByWinnr(winid1, winid2)
        if !WinStateWinExists(a:winid1) || !WinStateWinExists(a:winid2)
            return 0
        endif
    let winnr1 = WinStateGetWinnrByWinid(a:winid1)
    let winnr2 = WinStateGetWinnrByWinid(a:winid2)
    return winnr1 == winnr2 ? 0 : winnr1 > winnr2 ? 1 : -1
endfunction
function! s:RestoreDimensionsByWinid(winid, olddims, prefertopleftdividers)
    call EchomLog('window-common', 'verbose', 'RestoreDimensionsByWinid ', a:winid, ' ', a:olddims, ' ', a:prefertopleftdividers)
    let newdims = WinStateGetWinDimensions(a:winid)
    " This function gets called only when there are no subwins, so any
    " non-supwin must be an uberwin.
    let isuberwin = (index(WinModelSupwinIds(), str2nr(a:winid)) <# 0 )
    let fixed = WinStateFixednessByWinid(a:winid)
    if a:olddims.w <# newdims.w || (isuberwin && fixed.w && a:olddims.w ># newdims.w)
        call EchomLog('window-common', 'debug', 'Set width for window ', a:winid, ' to ', a:olddims.w)
        call WinStateResizeHorizontal(a:winid, a:olddims.w, a:prefertopleftdividers)
    endif
    if a:olddims.h <# newdims.h || (isuberwin && fixed.h && a:olddims.h ># newdims.h)
        call EchomLog('window-common', 'debug', 'Set height for window ', a:winid, ' to ', a:olddims.h)
        call WinStateResizeVertical(a:winid, a:olddims.h, a:prefertopleftdividers)
    endif
endfunction
" Restore dimensions remembered with WinCommonPreserveDimensions
function! WinCommonRestoreDimensions(windims)
    call EchomLog('window-common', 'debug', 'WinCommonRestoreDimensions')
    let sorted = copy(keys(a:windims))
    call sort(sorted, function('s:CompareWinidsByWinnr'))
    for winid in sorted
        if !WinStateWinExists(winid)
            call EchomLog('window-common', 'verbose', 'Window ', winid, ' no longer exists')
            call remove(sorted, index(sorted, winid))
        endif
    endfor
    for winid in sorted
        call s:RestoreDimensionsByWinid(winid, a:windims[winid], 0)
    endfor
    call reverse(sorted)
    for winid in sorted
        call s:RestoreDimensionsByWinid(winid, a:windims[winid], 1)
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
            call EchomLog('window-common', 'debug', 'Write state dimensions of uberwin group ', grouptypename, ' to model: ', dims)
            call WinModelChangeUberwinGroupDimensions(grouptypename, dims)
        catch /.*/
            call EchomLog('window-common', 'warning', 'WinCommonRecordAllDimensions found uberwin group ', grouptypename, ' inconsistent:')
            call EchomLog('window-common', 'debug', v:throwpoint)
            call EchomLog('window-common', 'warning', v:exception)
        endtry
    endfor

    " Record all supwin dimensions in the model
    for supwinid in WinModelSupwinIds()
        try
            let dim = WinStateGetWinDimensions(supwinid)
            call EchomLog('window-common', 'debug', 'Write state dimensions of supwin ', supwinid, ' to model: ', dim)
            call WinModelChangeSupwinDimensions(supwinid, dim.nr, dim.w, dim.h)
        catch
            call EchomLog('window-common', 'warning', 'WinCommonRecordAllDimensions found supwin ', supwinid, ' inconsistent:')
            call EchomLog('window-common', 'debug', v:throwpoint)
            call EchomLog('window-common', 'warning', v:exception)
        endtry

    " Record all subwin dimensions in the model
        let supwinnr = WinStateGetWinnrByWinid(supwinid)
        for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            try
                let winids = WinModelSubwinIdsByGroupTypeName(supwinid, grouptypename)
                let dims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
                call EchomLog('window-common', 'debug', 'Write state dimensions of subwin group ', supwinid, ':', grouptypename, ' to model: ', dims)
                call WinModelChangeSubwinGroupDimensions(supwinid, grouptypename, dims)
            catch /.*/
                call EchomLog('window-common', 'warning', 'WinCommonRecordAllDimensions found subwin group ', grouptypename, ' for supwin ', supwinid, ' inconsistent:')
                call EchomLog('window-common', 'debug', v:throwpoint)
                call EchomLog('window-common', 'warning', v:exception)
            endtry
        endfor
    endfor
endfunction

" Wrapper for WinStateOpenUberwinsByGroupType that freezes scroll positions
" and corrects dimensions for existing windows
function! WinCommonOpenUberwins(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonOpenUberwins ', a:grouptypename)
    " Shielding only protects windows from scrolling when they are not
    " the current window, so explicitly save and restore the current
    " window's scroll position. Shielding is preferred for other
    " windows due to performance. This is the reason why it is required that
    " uberwin groups' toOpen callbacks not move the cursor before opening the
    " uberwin
    let curtopline = WinStatePreserveScrollPosition()
    let curwin = WinStateGetCursorWinId()

    let preshield = WinCommonShieldAllWindows([])
    try
        let windims = WinCommonPreserveDimensions()
        try
            let grouptype = g:uberwingrouptype[a:grouptypename]
            let winids = WinStateOpenUberwinsByGroupType(grouptype)

        finally
            call WinCommonRestoreDimensions(windims)
        endtry

    finally
        call WinCommonUnshieldWindows(preshield)

        " The ToOpen callback may have moved the cursor, so move it back
        " before restoring the scroll position
        call WinStateMoveCursorToWinidSilently(curwin)

        " The scroll position must be restored after unshielding, or else it
        " may cause other windows to scroll
        call WinStateRestoreScrollPosition(curtopline)
    endtry
    call EchomLog('window-common', 'verbose', 'Opened uberwin group ', a:grouptypename, ' with winids ', winids)
    return winids
endfunction

" Closes all uberwins with priority higher than a given, and returns a list of
" group types closed. The model is unchanged.
function! WinCommonCloseUberwinsWithHigherPriority(priority)
    call EchomLog('window-common', 'debug', 'WinCommonCloseUberwinsWithHigherPriority ', a:priority)
    let grouptypenames = WinModelUberwinGroupTypeNamesByMinPriority(a:priority)
    let preserved = []

    " grouptypenames is reversed so that we close uberwins in descending
    " priority order. See comments in WinCommonCloseSubwinsWithHigherPriority
    let reversegrouptypenames = reverse(copy(grouptypenames))

    " Apply PreCloseAndReopenUberwins to all uberwins first, then close them
    " all. This is done because sometimes closing an uberwin will cause other
    " lower-priority uberwins' dimensions to change, and we don't want to
    " preserve those changes
    for grouptypename in reversegrouptypenames
        call EchomLog('window-common', 'verbose', 'Uberwin group ', grouptypename, ' has higher priority')
        let pre = WinCommonPreCloseAndReopenUberwins(grouptypename)
        call add(preserved, {'grouptypename':grouptypename,'pre':pre})
    endfor
    for grouptypename in reversegrouptypenames
        call WinCommonCloseUberwinsByGroupTypeName(grouptypename)
    endfor
    return reverse(copy(preserved))
endfunction

" Reopens uberwins that were closed by WinCommonCloseUberwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenUberwins(preserved)
    call EchomLog('window-common', 'debug', 'WinCommonReopenUberwins')
    " Open all uberwins first, then apply PostCloseAndReopenUberwins to them
    " all. This is done because sometimes opening an uberwin will cause other
    " lower-priority uberwins' dimensions to change, and we don't want that to
    " happen after they've been restored
    let winids = {}
    for grouptype in a:preserved
        call EchomLog('window-common', 'debug', 'Reopening preserved uberwin group ', grouptype.grouptypename)
        try
            let winids[grouptype.grouptypename] = WinCommonOpenUberwins(grouptype.grouptypename)
            call EchomLog('window-common', 'verbose', 'Reopened uberwin group ', grouptype.grouptypename, ' with winids ', winids)
        catch /.*/
             call EchomLog('window-common', 'WinCommonReopenUberwins failed to open ', grouptype.grouptypename, ' uberwin group:')
             call EchomLog('window-common', 'debug', v:throwpoint)
             call EchomLog('window-common', 'warning', v:exception)
             call WinModelHideUberwins(grouptype.grouptypename)
        endtry
    endfor
    for grouptype in a:preserved
        if has_key(winids, grouptype.grouptypename)
            call WinModelChangeUberwinIds(grouptype.grouptypename, winids[grouptype.grouptypename])
            call WinCommonPostCloseAndReopenUberwins(
           \    grouptype.grouptypename,
           \    grouptype.pre
           \)

            let dims = WinStateGetWinDimensionsList(winids[grouptype.grouptypename])
            call WinModelChangeUberwinGroupDimensions(grouptype.grouptypename, dims)
        endif
    endfor
endfunction

" Wrapper for WinStateCloseSubwinsByGroupType that falls back to
" WinStateCloseWindow if any subwins in the group are afterimaged
function! WinCommonCloseSubwins(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonCloseSubwins ', a:supwinid, ':', a:grouptypename)
    let preunfix = WinStateUnfixDimensions(a:supwinid)
    try
        if WinModelSubwinGroupHasAfterimagedSubwin(a:supwinid, a:grouptypename)
            call EchomLog('window-common', 'debug', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' is partially afterimaged. Stomping subwins individually.')
            for subwinid in WinModelSubwinIdsByGroupTypeName(
           \    a:supwinid,
           \    a:grouptypename
           \)
                call EchomLog('window-common', 'verbose', 'Stomp subwin ', subwinid)
                call WinStateCloseWindow(subwinid)
            endfor

            " Here, afterimaged subwins are removed from the state but not from
            " the model. If they are opened again, they will not be afterimaged in
            " the state. So deafterimage them in the model.
            call WinModelDeafterimageSubwinsByGroup(a:supwinid, a:grouptypename)
        else
            let grouptype = g:subwingrouptype[a:grouptypename]
            let preclosewinids = WinStateGetWinidsByCurrentTab()
            let subwinids = WinModelSubwinIdsByGroupTypeName(a:supwinid, a:grouptypename)
            for winid in subwinids
                if index(preclosewinids, str2nr(winid)) < 0
                    throw 'Model subwin ID ' . winid . ' from group ' . a:supwinid . ':' . a:grouptypename . ' not present in state'
                endif
            endfor
            call EchomLog('window-common', 'debug', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' is not afterimaged. Closing via toClose')
            call WinStateCloseSubwinsByGroupType(a:supwinid, grouptype)
            let postclosewinids = WinStateGetWinidsByCurrentTab()
            for winid in preclosewinids
                let issubwinid = (index(subwinids, str2nr(winid)) >= 0)
                let ispresent = (index(postclosewinids, str2nr(winid)) >= 0)
                if !issubwinid && !ispresent
                    throw 'toClose callback of subwin group type ' . a:grouptypename . ' closed window ' . winid . ' which was not a member of subwin group ' . a:supwinid . ':' . a:grouptypename
                endif
                if issubwinid && ispresent
                    throw 'toClose callback of subwin group type ' . a:grouptypename . ' did not close subwin ' . a:winid . ' of supwin ' . a:supwinid
                endif
            endfor
        endif
    finally
        call WinStateRefixDimensions(a:supwinid, preunfix)
    endtry
endfunction

" Wrapper for WinStateOpenSubwinsByGroupType that uses a group type from the
" model
function! WinCommonOpenSubwins(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonOpenSubwins ', a:supwinid, ':', a:grouptypename)
    if WinStateWinIsTerminal(a:supwinid)
        throw 'Supwin ' . a:supwinid . ' is a terminal window'
    endif
    let preunfix = WinStateUnfixDimensions(a:supwinid)
    try
        let grouptype = g:subwingrouptype[a:grouptypename]
        let winids = WinStateOpenSubwinsByGroupType(a:supwinid, grouptype)
        call EchomLog('window-common', 'verbose', 'Opened subwin group ', a:supwinid, ':', a:grouptypename, ' with winids ', winids)
    finally
        call WinStateRefixDimensions(a:supwinid, preunfix)
    endtry
    return winids
endfunction

" Closes all subwins for a given supwin with priority higher than a given, and
" returns a list of group types closed. The model is unchanged.
function! WinCommonCloseSubwinsWithHigherPriority(supwinid, priority)
    call EchomLog('window-common', 'debug', 'WinCommonCloseSubwinsWithHigherPriority ', a:supwinid, ' ', a:priority)
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
        call EchomLog('window-common', 'verbose', 'Subwin group ', grouptypename, ' has higher priority')
        let pre = WinCommonPreCloseAndReopenSubwins(a:supwinid, grouptypename)
        call add(preserved, {'grouptypename':grouptypename,'pre':pre})
        call WinCommonCloseSubwins(a:supwinid, grouptypename)
    endfor
    return reverse(copy(preserved))
endfunction

" Reopens subwins that were closed by WinCommonCloseSubwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenSubwins(supwinid, preserved)
    call EchomLog('window-common', 'debug', 'WinCommonReopenSubwins ', a:supwinid)
    for grouptype in a:preserved
        call EchomLog('window-common', 'debug', 'Reopening preserved supwin group ', a:supwinid, ':', grouptype.grouptypename)
        try
            let winids = WinCommonOpenSubwins(
           \    a:supwinid,
           \    grouptype.grouptypename
           \)
            call EchomLog('window-common', 'verbose', 'Reopened subwin group ', a:supwinid, ':', grouptype.grouptypename, ' with winids ', winids)
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
            call EchomLog('window-common', 'warning', 'WinCommonReopenSubwins failed to open ', grouptype.grouptypename, ' subwin group for supwin ', a:supwinid, ':')
            call EchomLog('window-common', 'debug', v:throwpoint)
            call EchomLog('window-common', 'warning', v:exception)
            call WinModelHideSubwins(a:supwinid, grouptype.grouptypename)
        endtry
    endfor
endfunction

function! WinCommonPreCloseAndReopenUberwins(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonPreCloseAndReopenUberwins ', a:grouptypename)
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
            call EchomLog('window-common', 'verbose', 'Preserved uberwin ', a:grouptypename, ':', typename, ' with winid ', winid, ': ', preserved[typename])
        endfor
    finally
        call WinStateMoveCursorToWinidSilently(curwinid)
    endtry
    return preserved
endfunction

function! WinCommonPostCloseAndReopenUberwins(grouptypename, preserved)
    call EchomLog('window-common', 'debug', 'WinCommonPostCloseAndReopenUberwins ', a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    let curwinid = WinStateGetCursorWinId()
    try
        for typename in keys(a:preserved)
            let winid = WinModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            call EchomLog('window-common', 'verbose', 'Restore uberwin ', a:grouptypename, ':', typename, ' with winid ', winid, ': ', a:preserved[typename])
            call WinStatePostCloseAndReopen(winid, a:preserved[typename])
        endfor
    finally
        call WinStateMoveCursorToWinidSilently(curwinid)
    endtry
endfunction

function! WinCommonPreCloseAndReopenSubwins(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonPreCloseAndReopenSubwins ', a:supwinid, ':', a:grouptypename)
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
            call EchomLog('window-common', 'verbose', 'Preserved subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' with winid ', winid, ': ', preserved[typename])
        endfor
    call WinStateMoveCursorToWinidSilently(curwinid)
    return preserved
endfunction

function! WinCommonPostCloseAndReopenSubwins(supwinid, grouptypename, preserved)
    call EchomLog('window-common', 'debug', 'WinCommonPostCloseAndReopenSubwins ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    let curwinid = WinStateGetCursorWinId()
        for typename in keys(a:preserved)
            let winid = WinModelIdByInfo({
           \    'category': 'subwin',
           \    'supwin': a:supwinid,
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            call EchomLog('window-common', 'verbose', 'Restore subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' with winid ', winid, ': ', a:preserved[typename])
            call WinStatePostCloseAndReopen(winid, a:preserved[typename])
        endfor
    call WinStateMoveCursorToWinidSilently(curwinid)
endfunction

" Closes and reopens all shown subwins of a given supwin with priority higher
" than a given
function! WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(supwinid, priority)
    call EchomLog('window-common', 'debug', 'WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin ', a:supwinid, ', ', a:priority)
    let preserved = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, a:priority)
    call EchomLog('window-common', 'verbose', 'Preserved subwins across close-and-reopen: ', preserved)
    call WinCommonReopenSubwins(a:supwinid, preserved)

    let dims = WinStateGetWinDimensions(a:supwinid)
    call EchomLog('window-common', 'verbose', 'New dimensions of closed-and-reopened subwins: ', dims)
    call WinModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

" Closes and reopens all shown subwins of a given supwin
function! WinCommonCloseAndReopenAllShownSubwinsBySupwin(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonCloseAndReopenAllShownSubwinsBySupwin ', a:supwinid)
    call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(a:supwinid, -1)
endfunction

" Afterimages all afterimaging non-afterimaged subwins of a non-hidden subwin group
function! WinCommonAfterimageSubwinsByInfo(supwinid, grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonAfterimageSubwinsByInfo ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    " Don't bother even moving to the supwin if all the afterimaging subwins in
    " the group are already afterimaged
    let afterimagingneeded = 0
    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        if g:subwingrouptype[a:grouptypename].afterimaging[typeidx] &&
       \   !WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call EchomLog('window-common', 'debug', 'Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' needs afterimaging')
            let afterimagingneeded = 1
            break
        endif
        call EchomLog('window-common', 'verbose', 'Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' is already afterimaged')
    endfor
    if !afterimagingneeded
        call EchomLog('window-common', 'debug', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' already contains only afterimaged subwins')
        return
    endif

    " To make sure the subwins are in a good state, start from their supwin
    call WinStateMoveCursorToWinid(a:supwinid)

    " Each subwin type can be individually afterimaging, so deal with them one
    " by one
    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        " Don't afterimage non-afterimaging subwins
        if !g:subwingrouptype[a:grouptypename].afterimaging[typeidx]
            call EchomLog('window-common', 'verbose', 'Subwin type ', a:grouptypename, ':', g:subwingrouptype[a:grouptypename].typenames[typeidx], ' does not afterimage')
            continue
        endif

        " Don't afterimage subwins that are already afterimaged
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        if WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call EchomLog('window-common', 'debug', 'Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' is already afterimaged')
            continue
        endif
        
        " Get the subwin ID
        let subwinid = WinModelIdByInfo({
       \    'category': 'subwin',
       \    'supwin': a:supwinid,
       \    'grouptype': a:grouptypename,
       \    'typename': typename
       \})

        call EchomLog('window-common', 'debug', 'Afterimaging subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' with winid ', subwinid)

        " Afterimage the subwin in the state
        let aibuf = WinStateAfterimageWindow(subwinid)

        " Afterimage the subwin in the model
        call WinModelAfterimageSubwin(a:supwinid, a:grouptypename, typename, aibuf)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged shown subwins of a supwin
function! WinCommonAfterimageSubwinsBySupwin(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonAfterimageSubwinsBySupwin ', a:supwinid)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        call WinCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged shown subwins of a subwin
" unless they belong to a given group
function! WinCommonAfterimageSubwinsBySupwinExceptOne(supwinid, excludedgrouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonAfterimageSubwinsBySupwinExceptOne ', a:supwinid, ':', a:excludedgrouptypename)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        if grouptypename !=# a:excludedgrouptypename
            call WinCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
        endif
    endfor
endfunction

" Closes all subwin groups of a supwin that contain afterimaged subwins and reopens
" them as non-afterimaged
function! WinCommonDeafterimageSubwinsBySupwin(supwinid)
    call EchomLog('window-common', 'debug', 'WinCommonDeafterimageSubwinsBySupwin ', a:supwinid)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        call EchomLog('window-common', 'verbose', 'Subwin group ', a:supwinid, ':', grouptypename)
        if WinModelSubwinGroupHasAfterimagedSubwin(a:supwinid, grouptypename)
            call EchomLog('window-common', 'debug', ' Closing-and-reopening subwin groups of supwin ', a:supwinid, ' starting with partially afterimaged group ', grouptypename)
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
    call EchomLog('window-common', 'debug', 'WinCommonUpdateAfterimagingByCursorWindow ', a:curwin)
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
        call EchomLog('window-common', 'debug', 'Cursor position is supwin ', finalpos.id, '. Afterimaging all subwins of all other supwins')
        for supwinid in WinModelSupwinIds()
            if supwinid !=# finalpos.id
                call WinCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
        call EchomLog('window-common', 'debug', 'Cursor position is supwin ', finalpos.id, '. Deafterimaging all its subwins. ')
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
        call EchomLog('window-common', 'debug', 'Cursor position is subwin ', finalpos.supwin, ':', finalpos.grouptype, ':', finalpos.typename, '. Afterimaging all subwins of all other supwins.')
        for supwinid in WinModelSupwinIds()
            if supwinid !=# finalpos.supwin
                call WinCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
        call EchomLog('window-common', 'debug', 'Cursor position is subwin ', finalpos.supwin, ':', finalpos.grouptype, ':', finalpos.typename, '. Afterimaging all subwins of supwin ', finalpos.supwin, ' except those in group ', finalpos.supwin, ':', finalpos.grouptype)
        call WinCommonDeafterimageSubwinsBySupwin(finalpos.supwin)
        call WinCommonAfterimageSubwinsBySupwinExceptOne(
                    \    finalpos.supwin,
                    \    finalpos.grouptype
                    \)

    else
       throw 'Cursor final position ' . string(finalpos) . ' is neither uberwin nor supwin nor subwin'
    endif
endfunction

function! s:DoWithout(curwin, callback, args, nouberwins, nosubwins, reselect)
    call EchomLog('window-common', 'debug', 'DoWithout ', a:curwin, ', ', a:callback, ', ', a:args, ', [', a:nouberwins, ',', a:nosubwins, ',', a:reselect, ']')
    let supwinids = WinModelSupwinIds()
    let closedsubwingroupsbysupwin = {}
    for supwinid in supwinids
        let closedsubwingroupsbysupwin[supwinid] = []
    endfor

    let info = WinCommonGetCursorPosition()
    call EchomLog('window-common', 'debug', 'Cursor position before removals is ', info)

    if a:nosubwins && !empty(supwinids)
        let startwith = supwinids[0]

        " If the cursor is in a supwin, start with it
        if a:curwin.category ==# 'supwin'
            call EchomLog('window-common', 'verbose', 'Cursor is in supwin ', a:curwin.id, '. Its subwins will be closed first')
            let startwith = str2nr(a:curwin.id)

        " If the cursor is in a subwin, start with its supwin
        elseif a:curwin.category ==# 'subwin'
            call EchomLog('window-common', 'verbose', 'Cursor is in subwin ', a:curwin.supwin, ':', a:curwin.grouptype, ':', a:curwin.typename, '. Subwins of supwin ', a:curwin.supwin, ' will be closed first')
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

    let pretabnr = WinStateGetTabnr()
    let posttabnr = pretabnr
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
            call EchomLog('window-common', 'verbose', 'Invoking callback ', a:callback, ' with args ', a:args)
            let retval = call(a:callback, a:args)
            call EchomLog('window-common', 'verbose', 'Callback gave return value ', retval)
            let info = WinCommonGetCursorPosition()
            call EchomLog('window-common', 'debug', 'New cursor position after callback is ', info)
            let posttabnr = WinStateGetTabnr()
            call EchomLog('window-common', 'debug', 'New tab after callback is ', posttabnr)

        finally
            if pretabnr !=# posttabnr
                call EchomLog('window-common', 'debug', 'Callback changed tab from ', pretabnr, ' to ', posttabnr, '. Returning before reopening.')
                call WinStateGotoTab(pretabnr)
            endif
            call EchomLog('window-common', 'debug', 'Reopening all uberwins')
            call WinCommonReopenUberwins(closeduberwingroups)
        endtry

    finally
        call EchomLog('window-common', 'debug', 'Reopening all subwins')
        for supwinid in supwinids
            let newsupwinid = supwinid
            let gotopretabnr = 0
            if !WinStateWinExists(supwinid)
                if pretabnr !=# posttabnr
                    " There is only one command that removes a window and ends
                    " in a different tab: WinMoveToNewTab. So if the control
                    " reaches here, the command is WinMoveToNewTab. We need to
                    " move the model's record of the supwin to the new tab's
                    " model, and also restore the state subwins in the new
                    " tab.
                    let supwindata = WinModelRemoveSupwin(supwinid)
                    call WinStateGotoTab(posttabnr)
                    call WinModelRestoreSupwin(supwindata)
                    " This command changes the winid of the window being
                    " moved (even with legacy winids, because it wipes out
                    " window-local variables). So after moving the supwin
                    " record to the new tab's model, change its winid
                    " Immediately after wincmd T, the only window in the tab
                    " is the one that was moved
                    let newsupwinid = WinStateGetCursorWinId()
                    call WinModelReplaceWinid(supwinid, newsupwinid)
                    let gotopretabnr = 1
                    call EchomLog('window-common', 'debug', 'Supwin ', supwinid, ' has moved to tab ', posttabnr, ' and changed winid to ', newsupwinid, '. Restoring subwins there.')
                else
                    call EchomLog('window-common', 'debug', 'Supwin ', supwinid, ' has vanished from state. Not restoring its subwins.')
                    continue
                endif
            endif
            call EchomLog('window-common', 'verbose', 'Reopening all subwins of supwin ', newsupwinid)
            call WinCommonReopenSubwins(newsupwinid, closedsubwingroupsbysupwin[supwinid])
            let dims = WinStateGetWinDimensions(newsupwinid)
            call EchomLog('window-common', 'verbose', 'Supwin dimensions after reopening its subwins: ', dims)
            " Afterimage everything after finishing with each supwin to avoid collisions
            call EchomLog('window-common', 'verbose', 'Afterimaging all reopened subwins of supwin ', newsupwinid, ' to avoid collisions with the next supwin')
            call WinCommonAfterimageSubwinsBySupwin(newsupwinid)
            call WinModelChangeSupwinDimensions(newsupwinid, dims.nr, dims.w, dims.h)
            if gotopretabnr
                call EchomLog('window-common', 'debug', 'Finished restoring subwins of supwin ', newsupwinid, ' in tab ', posttabnr, '. Returning to tab ', pretabnr)
                call WinStateGotoTab(pretabnr)
            endif
        endfor
        if pretabnr !=# posttabnr
            call EchomLog('window-common', 'debug', 'Finished reopening. All afterimaging subwins afterimaged. Moving back to post-callback tab ', posttabnr)
            call WinStateGotoTab(posttabnr)
        endif
        if a:reselect
            call WinCommonRestoreCursorPosition(info)
            call WinCommonUpdateAfterimagingByCursorWindow(info.win)
        else
            call WinStateMoveCursorToWinid(info.win.id)
        endif
    endtry
    return retval
endfunction
function! WinCommonDoWithoutUberwins(curwin, callback, args, reselect)
    call EchomLog('window-common', 'debug', 'WinCommonDoWithoutUberwins ', a:curwin, ', ', a:callback, ', ', a:args, ', ', a:reselect)
    return s:DoWithout(a:curwin, a:callback, a:args, 1, 0, a:reselect)
endfunction

function! WinCommonDoWithoutSubwins(curwin, callback, args, reselect)
    call EchomLog('window-common', 'debug', 'WinCommonDoWithoutSubwins ', a:curwin, ', ', a:callback, ', ', a:args, ', ', a:reselect)
    return s:DoWithout(a:curwin, a:callback, a:args, 0, 1, a:reselect)
endfunction

function! WinCommonDoWithoutUberwinsOrSubwins(curwin, callback, args, reselect)
    call EchomLog('window-common', 'debug', 'WinCommonDoWithoutUberwinsOrSubwins ', a:curwin, ', ', a:callback, ', ', a:args, ', ', a:reselect)
    return s:DoWithout(a:curwin, a:callback, a:args, 1, 1, a:reselect)
endfunction

function! s:Nop()
    call EchomLog('window-common', 'debug', 'Nop')
endfunction

" Closes and reopens all shown subwins in the current tab, afterimaging the
" afterimaging ones that need it
function! WinCommonCloseAndReopenAllShownSubwins(curwin)
    call EchomLog('window-common', 'debug', 'WinCommonCloseAndReopenAllShownSubwins ', a:curwin)
     call WinCommonDoWithoutSubwins(a:curwin, function('s:Nop'), [], 1)
endfunction

" Returns a statusline-friendly string that will evaluate to the correct
" colour and flag for the given subwin group
" This code is awkward because statusline expressions cannot recurse
function! WinCommonSubwinFlagStrByGroup(grouptypename)
    call EchomLog('window-common', 'debug', 'WinCommonSubwinFlagStrByGroup ', a:grouptypename)
    let flagcol = WinModelSubwinFlagCol(a:grouptypename)
    let winidexpr = 'WinStateGetCursorWinId()'
    let flagexpr = 'WinModelSubwinFlagByGroup(' .
   \               winidexpr .
   \               ",'" .
   \               a:grouptypename .
   \               "')"
    return '%' . flagcol . '*%{' . flagexpr . '}'
endfunction
