" Wince code common to resolver and user operations
" See wince.vim
let s:Log = jer_log#LogFunctions('wince-common')

" Returns a data structure that encodes information about the window that the
" cursor is in
function! WinceCommonGetCursorPosition()
    call s:Log.DBG('WinceCommonGetCursorPosition')
    return {
   \    'win':WinceModelInfoById(WinceStateGetCursorWinId()),
   \    'cur':WinceStateGetCursorPosition()
   \}
endfunction

" Returns true if winids listed in in the model for an uberwin group exist in
" the state
function! WinceCommonUberwinGroupExistsInState(grouptypename)
    call s:Log.DBG('WinceCommonUberwinGroupExistsInState ', a:grouptypename)
    let winids = WinceModelUberwinIdsByGroupTypeName(a:grouptypename)
    return WinceStateWinExists(winids[0])
endfunction

" Returns true if winids listed in the model for a subwin group exist in the
" state
function! WinceCommonSubwinGroupExistsInState(supwinid, grouptypename)
    call s:Log.DBG('WinceCommonSubwinGroupExistsInState ', a:supwinid, ':', a:grouptypename)
    let winids = WinceModelSubwinIdsByGroupTypeName(a:supwinid, a:grouptypename)
    return WinceStateWinExists(winids[0])
endfunction

" Returns false if the dimensions in the model of any uberwin in a shown group of
" a given type are dummies or inconsistent with the state. True otherwise.

function! WinceCommonUberwinGroupDimensionsMatch(grouptypename)
    call s:Log.DBG('WinceCommonUberwinGroupDimensionsMatch ', a:grouptypename)
    for typename in WinceModelUberwinTypeNamesByGroupTypeName(a:grouptypename)
        call s:Log.VRB('Check uberwin ', a:grouptypename, ':', typename)
        let mdims = WinceModelUberwinDimensions(a:grouptypename, typename)
        if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
            call s:Log.DBG('Uberwin ', a:grouptypename, ':', typename, ' has dummy dimensions')
            return 0
        endif
        let winid = WinceModelIdByInfo({
       \    'category':'uberwin',
       \    'grouptype':a:grouptypename,
       \    'typename':typename
       \})
        let sdims = WinceStateGetWinDimensions(winid)
        if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
            call s:Log.DBG('Uberwin ', a:grouptypename, ':', typename, ' has inconsistent non-dummy dimensions')
            return 0
        endif
    endfor
    call s:Log.DBG('No dimensional inconsistency found for uberwin group ', a:grouptypename)
    return 1
endfunction

" Returns false if the dimensions in the model of a given supwin are dummies
" or inconsistent with the state. True otherwise.
function! WinceCommonSupwinDimensionsMatch(supwinid)
    call s:Log.DBG('WinceCommonSupwinDimensionsMatch ', a:supwinid)
    let mdims = WinceModelSupwinDimensions(a:supwinid)
    if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
        call s:Log.DBG('Supwin ', a:supwinid, ' has dummy dimensions')
        return 0
    endif
    let sdims = WinceStateGetWinDimensions(a:supwinid)
    if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
        call s:Log.DBG('Supwin ', a:supwinid, ' has inconsistent non-dummy dimensions')
        return 0
    endif
    call s:Log.DBG('No dimensional inconsistency found for supwin ', a:supwinid)
    return 1
endfunction

