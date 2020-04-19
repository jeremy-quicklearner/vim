" Window manipulation code common to resolve function and user operations
" See window.vim

" Returns a data structure that encodes information about the window that the
" cursor is in
function! WinCommonGetCursorWinInfo()
    return WinModelInfoById(WinStateGetCursorWinId())
endfunction

" Returns true if winids listed in in the model for an uberwin group exist in
" the state
function! WinCommonUberwinGroupExistsInState(grouptypename)
    let winids = WinModelUberwinIdsByGroupTypeName(a:grouptypename)
    return WinStateWinExists(winids[0])
endfunction

" Returns true if winids listed in the model for a subwin group exist in the
" state
function! WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
    let winids = WinModelSubwinIdsByGroupTypeName(a:supwinid, a:grouptypename)
    return WinStateWinExists(winids[0])
endfunction

" Returns false if the dimensions in the model of any uberwin in a shown group of
" a given type are dummies or inconsistent with the state. True otherwise.
function! WinCommonUberwinGroupDimensionsMatch(grouptypename)
    for typename in WinModelUberwinTypeNamesByGroupTypeName(a:grouptypename)
        let mdims = WinModelUberwinDimensions(a:grouptypename, typename)
        if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
            return 0
        endif
        let winid = WinModelIdByInfo({
       \    'category':'uberwin',
       \    'grouptype':a:grouptypename,
       \    'typename':typename
       \})
        let sdims = WinStateGetWinDimensions(winid)
        if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
            return 0
        endif
    endfor
    return 1
endfunction

" Returns false if the dimensions in the model of a given supwin are dummies
" or inconsistent with the state. True otherwise.
function! WinCommonSupwinDimensionsMatch(supwinid)
    let mdims = WinModelSupwinDimensions(a:supwinid)
    if mdims.nr ==# -1 || mdims.w ==# -1 || mdims.h ==# -1
        return 0
    endif
    let sdims = WinStateGetWinDimensions(a:supwinid)
    if sdims.nr !=# mdims.nr || sdims.w !=# mdims.w || sdims.h !=# mdims.h
        return 0
    endif
    return 1
endfunction

" Returns false if the dimensions in the model of any subwin in a shown group of
" a given type for a given supwin are dummies or inconsistent with the state.
" True otherwise.
function! WinCommonSubwinGroupDimensionsMatch(supwinid, grouptypename)
    for typename in WinModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        let mdims = WinModelSubwinDimensions(a:supwinid, a:grouptypename, typename)
        if mdims.relnr ==# 0 || mdims.w ==# -1 || mdims.h ==# -1
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
            return 0
        endif
    endfor
    return 1
endfunction

" Get the window ID of the topmost leftmost supwin
function WinCommonFirstSupwinId()
    let minsupwinnr = 0
    let minsupwinid = 0
    for supwinid in WinModelSupwinIds()
        let winnr = WinStateGetWinnrByWinid(supwinid)
        if minsupwinnr ==# 0 || minsupwinnr < winnr
            let minsupwinnr = winnr
            let minsupwinid = supwinid
        endif
    endfor
    return minsupwinid
endfunction

" Get the window ID of the first uberwin in the lowest-priority shown uberwin
" group
function WinCommonFirstUberwinInfo()
    let grouptypenames = WinModelShownUberwinGroupTypeNames()
    if !grouptypenames
        return {'category':'none','id':0}
    endif
    let grouptypename = grouptypenames[0]
    let typename = g:uberwingrouptype[grouptypename].typenames[0]
    return {
   \    'category':'uberwin',
   \    'grouptype':grouptypename,
   \    'typename':typename
   \}
endfunction

