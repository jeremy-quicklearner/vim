" Window manipulation code common to resolve function and user operations
" See window.vim

" Returns a data structure that encodes information about the window that the
" cursor is in
function! WinCommonGetCursorPosition()
    return {
   \    'win':WinModelInfoById(WinStateGetCursorWinId()),
   \    'cur':WinStateGetCursorPosition()
   \}
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
function! WinCommonFirstSupwinId()
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
function! WinCommonFirstUberwinInfo()
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

" Given a cursor position remembered with WinCommonGetCursorPosition, return
" either the same position or an updated one if it doesn't exist anymore
function! WinCommonReselectCursorWindow(oldpos)
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
            let pos = {'category':'supwin','id':firstsupwinid}
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

" Freeze the width and height of all windows except for a given supwin and its
" subwins. Return information about the frozen windows' previous settings so
" that they can later be thawed
function! WinCommonFreezeAllWindowSizesOutsideSupwin(immunesupwinid)
    let immunewinids = [str2nr(a:immunesupwinid)]
    for subwinid in WinModelShownSubwinIdsBySupwinId(a:immunesupwinid)
        call add(immunewinids, str2nr(subwinid))
    endfor

    let prefreeze = {}
    for winid in WinStateGetWinidsByCurrentTab()
        if index(immunewinids, str2nr(winid)) < 0
            let prefreeze[winid] = WinStateFreezeWindowSize(winid)
        endif
    endfor
    
    return prefreeze
endfunction

" Thaw the height and width of all windows that were frozen with
" WinCommonFreezeAllWindowSizesOutsideSupwin()
function! WinCommonThawWindowSizes(prefreeze)
    for winid in keys(a:prefreeze)
        call WinStateThawWindowSize(winid, a:prefreeze[winid])
    endfor
endfunction

" Moves the cursor to a window remembered with WinCommonGetCursorPosition. If
" the window no longer exists, go to the next best window as selected by
" WinCommonReselectCursorWindow
function! WinCommonRestoreCursorPosition(info)
    let newpos = WinCommonReselectCursorWindow(a:info.win)
    let winid = WinModelIdByInfo(newpos)
    call WinStateMoveCursorToWinid(winid)
    call WinStateRestoreCursorPosition(a:info.cur)
endfunction

" Closes all uberwins with priority higher than a given, and returns a list of
" group types closed. The model is unchanged.
function! WinCommonCloseUberwinsWithHigherPriority(priority)
    let grouptypenames = WinModelUberwinGroupTypeNamesByMinPriority(a:priority)
    " grouptypenames is revsersed so that we close uberwins in descending
    " priority order. See comments in WinCommonCloseSubwinsWithHigherPriority
    for grouptypename in reverse(copy(grouptypenames))
        call WinStateCloseUberwinsByGroupType(g:uberwingrouptype[grouptypename])
    endfor
    return grouptypenames
endfunction

" Reopens uberwins that were closed by WinCommonCloseUberwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenUberwins(grouptypenames)
    for grouptypename in a:grouptypenames
        try
            let winids = WinStateOpenUberwinsByGroupType(
           \    g:uberwingrouptype[a:grouptypename]
           \)
            call WinModelChangeUberwinIds(grouptypename, winids)

            let dims = WinStateGetWinDimensionsList(winids)
            call WinModelChangeUberwinGroupDimensions(grouptypename, dims)
        catch /.*/
            echom 'WinCommonReopenUberwins failed to open ' . grouptypename . ' uberwin group:'
            echohl ErrorMsg | echo v:exception | echohl None
            call WinModelHideUberwins(a:grouptypename)
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
    let prefreeze = WinCommonFreezeAllWindowSizesOutsideSupwin(a:supwinid)

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

    call WinCommonThawWindowSizes(prefreeze)
endfunction

" Wrapper for WinStateOpenSubwinsByGroupType that freezes windows whose
" dimensions shouldn't change
function! WinCommonOpenSubwins(supwinid, grouptypename)
    let prefreeze = WinCommonFreezeAllWindowSizesOutsideSupwin(a:supwinid)
        let grouptype = g:subwingrouptype[a:grouptypename]
        let winids = WinStateOpenSubwinsByGroupType(a:supwinid, grouptype)
    call WinCommonThawWindowSizes(prefreeze)
    return winids
endfunction

" Closes all subwins for a given supwin with priority higher than a given, and
" returns a list of group types closed. The model is unchanged.
function! WinCommonCloseSubwinsWithHigherPriority(supwinid, priority)
    let grouptypenames = WinModelSubwinGroupTypeNamesByMinPriority(
   \    a:supwinid,
   \    a:priority
   \)

    " grouptypenames is reversed because Vim sometimes makes strange decisions
    " when deciding which windows will fill the space left behind by a window
    " that closes. Assuming that subwins in ascending priority open from the
    " outside in (which is the intent underpinning the notion of subwin
    " priorities), closing them in descending priority order means closing
    " them from the inside out. This means that a subwin will never have to
    " stretch to fill the space left behind - only the supwin will stretch.
    " I don't fully understand why, but relaxing that constraint and allowing
    " subwins to stretch causes strange behaviour with other supwins filling
    " the space left by supwins closing after they have stretched.
    for grouptypename in reverse(copy(grouptypenames))
        call WinCommonCloseSubwins(a:supwinid, grouptypename)
    endfor
    return grouptypenames