" Returns false if the dimensions in the model of any subwin in a shown group of
" a given type for a given supwin are dummies or inconsistent with the state.
" True otherwise.
function! WinceCommonSubwinGroupDimensionsMatch(supwinid, grouptypename)
    call s:Log.DBG('WinceCommonSubwinGroupDimensionsMatch ', a:supwinid, ':', a:grouptypename)
    for typename in WinceModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call s:Log.VRB('Check subwin ', a:supwinid, ':', a:grouptypename, ':', typename)
        let mdims = WinceModelSubwinDimensions(a:supwinid, a:grouptypename, typename)
        if mdims.relnr ==# 0 || mdims.w ==# -1 || mdims.h ==# -1
            call s:Log.DBG('Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' has dummy dimensions')
            return 0
        endif
        let winid = WinceModelIdByInfo({
       \    'category':'subwin',
       \    'supwin': a:supwinid,
       \    'grouptype':a:grouptypename,
       \    'typename':typename
       \})
        let sdims = WinceStateGetWinDimensions(winid)
        let snr = WinceStateGetWinnrByWinid(a:supwinid)
        if sdims.nr !=# snr + mdims.relnr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
            call s:Log.DBG('Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' has inconsistent non-dummy dimensions')
            return 0
        endif
    endfor
    call s:Log.DBG('No dimensional inconsistency found for subwin group ', a:supwinid, ':', a:grouptypename)
    return 1
endfunction

" Get the window ID of the topmost leftmost supwin
function! WinceCommonFirstSupwinId()
    call s:Log.DBG('WinceCommonFirstSupwinId')
    let minsupwinnr = 0
    let minsupwinid = 0
    for supwinid in WinceModelSupwinIds()
        if !WinceStateWinExists(supwinid)
            call s:Log.VRB('Skipping non-state-present supwin ', supwinid)
            continue
        endif
        call s:Log.VRB('Check supwin ', supwinid)
        let winnr = WinceStateGetWinnrByWinid(supwinid)
        if minsupwinnr ==# 0 || minsupwinnr > winnr
            call s:Log.VRB('Supwin ', supwinid, ' has lowest winnr so far: ', winnr)
            let minsupwinnr = winnr
            let minsupwinid = supwinid
        endif
    endfor
    call s:Log.DBG('Supwin with lowest winnr is ', minsupwinid)
    return minsupwinid
endfunction

" Get the window ID of the first uberwin in the lowest-priority shown uberwin
" group
function! WinceCommonFirstUberwinInfo()
    call s:Log.DBG('WinceCommonFirstUberwinInfo')
    let grouptypenames = WinceModelShownUberwinGroupTypeNames()
    if empty(grouptypenames)
        call s:Log.DBG('No uberwins are open')
        return {'category':'none','id':0}
    endif
    let grouptypename = grouptypenames[0]
    let typename = g:wince_uberwingrouptype[grouptypename].typenames[0]
    call s:Log.DBG('Selected uberwin ', grouptypename, ':', typename, ' as first uberwin')
    return {
   \    'category':'uberwin',
   \    'grouptype':grouptypename,
   \    'typename':typename
   \}
endfunction

" Given a cursor position remembered with WinceCommonGetCursorPosition, return
" either the same position or an updated one if it doesn't exist anymore
function! WinceCommonReselectCursorWindow(oldpos)
    call s:Log.DBG('WinceCommonReselectCursorWindow ', a:oldpos)
    let pos = a:oldpos

    " If the cursor is in a nonexistent or hidden subwin, try to select its supwin
    if pos.category ==# 'subwin' && (
   \   !WinceModelSubwinGroupExists(pos.supwin, pos.grouptype) ||
   \   WinceModelSubwinGroupIsHidden(pos.supwin, pos.grouptype))
        call s:Log.DBG('Cursor is in nonexistent or hidden subwin. Attempt to select its supwin: ', pos.supwin)
        let pos = {'category':'supwin','id':pos.supwin}
    endif

    " If all we have is a window ID, try looking it up
    if pos.category ==# 'none' || pos.category ==# 'supwin'
        call s:Log.DBG('Validate winid ', pos.id, ' by model lookup')
        let pos = WinceModelInfoById(pos.id)
    endif

    " If we still have just a window ID, or if the cursor is in a nonexistent
    " supwin, nonexistent uberwin, or hidden uberwin, try to select the first supwin
    if pos.category ==# 'none' ||
   \   (pos.category ==# 'supwin' && !WinceModelSupwinExists(pos.id)) ||
   \   (pos.category ==# 'uberwin' && !WinceModelUberwinGroupExists(pos.grouptype)) ||
   \   (pos.category ==# 'uberwin' && WinceModelUberwinGroupIsHidden(pos.grouptype))
        call s:Log.DBG('Cursor position fallback to first supwin')
        let firstsupwinid = WinceCommonFirstSupwinId()
        if firstsupwinid
            call s:Log.DBG('First supwin is ', firstsupwinid)
            let pos = {'category':'supwin','id':firstsupwinid}
        endif
    endif

    " If we still have just a window ID, there are no supwins and therefore
    " also no subwins. Try to select the first uberwin.
    if pos.category ==# 'none' ||
   \   (pos.category ==# 'supwin' && !WinceModelSupwinExists(pos.id))
        call s:Log.DBG('Cursor position fallback to first uberwin')
        let pos = WinceCommonFirstUberwinInfo()
    endif

    " If we still have no window ID, then there are no windows in the model
    " and an informed decision can't be made.
    if pos.category ==# 'none'
        return a:oldpos
    endif

    " At this point, a window has been chosen based only on the model. But if
    " the model and state are inconsistent, the window may not be open in the
    " state.
    call s:Log.DBG('Cursor position selected based on model: ', pos)
    let winexistsinstate = WinceStateWinExists(WinceModelIdByInfo(pos))

    " If a non-open subwin was selected, select its supwin
    if !winexistsinstate && pos.category ==# 'subwin'
        call s:Log.DBG('Cursor position is a state-closed subwin. Attempt to select its supwin: ', pos.supwin)
        let pos = {'category':'supwin','id':pos.supwin}
        let winexistsinstate = WinceStateWinExists(WinceModelIdByInfo(pos))
    endif

    " If a non-open supwin was selected. select the first supwin
    if !winexistsinstate && pos.category ==# 'supwin'
        call s:Log.DBG('Cursor position is a state-closed supwin. Fallback to first supwin')
        let firstsupwinid = WinceCommonFirstSupwinId()
        if firstsupwinid
            call s:Log.DBG('First supwin is ', firstsupwinid)
            let pos = {'category':'supwin','id':firstsupwinid}
        endif
        let winexistsinstate = WinceStateWinExists(WinceModelIdByInfo(pos))
    endif

    " If we still haven't selected an open supwin, there are no open supwins.
    " Select the first uberwin.
    if !winexistsinstate 
        call s:Log.DBG('Cursor position fallback to first uberwin')
        let pos = WinceCommonFirstUberwinInfo()
        let winexistsinstate = WinceStateWinExists(WinceModelIdByInfo(pos))
    endif

    " If we still have no window ID, then we're out of ideas
    if !winexistsinstate
        throw "No windows from the model are open in the state. Cannot select a window for the cursor."
    endif

    call s:Log.VRB('Reselected cursor position ', pos)
    return pos
endfunction

" Fix the scroll position of all windows such that opening and closing new windows
" won't change them. ('Shield' them). Return information about the shielded windows'
" previous fixedness so that they can later be unshielded. Exclude some
" windows.
function! WinceCommonShieldAllWindows(excludedwinids)
    call s:Log.DBG('WinceCommonShieldAllWindows')
    let supwinids = copy(WinceModelSupwinIds())

    let preshield = {}
    for winid in WinceStateGetWinidsByCurrentTab()
        if index(a:excludedwinids, str2nr(winid)) >=# 0
            continue
        endif
        let onlyscroll = (index(supwinids, str2nr(winid)) >= 0)
        call s:Log.VRB('Shield ', winid, ' ' . onlyscroll)
        let preshield[winid] = WinceStateShieldWindow(winid, onlyscroll)
    endfor
    
    call s:Log.VRB('Shielded: ', preshield)
    return preshield
endfunction

" Unshield windows that were shielded with WinceCommonShieldAllWindows()
function! WinceCommonUnshieldWindows(preshield)
    call s:Log.DBG('WinceCommonUnshieldWindows')
    for winid in keys(a:preshield)
        if WinceStateWinExists(winid)
            call s:Log.VRB('Unshield ', winid, ':', a:preshield[winid])
            call WinceStateUnshieldWindow(winid, a:preshield[winid])
        else
            call s:Log.VRB('Window ', winid, ' does not exist in state and so cannot be unshielded')
        endif
    endfor
endfunction

" Moves the cursor to a window remembered with WinceCommonGetCursorPosition. If
" the window no longer exists, go to the next best window as selected by
" WinceCommonReselectCursorWindow
function! WinceCommonRestoreCursorPosition(info)
    call s:Log.DBG('WinceCommonRestoreCursorPosition ', a:info)
    let newpos = WinceCommonReselectCursorWindow(a:info.win)
    call s:Log.DBG('Reselected cursor position: ', newpos)
    " If we failed to reselect, we fail to restore
    if newpos.category ==# 'none'
        return
    endif
    let winid = WinceModelIdByInfo(newpos)
    call WinceStateMoveCursorToWinid(winid)
    if WinceModelIdByInfo(a:info.win) ==# WinceModelIdByInfo(newpos)
        call WinceStateRestoreCursorPosition(a:info.cur)
    endif
endfunction

" Wrapper for WinceStateCloseUberwinsByGroupType that shields windows whose
" dimensions shouldn't change and validates that the windows it removes from
" the state are the ones associated with the correct uberwin group type in the
" model
function! WinceCommonCloseUberwinsByGroupTypeName(grouptypename)
    call s:Log.DBG('WinceCommonCloseUberwinsByGroupTypeName ', a:grouptypename)
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
    " would happen here: WinceCommonShieldAllWindows() would set scrollbind on
    " the uberwins, then WinceStateCloseUberwinsByGroupType would close them.
    " Vim would internally preserve scrollbind for the uberwins' buffers,
    " which could then be opened in other windows causing scrollbind to be
    " restored to those windows. Now we have scrollbind set for windows that
    " should not have it set, and a very confused user.
    let uberwinids = WinceModelUberwinIdsByGroupTypeName(a:grouptypename)
    let preshield = WinceCommonShieldAllWindows(uberwinids)
    try
        let grouptype = g:wince_uberwingrouptype[a:grouptypename]
        let preclosewinids = WinceStateGetWinidsByCurrentTab()
        for winid in uberwinids
            if index(preclosewinids, str2nr(winid)) < 0
                throw 'Model uberwin ID ' . winid . ' from group ' . a:grouptypename . ' not present in state'
            endif
        endfor
        call s:Log.DBG('State-closing uberwin group ', a:grouptypename)
        call WinceStateCloseUberwinsByGroupType(grouptype)
        let postclosewinids = WinceStateGetWinidsByCurrentTab()
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
        call WinceCommonUnshieldWindows(preshield)
    endtry
endfunction

" When windows are opened, Vim needs to choose which other windows to shrink
" to make room. Sometimes Vim makes choices I don't like, such as equalizing
" windows along the way. This function can be called before opening a window,
" to remember the dimensions of all the windows that are already open. The
" remembered dimensions can then be somewhat restored using
" WinceCommonRestoreDimensions
function! WinceCommonPreserveDimensions()
    call s:Log.DBG('WinceCommonPreserveDimensions')
    let winids = WinceStateGetWinidsByCurrentTab()
    let dims = WinceStateGetWinDimensionsList(winids)
    let windims = {}
    for idx in range(len(winids))
        let windims[winids[idx]] = dims[idx]
    endfor
    call s:Log.VRB('Preserved dimensions: ', windims)
    return windims
endfunction

function! s:CompareWinidsByWinnr(winid1, winid2)
        if !WinceStateWinExists(a:winid1) || !WinceStateWinExists(a:winid2)
            return 0
        endif
    let winnr1 = WinceStateGetWinnrByWinid(a:winid1)
    let winnr2 = WinceStateGetWinnrByWinid(a:winid2)
    return winnr1 == winnr2 ? 0 : winnr1 > winnr2 ? 1 : -1
endfunction
function! s:RestoreDimensionsByWinid(winid, olddims, prefertopleftdividers)
    call s:Log.VRB('RestoreDimensionsByWinid ', a:winid, ' ', a:olddims, ' ', a:prefertopleftdividers)
    let newdims = WinceStateGetWinDimensions(a:winid)
    " This function gets called only when there are no subwins, so any
    " non-supwin must be an uberwin.
    let isuberwin = (index(WinceModelSupwinIds(), str2nr(a:winid)) <# 0 )
    let fixed = WinceStateFixednessByWinid(a:winid)
    if a:olddims.w <# newdims.w || (isuberwin && fixed.w && a:olddims.w ># newdims.w)
        call s:Log.DBG('Set width for window ', a:winid, ' to ', a:olddims.w)
        call WinceStateResizeHorizontal(a:winid, a:olddims.w, a:prefertopleftdividers)
    endif
    if a:olddims.h <# newdims.h || (isuberwin && fixed.h && a:olddims.h ># newdims.h)
        call s:Log.DBG('Set height for window ', a:winid, ' to ', a:olddims.h)
        call WinceStateResizeVertical(a:winid, a:olddims.h, a:prefertopleftdividers)
    endif
endfunction
" Restore dimensions remembered with WinceCommonPreserveDimensions
function! WinceCommonRestoreDimensions(windims)
    call s:Log.DBG('WinceCommonRestoreDimensions')
    let sorted = copy(keys(a:windims))
    call sort(sorted, function('s:CompareWinidsByWinnr'))
    for winid in sorted
        if !WinceStateWinExists(winid)
            call s:Log.VRB('Window ', winid, ' no longer exists')
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
function! WinceCommonRecordAllDimensions()
    call s:Log.DBG('WinceCommonRecordAllDimensions')
    " Record all uberwin dimensions in the model
    for grouptypename in WinceModelShownUberwinGroupTypeNames()
        try
            let winids = WinceModelUberwinIdsByGroupTypeName(grouptypename)
            let dims = WinceStateGetWinDimensionsList(winids)
            call s:Log.DBG('Write state dimensions of uberwin group ', grouptypename, ' to model: ', dims)
            call WinceModelChangeUberwinGroupDimensions(grouptypename, dims)
        catch /.*/
            call s:Log.WRN('WinceCommonRecordAllDimensions found uberwin group ', grouptypename, ' inconsistent:')
            call s:Log.DBG(v:throwpoint)
            call s:Log.WRN(v:exception)
        endtry
    endfor

    " Record all supwin dimensions in the model
    for supwinid in WinceModelSupwinIds()
        try
            let dim = WinceStateGetWinDimensions(supwinid)
            call s:Log.DBG('Write state dimensions of supwin ', supwinid, ' to model: ', dim)
            call WinceModelChangeSupwinDimensions(supwinid, dim.nr, dim.w, dim.h)
        catch
            call s:Log.WRN('WinceCommonRecordAllDimensions found supwin ', supwinid, ' inconsistent:')
            call s:Log.DBG(v:throwpoint)
            call s:Log.WRN(v:exception)
        endtry

    " Record all subwin dimensions in the model
        let supwinnr = WinceStateGetWinnrByWinid(supwinid)
        for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            try
                let winids = WinceModelSubwinIdsByGroupTypeName(supwinid, grouptypename)
                let dims = WinceStateGetWinRelativeDimensionsList(winids, supwinnr)
                call s:Log.DBG('Write state dimensions of subwin group ', supwinid, ':', grouptypename, ' to model: ', dims)
                call WinceModelChangeSubwinGroupDimensions(supwinid, grouptypename, dims)
            catch /.*/
                call s:Log.WRN('WinceCommonRecordAllDimensions found subwin group ', grouptypename, ' for supwin ', supwinid, ' inconsistent:')
                call s:Log.DBG(v:throwpoint)
                call s:Log.WRN(v:exception)
            endtry
        endfor
    endfor
endfunction

" Wrapper for WinceStateOpenUberwinsByGroupType that freezes scroll positions
" and corrects dimensions for existing windows
function! WinceCommonOpenUberwins(grouptypename, correctdims)
    call s:Log.DBG('WinceCommonOpenUberwins ', a:grouptypename, ' ', a:correctdims)
    " Shielding only protects windows from scrolling when they are not
    " the current window, so explicitly save and restore the current
    " window's scroll position. Shielding is preferred for other
    " windows due to performance. This is the reason why it is required that
    " uberwin groups' toOpen callbacks not move the cursor before opening the
    " uberwin
    let curtopline = WinceStatePreserveScrollPosition()
    let curwin = WinceStateGetCursorWinId()

    let preshield = WinceCommonShieldAllWindows([])
    try
        if a:correctdims
            let windims = WinceCommonPreserveDimensions()
        endif
        try
            let grouptype = g:wince_uberwingrouptype[a:grouptypename]
            let winids = WinceStateOpenUberwinsByGroupType(grouptype)

        finally
            if a:correctdims
                call WinceCommonRestoreDimensions(windims)
            endif
        endtry

    finally
        call WinceCommonUnshieldWindows(preshield)

        " The ToOpen callback may have moved the cursor, so move it back
        " before restoring the scroll position
        call WinceStateMoveCursorToWinidSilently(curwin)

        " The scroll position must be restored after unshielding, or else it
        " may cause other windows to scroll
        call WinceStateRestoreScrollPosition(curtopline)
    endtry
    call s:Log.VRB('Opened uberwin group ', a:grouptypename, ' with winids ', winids)
    return winids
endfunction

" Closes all uberwins with priority higher than a given, and returns a list of
" group types closed. The model is unchanged.
function! WinceCommonCloseUberwinsWithHigherPriority(priority)
    call s:Log.DBG('WinceCommonCloseUberwinsWithHigherPriority ', a:priority)
    let grouptypenames = WinceModelUberwinGroupTypeNamesByMinPriority(a:priority)
    let preserved = []

    " grouptypenames is reversed so that we close uberwins in descending
    " priority order. See comments in WinceCommonCloseSubwinsWithHigherPriority
    let reversegrouptypenames = reverse(copy(grouptypenames))

    " Apply PreCloseAndReopenUberwins to all uberwins first, then close them
    " all. This is done because sometimes closing an uberwin will cause other
    " lower-priority uberwins' dimensions to change, and we don't want to
    " preserve those changes
    for grouptypename in reversegrouptypenames
        call s:Log.VRB('Uberwin group ', grouptypename, ' has higher priority')
        let pre = WinceCommonPreCloseAndReopenUberwins(grouptypename)
        call add(preserved, {'grouptypename':grouptypename,'pre':pre})
    endfor
    for grouptypename in reversegrouptypenames
        call WinceCommonCloseUberwinsByGroupTypeName(grouptypename)
    endfor
    return reverse(copy(preserved))
endfunction

" Reopens uberwins that were closed by WinceCommonCloseUberwinsWithHigherPriority
" and updates the model with the new winids
function! WinceCommonReopenUberwins(preserved, correctdims)
    call s:Log.DBG('WinceCommonReopenUberwins ', a:correctdims)
    " Open all uberwins first, then apply PostCloseAndReopenUberwins to them
    " all. This is done because sometimes opening an uberwin will cause other
    " lower-priority uberwins' dimensions to change, and we don't want that to
    " happen after they've been restored
    let winids = {}
    for grouptype in a:preserved
        call s:Log.DBG('Reopening preserved uberwin group ', grouptype.grouptypename)
        try
            let winids[grouptype.grouptypename] = WinceCommonOpenUberwins(grouptype.grouptypename, a:correctdims)
            call s:Log.VRB('Reopened uberwin group ', grouptype.grouptypename, ' with winids ', winids)
        catch /.*/
             call s:Log.WRN('WinceCommonReopenUberwins failed to open ', grouptype.grouptypename, ' uberwin group:')
             call s:Log.DBG(v:throwpoint)
             call s:Log.WRN(v:exception)
             call WinceModelHideUberwins(grouptype.grouptypename)
        endtry
    endfor
    for grouptype in a:preserved
        if has_key(winids, grouptype.grouptypename)
            call WinceModelChangeUberwinIds(grouptype.grouptypename, winids[grouptype.grouptypename])
            call WinceCommonPostCloseAndReopenUberwins(
           \    grouptype.grouptypename,
           \    grouptype.pre
           \)

            let dims = WinceStateGetWinDimensionsList(winids[grouptype.grouptypename])
            call WinceModelChangeUberwinGroupDimensions(grouptype.grouptypename, dims)
        endif
    endfor
endfunction

" Wrapper for WinceStateCloseSubwinsByGroupType that falls back to
" WinceStateCloseWindow if any subwins in the group are afterimaged
function! WinceCommonCloseSubwins(supwinid, grouptypename)
    call s:Log.DBG('WinceCommonCloseSubwins ', a:supwinid, ':', a:grouptypename)
    let preunfix = WinceStateUnfixDimensions(a:supwinid)
    try
        if WinceModelSubwinGroupHasAfterimagedSubwin(a:supwinid, a:grouptypename)
            call s:Log.DBG('Subwin group ', a:supwinid, ':', a:grouptypename, ' is partially afterimaged. Stomping subwins individually.')
            for subwinid in WinceModelSubwinIdsByGroupTypeName(
           \    a:supwinid,
           \    a:grouptypename
           \)
                call s:Log.VRB('Stomp subwin ', subwinid)
                call WinceStateCloseWindow(subwinid, g:wince_subwingrouptype[a:grouptypename].stompWithBelowRight)
            endfor

            " Here, afterimaged subwins are removed from the state but not from
            " the model. If they are opened again, they will not be afterimaged in
            " the state. So deafterimage them in the model.
            call WinceModelDeafterimageSubwinsByGroup(a:supwinid, a:grouptypename)
        else
            let grouptype = g:wince_subwingrouptype[a:grouptypename]
            let preclosewinids = WinceStateGetWinidsByCurrentTab()
            let subwinids = WinceModelSubwinIdsByGroupTypeName(a:supwinid, a:grouptypename)
            for winid in subwinids
                if index(preclosewinids, str2nr(winid)) < 0
                    throw 'Model subwin ID ' . winid . ' from group ' . a:supwinid . ':' . a:grouptypename . ' not present in state'
                endif
            endfor
            call s:Log.DBG('Subwin group ', a:supwinid, ':', a:grouptypename, ' is not afterimaged. Closing via toClose')
            call WinceStateCloseSubwinsByGroupType(a:supwinid, grouptype)
            let postclosewinids = WinceStateGetWinidsByCurrentTab()
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
        call WinceStateRefixDimensions(a:supwinid, preunfix)
    endtry
endfunction

" Wrapper for WinceStateOpenSubwinsByGroupType that uses a group type from the
" model
function! WinceCommonOpenSubwins(supwinid, grouptypename)
    call s:Log.DBG('WinceCommonOpenSubwins ', a:supwinid, ':', a:grouptypename)
    if WinceStateWinIsTerminal(a:supwinid)
        throw 'Supwin ' . a:supwinid . ' is a terminal window'
    endif
    let preunfix = WinceStateUnfixDimensions(a:supwinid)
    try
        let grouptype = g:wince_subwingrouptype[a:grouptypename]
        let winids = WinceStateOpenSubwinsByGroupType(a:supwinid, grouptype)
        call s:Log.VRB('Opened subwin group ', a:supwinid, ':', a:grouptypename, ' with winids ', winids)
    finally
        call WinceStateRefixDimensions(a:supwinid, preunfix)
    endtry
    return winids
endfunction

" Closes all subwins for a given supwin with priority higher than a given, and
" returns a list of group types closed. The model is unchanged.
function! WinceCommonCloseSubwinsWithHigherPriority(supwinid, priority)
    call s:Log.DBG('WinceCommonCloseSubwinsWithHigherPriority ', a:supwinid, ' ', a:priority)
    let grouptypenames = WinceModelSubwinGroupTypeNamesByMinPriority(
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
        call s:Log.VRB('Subwin group ', grouptypename, ' has higher priority')
        let pre = WinceCommonPreCloseAndReopenSubwins(a:supwinid, grouptypename)
        call add(preserved, {'grouptypename':grouptypename,'pre':pre})
        call WinceCommonCloseSubwins(a:supwinid, grouptypename)
    endfor
    return reverse(copy(preserved))
endfunction

" Reopens subwins that were closed by WinceCommonCloseSubwinsWithHigherPriority
" and updates the model with the new winids
function! WinceCommonReopenSubwins(supwinid, preserved)
    call s:Log.DBG('WinceCommonReopenSubwins ', a:supwinid)
    for grouptype in a:preserved
        call s:Log.DBG('Reopening preserved supwin group ', a:supwinid, ':', grouptype.grouptypename)
        try
            let winids = WinceCommonOpenSubwins(
           \    a:supwinid,
           \    grouptype.grouptypename
           \)
            call s:Log.VRB('Reopened subwin group ', a:supwinid, ':', grouptype.grouptypename, ' with winids ', winids)
            call WinceModelChangeSubwinIds(a:supwinid, grouptype.grouptypename, winids)
            call WinceCommonPostCloseAndReopenSubwins(
           \    a:supwinid,
           \    grouptype.grouptypename,
           \    grouptype.pre
           \)
            call WinceModelDeafterimageSubwinsByGroup(
           \    a:supwinid,
           \    grouptype.grouptypename
           \)

            let supwinnr = WinceStateGetWinnrByWinid(a:supwinid)
            let dims = WinceStateGetWinRelativeDimensionsList(winids, supwinnr)
            call WinceModelChangeSubwinGroupDimensions(
           \    a:supwinid,
           \    grouptype.grouptypename,
           \    dims
           \)
        catch /.*/
            call s:Log.WRN('WinceCommonReopenSubwins failed to open ', grouptype.grouptypename, ' subwin group for supwin ', a:supwinid, ':')
            call s:Log.DBG(v:throwpoint)
            call s:Log.WRN(v:exception)
            call WinceModelHideSubwins(a:supwinid, grouptype.grouptypename)
        endtry
    endfor
endfunction

function! WinceCommonPreCloseAndReopenUberwins(grouptypename)
    call s:Log.DBG('WinceCommonPreCloseAndReopenUberwins ', a:grouptypename)
    call WinceModelAssertUberwinGroupExists(a:grouptypename)
    let preserved = {}
    let curwinid = WinceStateGetCursorWinId()
    try
        for typename in g:wince_uberwingrouptype[a:grouptypename].typenames
            let winid = WinceModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            let preserved[typename] = WinceStatePreCloseAndReopen(winid)
            call s:Log.VRB('Preserved uberwin ', a:grouptypename, ':', typename, ' with winid ', winid, ': ', preserved[typename])
        endfor
    finally
        call WinceStateMoveCursorToWinidSilently(curwinid)
    endtry
    return preserved
endfunction

function! WinceCommonPostCloseAndReopenUberwins(grouptypename, preserved)
    call s:Log.DBG('WinceCommonPostCloseAndReopenUberwins ', a:grouptypename)
    call WinceModelAssertUberwinGroupExists(a:grouptypename)
    let curwinid = WinceStateGetCursorWinId()
    try
        for typename in keys(a:preserved)
            let winid = WinceModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            call s:Log.VRB('Restore uberwin ', a:grouptypename, ':', typename, ' with winid ', winid, ': ', a:preserved[typename])
            call WinceStatePostCloseAndReopen(winid, a:preserved[typename])
        endfor
    finally
        call WinceStateMoveCursorToWinidSilently(curwinid)
    endtry
endfunction

function! WinceCommonPreCloseAndReopenSubwins(supwinid, grouptypename)
    call s:Log.DBG('WinceCommonPreCloseAndReopenSubwins ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    let preserved = {}
    let curwinid = WinceStateGetCursorWinId()
        for typename in g:wince_subwingrouptype[a:grouptypename].typenames
            let winid = WinceModelIdByInfo({
           \    'category': 'subwin',
           \    'supwin': a:supwinid,
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            let preserved[typename] = WinceStatePreCloseAndReopen(winid)
            call s:Log.VRB('Preserved subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' with winid ', winid, ': ', preserved[typename])
        endfor
    call WinceStateMoveCursorToWinidSilently(curwinid)
    return preserved
endfunction

function! WinceCommonPostCloseAndReopenSubwins(supwinid, grouptypename, preserved)
    call s:Log.DBG('WinceCommonPostCloseAndReopenSubwins ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    let curwinid = WinceStateGetCursorWinId()
        for typename in keys(a:preserved)
            let winid = WinceModelIdByInfo({
           \    'category': 'subwin',
           \    'supwin': a:supwinid,
           \    'grouptype': a:grouptypename,
           \    'typename': typename
           \})
            call s:Log.VRB('Restore subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' with winid ', winid, ': ', a:preserved[typename])
            call WinceStatePostCloseAndReopen(winid, a:preserved[typename])
        endfor
    call WinceStateMoveCursorToWinidSilently(curwinid)
endfunction

" Closes and reopens all shown subwins of a given supwin with priority higher
" than a given
function! WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(supwinid, priority)
    call s:Log.DBG('WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin ', a:supwinid, ', ', a:priority)
    let preserved = WinceCommonCloseSubwinsWithHigherPriority(a:supwinid, a:priority)
    call s:Log.VRB('Preserved subwins across close-and-reopen: ', preserved)
    call WinceCommonReopenSubwins(a:supwinid, preserved)

    let dims = WinceStateGetWinDimensions(a:supwinid)
    call s:Log.VRB('New dimensions of closed-and-reopened subwins: ', dims)
    call WinceModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

" Closes and reopens all shown subwins of a given supwin
function! WinceCommonCloseAndReopenAllShownSubwinsBySupwin(supwinid)
    call s:Log.DBG('WinceCommonCloseAndReopenAllShownSubwinsBySupwin ', a:supwinid)
    call WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(a:supwinid, -1)
endfunction

" Afterimages all afterimaging non-afterimaged subwins of a non-hidden subwin group
function! WinceCommonAfterimageSubwinsByInfo(supwinid, grouptypename)
    call s:Log.DBG('WinceCommonAfterimageSubwinsByInfo ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    " Don't bother even moving to the supwin if all the afterimaging subwins in
    " the group are already afterimaged
    let afterimagingneeded = 0
    for typeidx in range(len(g:wince_subwingrouptype[a:grouptypename].typenames))
        let typename = g:wince_subwingrouptype[a:grouptypename].typenames[typeidx]
        if g:wince_subwingrouptype[a:grouptypename].afterimaging[typeidx] &&
       \   !WinceModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call s:Log.DBG('Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' needs afterimaging')
            let afterimagingneeded = 1
            break
        endif
        call s:Log.VRB('Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' is already afterimaged')
    endfor
    if !afterimagingneeded
        call s:Log.DBG('Subwin group ', a:supwinid, ':', a:grouptypename, ' requires no aftermimaging')
        return
    endif

    " To make sure the subwins are in a good state, start from their supwin
    call WinceStateMoveCursorToWinid(a:supwinid)

    " Each subwin type can be individually afterimaging, so deal with them one
    " by one
    for typeidx in range(len(g:wince_subwingrouptype[a:grouptypename].typenames))
        " Don't afterimage non-afterimaging subwins
        if !g:wince_subwingrouptype[a:grouptypename].afterimaging[typeidx]
            call s:Log.VRB('Subwin type ', a:grouptypename, ':', g:wince_subwingrouptype[a:grouptypename].typenames[typeidx], ' does not afterimage')
            continue
        endif

        " Don't afterimage subwins that are already afterimaged
        let typename = g:wince_subwingrouptype[a:grouptypename].typenames[typeidx]
        if WinceModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call s:Log.DBG('Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' is already afterimaged')
            continue
        endif
        
        " Get the subwin ID
        let subwinid = WinceModelIdByInfo({
       \    'category': 'subwin',
       \    'supwin': a:supwinid,
       \    'grouptype': a:grouptypename,
       \    'typename': typename
       \})

        call s:Log.DBG('Afterimaging subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' with winid ', subwinid)

        " Afterimage the subwin in the state
        let aibuf = WinceStateAfterimageWindow(subwinid)

        " Afterimage the subwin in the model
        call WinceModelAfterimageSubwin(a:supwinid, a:grouptypename, typename, aibuf)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged shown subwins of a supwin
function! WinceCommonAfterimageSubwinsBySupwin(supwinid)
    call s:Log.DBG('WinceCommonAfterimageSubwinsBySupwin ', a:supwinid)
    for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        call WinceCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged shown subwins of a subwin
" unless they belong to a given group
function! WinceCommonAfterimageSubwinsBySupwinExceptOne(supwinid, excludedgrouptypename)
    call s:Log.DBG('WinceCommonAfterimageSubwinsBySupwinExceptOne ', a:supwinid, ':', a:excludedgrouptypename)
    for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        if grouptypename !=# a:excludedgrouptypename
            call WinceCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
        endif
    endfor
endfunction

" Closes all subwin groups of a supwin that contain afterimaged subwins and reopens
" them as non-afterimaged
function! WinceCommonDeafterimageSubwinsBySupwin(supwinid)
    call s:Log.DBG('WinceCommonDeafterimageSubwinsBySupwin ', a:supwinid)
    for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        call s:Log.VRB('Subwin group ', a:supwinid, ':', grouptypename)
        if WinceModelSubwinGroupHasAfterimagedSubwin(a:supwinid, grouptypename)
            call s:Log.DBG(' Closing-and-reopening subwin groups of supwin ', a:supwinid, ' starting with partially afterimaged group ', grouptypename)
            let priority = g:wince_subwingrouptype[grouptypename].priority
            call WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
           \    a:supwinid,
           \    priority - 1
           \)
            return
        endif
    endfor
endfunction

function! WinceCommonUpdateAfterimagingByCursorWindow(curwin)
    call s:Log.DBG('WinceCommonUpdateAfterimagingByCursorWindow ', a:curwin)
    " If the given cursor is in a window that doesn't exist, place it in a
    " window that does exist
    let finalpos = WinceCommonReselectCursorWindow(a:curwin)

    " If the cursor's position is in an uberwin (or still in a window that
    " doesn't exist), afterimage all shown afterimaging subwins of all supwins
    if finalpos.category ==# 'uberwin' || finalpos.category ==# 'none'
        call s:Log.DBG('Cursor position is uberwin. Afterimaging all subwins of all supwins.')
        for supwinid in WinceModelSupwinIds()
            call WinceCommonAfterimageSubwinsBySupwin(supwinid)
        endfor

    " If the cursor's position is in a supwin, afterimage all
    " shown afterimaging subwins of all supwins except the one with
    " the cursor. Deafterimage all shown afterimaging subwins of the
    " supwin with the cursor.
    elseif finalpos.category ==# 'supwin'
        call s:Log.DBG('Cursor position is supwin ', finalpos.id, '. Afterimaging all subwins of all other supwins')
        for supwinid in WinceModelSupwinIds()
            if supwinid !=# finalpos.id
                call WinceCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
        call s:Log.DBG('Cursor position is supwin ', finalpos.id, '. Deafterimaging all its subwins. ')
        call WinceCommonDeafterimageSubwinsBySupwin(finalpos.id)

    " If the cursor's position is in a subwin, afterimage all
    " shown afterimaging subwins of all supwins except the one with
    " the subwin with the cursor. Also afterimage all shown
    " afterimaging subwins of the supwin with the subwin with the
    " cursor except for the ones in the group with the subwin with
    " the cursor. If the cursor is in a group with an afterimaging
    " subwin, Deafterimage that group. I had fun writing this
    " comment.
    elseif finalpos.category ==# 'subwin'
        call s:Log.DBG('Cursor position is subwin ', finalpos.supwin, ':', finalpos.grouptype, ':', finalpos.typename, '. Afterimaging all subwins of all other supwins.')
        for supwinid in WinceModelSupwinIds()
            if supwinid !=# finalpos.supwin
                call WinceCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
        call s:Log.DBG('Cursor position is subwin ', finalpos.supwin, ':', finalpos.grouptype, ':', finalpos.typename, '. Afterimaging all subwins of supwin ', finalpos.supwin, ' except those in group ', finalpos.supwin, ':', finalpos.grouptype)
        call WinceCommonDeafterimageSubwinsBySupwin(finalpos.supwin)
        call WinceCommonAfterimageSubwinsBySupwinExceptOne(
                    \    finalpos.supwin,
                    \    finalpos.grouptype
                    \)

    else
       throw 'Cursor final position ' . string(finalpos) . ' is neither uberwin nor supwin nor subwin'
    endif
endfunction

function! s:DoWithout(curwin, callback, args, nouberwins, nosubwins, reselect, preservesupdims)
    call s:Log.DBG('DoWithout ', a:curwin, ', ', a:callback, ', ', a:args, ', [', a:nouberwins, ',', a:nosubwins, ',', a:reselect, ',', a:preservesupdims, ']')
    let supwinids = WinceModelSupwinIds()
    let closedsubwingroupsbysupwin = {}
    for supwinid in supwinids
        let closedsubwingroupsbysupwin[supwinid] = []
    endfor

    let info = WinceCommonGetCursorPosition()
    call s:Log.DBG('Cursor position before removals is ', info)

    if a:nosubwins && !empty(supwinids)
        let startwith = supwinids[0]

        " If the cursor is in a supwin, start with it
        if a:curwin.category ==# 'supwin'
            call s:Log.VRB('Cursor is in supwin ', a:curwin.id, '. Its subwins will be closed first')
            let startwith = str2nr(a:curwin.id)

        " If the cursor is in a subwin, start with its supwin
        elseif a:curwin.category ==# 'subwin'
            call s:Log.VRB('Cursor is in subwin ', a:curwin.supwin, ':', a:curwin.grouptype, ':', a:curwin.typename, '. Subwins of supwin ', a:curwin.supwin, ' will be closed first')
            let startwith = str2nr(a:curwin.supwin)
        endif

        call remove(supwinids, index(supwinids, startwith))
        call insert(supwinids, startwith)

        call s:Log.DBG('Closing all subwins')
        for supwinid in supwinids
             let closedsubwingroupsbysupwin[supwinid] = 
            \    WinceCommonCloseSubwinsWithHigherPriority(supwinid, -1)
        endfor
    endif

    let pretabnr = WinceStateGetTabnr()
    let posttabnr = pretabnr
    try
        let closeduberwingroups = []
        if a:nouberwins
            call s:Log.DBG('Closing all uberwins')
            if a:preservesupdims
                let supdims = WinceCommonPreserveDimensions()
            endif
            let closeduberwingroups = WinceCommonCloseUberwinsWithHigherPriority(-1)
        endif
        try
            if type(a:curwin) ==# v:t_dict
                let winid = WinceModelIdByInfo(a:curwin)
                if WinceStateWinExists(winid)
                    call s:Log.DBG('Cursor window still exists. Moving to it.')
                    call WinceStateMoveCursorToWinid(winid)
                endif
            endif
            call s:Log.VRB('Invoking callback ', a:callback, ' with args ', a:args)
            let retval = call(a:callback, a:args)
            call s:Log.VRB('Callback gave return value ', retval)
            let info = WinceCommonGetCursorPosition()
            call s:Log.DBG('New cursor position after callback is ', info)
            let posttabnr = WinceStateGetTabnr()
            call s:Log.DBG('New tab after callback is ', posttabnr)

        finally
            if pretabnr !=# posttabnr
                call s:Log.DBG('Callback changed tab from ', pretabnr, ' to ', posttabnr, '. Returning before reopening.')
                call WinceStateGotoTab(pretabnr)
            endif
            call s:Log.DBG('Reopening all uberwins')
            call WinceCommonReopenUberwins(closeduberwingroups, !a:preservesupdims)
            if a:preservesupdims
                call WinceCommonRestoreDimensions(supdims)
            endif
        endtry

    finally
        call s:Log.DBG('Reopening all subwins')
        for supwinid in supwinids
            let newsupwinid = supwinid
            let gotopretabnr = 0
            if !WinceStateWinExists(supwinid)
                if pretabnr !=# posttabnr
                    " There is only one command that removes a window and ends
                    " in a different tab: WinMoveToNewTab. So if the control
                    " reaches here, the command is WinMoveToNewTab. We need to
                    " move the model's record of the supwin to the new tab's
                    " model, and also restore the state subwins in the new
                    " tab.
                    let supwindata = WinceModelRemoveSupwin(supwinid)
                    call WinceStateGotoTab(posttabnr)
                    call WinceModelRestoreSupwin(supwindata)
                    " This command changes the winid of the window being
                    " moved (even with legacy winids, because it wipes out
                    " window-local variables). So after moving the supwin
                    " record to the new tab's model, change its winid
                    " Immediately after wincmd T, the only window in the tab
                    " is the one that was moved
                    let newsupwinid = WinceStateGetCursorWinId()
                    call WinceModelReplaceWinid(supwinid, newsupwinid)
                    let gotopretabnr = 1
                    call s:Log.DBG('Supwin ', supwinid, ' has moved to tab ', posttabnr, ' and changed winid to ', newsupwinid, '. Restoring subwins there.')
                else
                    call s:Log.DBG('Supwin ', supwinid, ' has vanished from state. Not restoring its subwins.')
                    continue
                endif
            endif
            call s:Log.VRB('Reopening all subwins of supwin ', newsupwinid)
            call WinceCommonReopenSubwins(newsupwinid, closedsubwingroupsbysupwin[supwinid])
            let dims = WinceStateGetWinDimensions(newsupwinid)
            call s:Log.VRB('Supwin dimensions after reopening its subwins: ', dims)
            " Afterimage everything after finishing with each supwin to avoid collisions
            call s:Log.VRB('Afterimaging all reopened subwins of supwin ', newsupwinid, ' to avoid collisions with the next supwin')
            call WinceCommonAfterimageSubwinsBySupwin(newsupwinid)
            call WinceModelChangeSupwinDimensions(newsupwinid, dims.nr, dims.w, dims.h)
            if gotopretabnr
                call s:Log.DBG('Finished restoring subwins of supwin ', newsupwinid, ' in tab ', posttabnr, '. Returning to tab ', pretabnr)
                call WinceStateGotoTab(pretabnr)
            endif
        endfor
        if pretabnr !=# posttabnr
            call s:Log.DBG('Finished reopening. All afterimaging subwins afterimaged. Moving back to post-callback tab ', posttabnr)
            call WinceStateGotoTab(posttabnr)
        endif
        if a:reselect
            call WinceCommonRestoreCursorPosition(info)
            call WinceCommonUpdateAfterimagingByCursorWindow(info.win)
        else
            call WinceStateMoveCursorToWinid(info.win.id)
        endif
    endtry
    return retval
endfunction
function! WinceCommonDoWithoutUberwins(curwin, callback, args, reselect)
    call s:Log.DBG('WinceCommonDoWithoutUberwins ', a:curwin, ', ', a:callback, ', ', a:args, ', ', a:reselect)
    return s:DoWithout(a:curwin, a:callback, a:args, 1, 0, a:reselect, 0)
endfunction

function! WinceCommonDoWithoutSubwins(curwin, callback, args, reselect)
    call s:Log.DBG('WinceCommonDoWithoutSubwins ', a:curwin, ', ', a:callback, ', ', a:args, ', ', a:reselect)
    return s:DoWithout(a:curwin, a:callback, a:args, 0, 1, a:reselect, 0)
endfunction

function! WinceCommonDoWithoutUberwinsOrSubwins(curwin, callback, args, reselect, preservesupdims)
    call s:Log.DBG('WinceCommonDoWithoutUberwinsOrSubwins ', a:curwin, ', ', a:callback, ', ', a:args, ', ', a:reselect, ', ', a:preservesupdims)
    return s:DoWithout(a:curwin, a:callback, a:args, 1, 1, a:reselect, a:preservesupdims)
endfunction

function! s:Nop()
    call s:Log.DBG('Nop')
endfunction

" Closes and reopens all shown subwins in the current tab, afterimaging the
" afterimaging ones that need it
function! WinceCommonCloseAndReopenAllShownSubwins(curwin)
    call s:Log.DBG('WinceCommonCloseAndReopenAllShownSubwins ', a:curwin)
     call WinceCommonDoWithoutSubwins(a:curwin, function('s:Nop'), [], 1)
endfunction

" Returns a statusline-friendly string that will evaluate to the correct
" colour and flag for the given subwin group
" This code is awkward because statusline expressions cannot recurse
function! WinceCommonSubwinFlagStrByGroup(grouptypename)
    call s:Log.DBG('WinceCommonSubwinFlagStrByGroup ', a:grouptypename)
    let flagcol = WinceModelSubwinFlagCol(a:grouptypename)
    let winidexpr = 'WinceStateGetCursorWinId()'
    let flagexpr = 'WinceModelSubwinFlagByGroup(' .
   \               winidexpr .
   \               ",'" .
   \               a:grouptypename .
   \               "')"
    return '%' . flagcol . '*%{' . flagexpr . '}'
endfunction