" Given a cursor position remembered with WinCommonGetCursorWinInfo, return
" either the same position or an updated one if it doesn't exist anymore
function WinCommonReselectCursorPosition(oldpos)
    let pos = a:oldpos

    " If the cursor is in a nonexistent subwin, try to select its supwin
    if pos.category ==# 'subwin' &&
   \   !WinModelSubwinGroupExists(pos.supwin, pos.grouptype)
        let pos = {'category':'supwin','id':pos.supwin}
    endif

    " If all we have is a window ID, try looking it up
    if pos.category ==# 'none' || pos.category ==# 'supwin'
        let pos = WinModelInfoById(pos.id)
    endif

    " If we still have just a window ID, or if the cursor is in a nonexistent
    " supwin or uberwin, try to select the first supwin
    if pos.category ==# 'none' ||
   \   (pos.category ==# 'supwin' && !WinModelSupwinExists(pos.id)) ||
   \   (pos.category ==# 'uberwin' && !WinModelUberwinGroupExists(pos.grouptype))
        let firstsupwinid = WinCommonFirstSupwinId()
        if firstsupwinid
            let pos = {'category':'supwin','id':firstsupwinnr}
        endif
    endif

    " If we still have just a window ID, there are no supwins and therefore
    " also no subwins. Try to select the first uberwin.
    if pos.category ==# 'none' ||
   \   (pos.category ==# 'supwin' && !WinModelSupwinExists(pos.id))
        let pos = WinCommonFirstUberwinInfo()
    endif

    " If we still have no window ID, then there are no windows
    if pos.category ==# 'none'
        throw "No windows exist. Cannot select a window for the cursor."
    endif
    return pos

endfunction

" Moves the cursor to a window remembered with WinCommonGetCursorWinInfo. If
" the window no longer exists, go to the next best window as selected by
" WinCommonReselectCursorPosition
function! WinCommonRestoreCursorWinInfo(info)
    let newpos = WinCommonReselectCursorPosition(a:info)
    let winid = WinModelIdByInfo(newpos)
    call WinStateMoveCursorToWinid(winid)
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

" Wrapper for WinStateCloseSubwinsByGroupType that falls back to
" WinStateCloseWindow if any subwins in the group are afterimaged
function! WinCommonCloseSubwins(supwinid, grouptypename)
    if WinModelSubwinGroupHasAfterimagedSubwin(a:supwinid, a:grouptypename)
        for subwinid in WinModelSubwinIdsByGroupTypeName(a:supwinid, a:grouptypename)
            call WinStateCloseWindow(subwinid)
        endfor

        " Here, afterimaged subwins are removed from the state but not from
        " the model. If they are opened again, they will not be afterimaged in
        " the state. So deafterimage them in the model.
        call WinModelDeafterimageSubwinsByGroup(a:supwinid, a:grouptypename)
    else
        let grouptype = g:subwingrouptype[a:grouptypename]
        call WinStateCloseSubwinsByGroupType(a:supwinid, grouptype)
    endif
endfunction

" Closes all subwins for a given supwin with priority higher than a given, and
" returns a list of group types closed. The model is unchanged.
function! WinCommonCloseSubwinsWithHigherPriority(supwinid, priority)
    let grouptypenames = WinModelSubwinGroupTypeNamesByMinPriority(
   \    a:supwinid,
   \    a:priority
   \)
    for grouptypename in grouptypenames
        call WinCommonCloseSubwins(a:supwinid, grouptypename)
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
        call WinModelDeafterimageSubwinsByGroup(a:supwinid, grouptypename)

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

" Afterimages all afterimaging non-afterimaged subwins of a non-hidden subwin group
function! WinCommonAfterimageSubwinsByInfo(supwinid, grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    " Don't bother even moving to the supwin if all the afterimaging subwins in
    " the group are already afterimaged
    let afterimagingneeded = 0
    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        if g:subwingrouptype[a:grouptypename].afterimaging[typeidx] &&
       \   !WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
           let afterimagingneeded = 1
           break
        endif
    endfor
    if !afterimagingneeded
        return
    endif

    " To make sure the subwins are in a good state, start from their supwin
     call WinStateMoveCursorToWinid(a:supwinid)

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
        " Silent movement (noautocmd) is used here because we want to preserve the
        " state of the window exactly as it was when the function was first
        " called, and autocmds may fire on win_gotoid that change the state
        " TODO: Try commenting out this line. It probably isn't needed
        call WinStateMoveCursorToWinidSilently(a:supwinid)

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

" Afterimages all afterimaging non-afterimaged shown subwins of a supwin
function! WinCommonAfterimageSubwinsBySupwin(supwinid)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        call WinCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
    endfor
endfunction

" Afterimages all afterimaging non-afterimaged shown subwins of a subwin
" unless they belong to a given group
function! WinCommonAfterimageSubwinsBySupwinExceptOne(supwinid, excludedgrouptypename)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        if grouptypename !=# a:excludedgrouptypename
            call WinCommonAfterimageSubwinsByInfo(a:supwinid, grouptypename)
        endif
    endfor
endfunction

" Closes all subwin groups of a supwin that contain afterimaged subwins and reopens
" them as non-afterimaged
function! WinCommonDeafterimageSubwinsBySupwin(supwinid)
    for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(a:supwinid)
        if WinModelSubwinGroupHasAfterimagedSubwin(a:supwinid, grouptypename)
            let priority = g:subwingrouptype[grouptypename].priority
            call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
           \    a:supwinid,
           \    priority - 1
           \)
            return
        endif
    endfor
endfunction

function! WinCommonUpdateAfterimagingByCursorPosition(curpos)
    " If the given cursor is in a window that doesn't exist, place it in a
    " window that does exist
    let finalpos = WinCommonReselectCursorPosition(a:curpos)

    " If the cursor's position is in an uberwin, afterimage
    " all shown afterimaging subwins of all supwins
    if finalpos.category ==# 'uberwin'
        for supwinid in WinModelSupwinIds()
            call WinCommonAfterimageSubwinsBySupwin(supwinid)
        endfor

    " If the cursor's position is in a supwin, afterimage all
    " shown afterimaging subwins of all supwins except the one with
    " the cursor. Deafterimage all shown afterimaging subwins of the
    " supwin with the cursor.
    elseif finalpos.category ==# 'supwin'
        for supwinid in WinModelSupwinIds()
            if supwinid !=# finalpos.id
                call WinCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
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
        for supwinid in WinModelSupwinIds()
            if supwinid !=# finalpos.supwin
                call WinCommonAfterimageSubwinsBySupwin(supwinid)
            endif
        endfor
        call WinCommonDeafterimageSubwinsBySupwin(finalpos.supwin)
        call WinCommonAfterimageSubwinsBySupwinExceptOne(
                    \    finalpos.supwin,
                    \    finalpos.grouptype
                    \)

    else
        echom string(finalpos)
        throw 'Cursor final position is neither uberwin nor supwin nor subwin'
    endif
endfunction

" Closes and reopens all shown subwins in the current tab, afterimaging the
" afterimaging ones that need it
function! WinCommonCloseAndReopenAllShownSubwins()
    for supwinid in WinModelSupwinIds()
        call WinCommonCloseAndReopenAllShownSubwinsBySupwin(supwinid)
        " Afterimage everything after finishing with each supwin to avoid collisions
        call WinCommonAfterimageSubwinsBySupwin(supwinid)
    endfor
    " Deafterimage everything that needs it
    call WinCommonUpdateAfterimagingByCursorPosition(WinCommonGetCursorWinInfo())
endfunction