endfunction

" Reopens subwins that were closed by WinCommonCloseSubwinsWithHigherPriority
" and updates the model with the new winids
function! WinCommonReopenSubwins(supwinid, grouptypenames)
    for grouptypename in a:grouptypenames
        try
            let winids = WinCommonOpenSubwins(
           \    a:supwinid,
           \    grouptypename
           \)
            call WinModelChangeSubwinIds(a:supwinid, grouptypename, winids)
            call WinModelDeafterimageSubwinsByGroup(a:supwinid, grouptypename)

            let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
            let dims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
            call WinModelChangeSubwinGroupDimensions(a:supwinid, grouptypename, dims)
        catch /.*/
            echom 'WinCommonReopenSubwins failed to open ' . grouptypename . ' subwin group for supwin ' . a:supwinid . ':'

            echohl ErrorMsg | echo v:exception | echohl None
            call WinModelHideSubwins(a:supwinid, a:grouptypename)
        endtry
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

function! WinCommonUpdateAfterimagingByCursorWindow(curwin)
    " If the given cursor is in a window that doesn't exist, place it in a
    " window that does exist
    let finalpos = WinCommonReselectCursorWindow(a:curwin)

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

function! s:DoWithout(curwin, callback, nouberwins, nosubwins)
    if a:nosubwins
        let closedsubwingroupsbysupwin = {}

        let supwinids = WinModelSupwinIds()
        if empty(supwinids)
            return
        endif

        let startwith = supwinids[0]

        " If the cursor is in a supwin, start with it
        if a:curwin.category ==# 'supwin'
            let startwith = str2nr(a:curwin.id)

        " If the cursor is in a subwin, start with its supwin
        elseif a:curwin.category ==# 'subwin'
            let startwith = str2nr(a:curwin.supwin)
        endif

        call remove(supwinids, index(supwinids, startwith))
        call insert(supwinids, startwith)

        for supwinid in supwinids
             let closedsubwingroupsbysupwin[supwinid] = 
            \    WinCommonCloseSubwinsWithHigherPriority(supwinid, -1)
        endfor
    endif

    if a:nouberwins
        let closeduberwingroups = WinCommonCloseUberwinsWithHigherPriority(-1)
    endif

    if type(a:curwin) ==# v:t_dict
        call WinStateMoveCursorToWinid(WinModelIdByInfo(a:curwin))
    endif
    call call(a:callback, [])

    if a:nouberwins
        call WinCommonReopenUberwins(closeduberwingroups)
    endif

    if a:nosubwins
        for supwinid in supwinids
            call WinCommonReopenSubwins(supwinid, closedsubwingroupsbysupwin[supwinid])
            let dims = WinStateGetWinDimensions(supwinid)
            " Afterimage everything after finishing with each supwin to avoid collisions
            call WinCommonAfterimageSubwinsBySupwin(supwinid)
            call WinModelChangeSupwinDimensions(supwinid, dims.nr, dims.w, dims.h)
        endfor
        call WinCommonUpdateAfterimagingByCursorWindow(a:curwin)
    endif
endfunction
function! WinCommonDoWithoutUberwins(callback)
    call s:DoWithout(0, a:callback, 1, 0)
endfunction

function! WinCommonDoWithoutSubwins(curwin, callback)
    call s:DoWithout(a:curwin, a:callback, 0, 1)
endfunction

function! WinCommonDoWithoutUberwinsOrSubwins(curwin, callback)
    call s:DoWithout(a:curwin, a:callback, 1, 1)
endfunction

function! s:Nop()
endfunction

" Closes and reopens all shown subwins in the current tab, afterimaging the
" afterimaging ones that need it
function! WinCommonCloseAndReopenAllShownSubwins(curwin)
     call WinCommonDoWithoutSubwins(a:curwin, function('s:Nop'))
endfunction

" Returns a statusline-friendly string that will evaluate to the correct
" colour and flag for the given subwin group
" This code is awkward because statusline expressions cannot recurse
function! WinCommonSubwinFlagStrByGroup(grouptypename)
    let flagcol = WinModelSubwinFlagCol(a:grouptypename)
    let winidexpr = 'WinStateGetCursorWinId()'
    let flagexpr = 'WinModelSubwinFlagByGroup(' .
   \               winidexpr .
   \               ",'" .
   \               a:grouptypename .
   \               "')"
    return '%' . flagcol . '*%{' . flagexpr . '}'
endfunction
