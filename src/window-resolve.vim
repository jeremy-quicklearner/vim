" Window infrastructure Resolve function
" See window.vim

" The cursor's final position is used in multiple places
let s:curpos = {}

" Internal conditions - flags used by different helpers to communicate with
" each other
let s:supwinsaddedcond = 0

" Input conditions - flags that influence the resolver's behaviour, set before
" it runs
let t:winresolvetabenteredcond = 1

" Helpers

" If given the winid of an afterimaged subwin, return model info about the
" subwin
function! WinResolveIdentifyAfterimagedSubwin(winid)
    let wininfo = WinModelInfoById(a:winid)
    if wininfo.category ==# 'subwin' && 
   \   WinModelSubwinIsAfterimaged(
   \       wininfo.supwin,
   \       wininfo.grouptype,
   \       wininfo.typename
   \   ) &&
   \   WinModelSubwinAibufBySubwinId(a:winid) ==# WinStateGetBufnrByWinid(a:winid)
        return wininfo
    endif
    return {'category':'none','id':a:winid}
endfunction

" Run all the toIdentify callbacks against a window until one of
" them succeeds. Return the model info obtained.
function! WinResolveIdentifyWindow(winid)
    for uberwingrouptypename in keys(s:toIdentifyUberwins)
        let uberwintypename = s:toIdentifyUberwins[uberwingrouptypename](a:winid)
        if !empty(uberwintypename)
            return {
           \    'category': 'uberwin',
           \    'grouptype': uberwingrouptypename,
           \    'typename': uberwintypename,
           \    'id': a:winid
           \}
        endif
    endfor
    let uberwinids = WinModelUberwinIds()
    let subwinids = WinModelSubwinIds()
    for subwingrouptypename in keys(s:toIdentifySubwins)
        let subwindict = s:toIdentifySubwins[subwingrouptypename](a:winid)
        if !empty(subwindict)
            " If there is no supwin, or if the identified 'supwin' isn't a
            " supwin, the window we are identifying has no place in the model
            if subwindict.supwin ==# -1 ||
           \   index(uberwinids, str2nr(subwindict.supwin)) >=# 0 ||
           \   index(subwinids, str2nr(subwindict.supwin)) >=# 0
                return {'category':'none','id':a:winid}
            endif
            return {
           \    'category': 'subwin',
           \    'supwin': subwindict.supwin,
           \    'grouptype': subwingrouptypename,
           \    'typename': subwindict.typename,
           \    'id': a:winid
           \}
        endif
    endfor
    let aiinfo = WinResolveIdentifyAfterimagedSubwin(a:winid)
    if aiinfo.category !=# 'none'
        " No need to sanity check the 'supwin' field like above because this
        " information already comes from the model
        return aiinfo
    endif
    return {
   \    'category': 'supwin',
   \    'id': a:winid
   \}
endfunction

" Convert a list of window info dicts (as returned by
" WinResolveIdentifyWindow) and group them by category, supwin id, group
" type, and type. Any incomplete groups are dropped.
function! WinResolveGroupInfo(wininfos)
    let uberwingroupinfo = {}
    let subwingroupinfo = {}
    let supwininfo = []
    " Group the window info
    for wininfo in a:wininfos
        if wininfo.category ==# 'uberwin'
            if !has_key(uberwingroupinfo, wininfo.grouptype)
                let uberwingroupinfo[wininfo.grouptype] = {}
            endif
            " TODO? Handle case where two uberwins of the same type are
            "       present
            let uberwingroupinfo[wininfo.grouptype][wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'subwin'
            if !has_key(subwingroupinfo, wininfo.supwin)
                let subwingroupinfo[wininfo.supwin] = {}
            endif
            if !has_key(subwingroupinfo[wininfo.supwin], wininfo.grouptype)
                let subwingroupinfo[wininfo.supwin][wininfo.grouptype] = {}
            endif
            " TODO? Handle case where two subwins of the same type are present
            "       for the same supwin
            let subwingroupinfo[wininfo.supwin]
                              \[wininfo.grouptype]
                              \[wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'supwin'
            call add(supwininfo, wininfo.id)
        endif
    endfor

    " Validate groups. Prune any incomplete groups. Convert typename-keyed
    " winid dicts to lists
    for grouptypename in keys(uberwingroupinfo)
        for typename in keys(uberwingroupinfo[grouptypename])
            call WinModelAssertUberwinTypeExists(grouptypename, typename)
        endfor
        let uberwingroupinfo[grouptypename].winids = []
        for typename in WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
            if !has_key(uberwingroupinfo[grouptypename], typename)
                unlet uberwingroupinfo[grouptypename]
                break
            endif
            call add(uberwingroupinfo[grouptypename].winids,
                    \uberwingroupinfo[grouptypename][typename])
        endfor
    endfor
    for supwinid in keys(subwingroupinfo)
        for grouptypename in keys(subwingroupinfo[supwinid])
            for typename in keys(subwingroupinfo[supwinid][grouptypename])
                call WinModelAssertSubwinTypeExists(grouptypename, typename)
            endfor
            let subwingroupinfo[supwinid][grouptypename].winids = []
            for typename in WinModelSubwinTypeNamesByGroupTypeName(grouptypename)
                if !has_key(subwingroupinfo[supwinid][grouptypename], typename)
                    unlet subwingroupinfo[supwinid][grouptypename]
                    break
                endif
                call add(subwingroupinfo[supwinid][grouptypename].winids,
                        \subwingroupinfo[supwinid][grouptypename][typename])
            endfor
        endfor
    endfor
    return {'uberwin':uberwingroupinfo,'supwin':supwininfo,'subwin':subwingroupinfo}
endfunction

" Resolver steps
" STEP 1 - Adjust the model so it accounts for recent changes to the state
function! s:WinResolveStateToModel()
    " STEP 1.1: Terminal windows get special handling because the CursorHold event
    "           doesn't execute when the cursor is inside them
    " If any terminal window is listed in the model as an uberwin, mark that
    " uberwin group hidden in the model and relist the window as a supwin
    " If there are multiple uberwins in this group and only one of them is a
    " terminal window, then this change renders that uberwin group incomplete
    " and the non-terminal windows will be ignored in STEP 1.4, then cleaned
    " up in STEP 2.1
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        for typename in WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
            let winid = WinModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': grouptypename,
           \    'typename': typename
           \})
            if winid && WinStateWinIsTerminal(winid)
                call WinModelHideUberwins(grouptypename)
                call WinModelAddSupwin(winid, -1, -1, -1)
                let s:supwinsaddedcond = 1
                break
            endif
        endfor
    endfor
    
    " If any terminal window is listed in the model as a subwin, mark that
    " subwin group hidden in the model and relist the window as a supwin
    " If there are multiple subwins in this group and only one of them is a
    " terminal window, then this change renders that subwin group incomplete
    " and the non-terminal windows will be ignored in STEP 1.4, then cleaned
    " up in STEP 2.1
    for supwinid in WinModelSupwinIds()
        for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            for typename in WinModelSubwinTypeNamesByGroupTypeName(grouptypename)
                let winid = WinModelIdByInfo({
               \    'category': 'subwin',
               \    'supwin': supwinid,
               \    'grouptype': grouptypename,
               \    'typename': typename
               \})
                if winid && WinStateWinIsTerminal(winid)
                    call WinModelHideSubwins(supwinid, grouptypename)
                    call WinModelAddSupwin(winid, -1, -1, -1)
                    let s:supwinsaddedcond = 1
                    break
                endif
            endfor
        endfor
    endfor
    
    " STEP 1.2: If any window in the model isn't in the state, remove it from
    "           the model
    " If any uberwin group in the model isn't fully represented in the state,
    " mark it hidden in the model
    let modeluberwinids = WinModelUberwinIds()
    " Using a dict so no keys will be duplicated
    let uberwingrouptypestohide = {}
    for modeluberwinid in modeluberwinids
        if !WinStateWinExists(modeluberwinid)
           let tohide = WinModelInfoById(modeluberwinid)
           if tohide.category != 'uberwin'
               throw 'Inconsistency in model. ID ' . modeluberwinid . ' is both' .
              \      ' uberwin and ' . tohide.category       
           endif
           let uberwingrouptypestohide[tohide.grouptype] = ''
        endif
    endfor
    for tohide in keys(uberwingrouptypestohide)
         call WinModelHideUberwins(tohide)
    endfor

    " If any supwin in the model isn't in the state, remove it and its subwins
    " from the model
    let modelsupwinids = WinModelSupwinIds()
    for modelsupwinid in modelsupwinids
        if !WinStateWinExists(modelsupwinid)
            call WinModelRemoveSupwin(modelsupwinid)
        endif
    endfor

    " If any subwin group in the model isn't fully represented in the state,
    " mark it hidden in the model
    let modelsupwinids = WinModelSupwinIds()
    let modelsubwinids = WinModelSubwinIds()
    " Using a dict for each supwin so no keys will be duplicated
    let subwingrouptypestohidebysupwin = {}
    for modelsupwinid in modelsupwinids
        let subwingrouptypestohidebysupwin[modelsupwinid] = {}
    endfor
    for modelsubwinid in modelsubwinids
        if !WinStateWinExists(modelsubwinid)
            let tohide = WinModelInfoById(modelsubwinid)
            if tohide.category != 'subwin'
                throw 'Inconsistency in model. ID ' . modelsubwinid . ' is both' .
               \      ' subwin and ' . tohide.category
            endif
            let subwingrouptypestohidebysupwin[tohide.supwin][tohide.grouptype] = ''
        endif
    endfor
    for supwinid in keys(subwingrouptypestohidebysupwin)
        for subwingrouptypetohide in keys(subwingrouptypestohidebysupwin[supwinid])
            call WinModelHideSubwins(supwinid, subwingrouptypetohide)
        endfor
    endfor

    " STEP 1.3: If any uberwin or subwin in the state doesn't look the way the model
    "           says it should, then it becomes a supwin
    " If any window is listed in the model as an uberwin but doesn't
    " satisfy its type's constraints, mark the uberwin group hidden
    " in the model and relist the window as a supwin. 
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        for typename in WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
            let winid = WinModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': grouptypename,
           \    'typename': typename
           \})
            if s:toIdentifyUberwins[grouptypename](winid) !=# typename
                call WinModelHideUberwins(grouptypename)
                call WinModelAddSupwin(winid, -1, -1, -1)
                let s:supwinsaddedcond = 1
                break
            endif
        endfor
    endfor

    " If any window is listed in the model as a subwin but doesn't
    " satisfy its type's constraints, mark the subwin group hidden
    " in the model and relist the window as a supwin.
    for supwinid in WinModelSupwinIds()
        for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            for typename in WinModelSubwinTypeNamesByGroupTypeName(grouptypename)
                let winid = WinModelIdByInfo({
               \    'category': 'subwin',
               \    'supwin': supwinid,
               \    'grouptype': grouptypename,
               \    'typename': typename
               \})
                " toIdentify consistency isn't required if the subwin is
                " afterimaged
                if WinModelSubwinIsAfterimaged(supwinid, grouptypename, typename)
                    continue
                endif
                let identified = s:toIdentifySubwins[grouptypename](winid)
                if empty(identified) ||
                  \identified.supwin !=# supwinid ||
                  \identified.typename !=# typename
                    call WinModelHideSubwins(supwinid, grouptypename)
                    call WinModelAddSupwin(winid, -1, -1, -1)
                    let s:supwinsaddedcond = 1
                    break
                endif
            endfor
        endfor
    endfor

    " STEP 1.4: If any window in the state isn't in the model, add it to the model
    " All winids in the state
    let statewinids = WinStateGetWinidsByCurrentTab()
    " Winids in the state that aren't in the model
    let missingwinids = []
    for statewinid in statewinids
        if !WinModelWinExists(statewinid)
            call add(missingwinids, statewinid)
        endif
    endfor
    " Model info for those winids
    let missingwininfos = []
    for missingwinid in missingwinids
        let missingwininfo = WinResolveIdentifyWindow(missingwinid)
        if len(missingwininfo)
            call add(missingwininfos, missingwininfo)
        endif
    endfor
    " Model info for those winids, grouped by category, supwin id, group type,
    " and type
    let groupedmissingwininfo = WinResolveGroupInfo(missingwininfos)
    for uberwingrouptypename in keys(groupedmissingwininfo.uberwin)
        let winids = groupedmissingwininfo.uberwin[uberwingrouptypename].winids
        call WinModelAddOrShowUberwins(
       \    uberwingrouptypename,
       \    winids,
       \    []
       \)
    endfor
    for supwinid in groupedmissingwininfo.supwin
        call WinModelAddSupwin(supwinid, -1, -1, -1)
        let s:supwinsaddedcond = 1
    endfor
    for supwinid in keys(groupedmissingwininfo.subwin)
        if !WinModelSupwinExists(supwinid)
            continue
        endif
        for subwingrouptypename in keys(groupedmissingwininfo.subwin[supwinid])
            let winids = groupedmissingwininfo.subwin[supwinid][subwingrouptypename].winids
            let supwinnr = WinStateGetWinnrByWinid(supwinid)
            call WinModelAddOrShowSubwins(
           \    supwinid,
           \    subwingrouptypename,
           \    winids,
           \    []
           \)
        endfor
    endfor

    " STEP 1.5: Supwins that have become terminal windows need to have their
    " subwins hidden, but this must be done after STEP 1.4 which would add the
    " subwins back
    " If any supwin is a terminal window with shown subwins, mark them as
    " hidden in the model
    for supwinid in WinModelSupwinIds()
        if WinStateWinExists(supwinid) && WinStateWinIsTerminal(supwinid)
            for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
                call WinModelHideSubwins(supwinid, grouptypename)
            endfor
        endif
    endfor

endfunction

" STEP 2: Adjust the state so that it matches the model
function! s:WinResolveModelToState()
    " STEP 2.1: Purge the state of window that isn't in the model
    " TODO? Do something more civilized than stomping each window
    "       individually. So far it's ok but some other group type
    "       may require it in the future
    for winid in WinStateGetWinidsByCurrentTab()
        if !WinStateWinExists(winid)
            continue
        endif

        let wininfo = WinResolveIdentifyWindow(winid)

        " If any window in the state isn't categorizable, remove it from the
        " state
        if wininfo.category ==# 'none'
            call WinStateCloseWindow(winid)
            continue
        endif

        " If any supwin in the state isn't in the model, remove it from the
        " state.
        if wininfo.category ==# 'supwin' && !WinModelSupwinExists(wininfo.id)
            call WinStateCloseWindow(winid)
            continue
        endif

        " If any uberwin in the state isn't shown in the model, remove it
        " from the state.
        if wininfo.category ==# 'uberwin' && (
       \    !WinModelUberwinGroupExists(wininfo.grouptype) ||
       \    WinModelUberwinGroupIsHidden(wininfo.grouptype)
       \)
            call WinStateCloseWindow(winid)
            continue
        endif

        " If any subwin in the state isn't shown in the model, remove it from
        " the state
        if wininfo.category ==# 'subwin' && (
       \    !WinModelSupwinExists(wininfo.supwin) ||
       \    !WinModelSubwinGroupExists(wininfo.supwin, wininfo.grouptype) ||
       \    WinModelSubwinGroupIsHidden(wininfo.supwin, wininfo.grouptype)
       \)
           " If the supwin exists, freeze dimensions of all windows
           " outside it while closing. See comment in WinCommonCloseSubwins
           if WinModelSupwinExists(wininfo.supwin)
               let prefreeze = WinCommonFreezeAllWindowSizesOutsideSupwin(wininfo.supwin)
           endif

           call WinStateCloseWindow(winid)

           if WinModelSupwinExists(wininfo.supwin)
               call WinCommonThawWindowSizes(prefreeze)
           endif
           continue
        endif
    endfor

    " STEP 2.2: Temporarily close any windows that may be in the wrong place.
    "           Any window that was added in STEP 1 was added because it
    "           spontaneously appeared. It may have spontaneously appeared in
    "           the wrong place, so any window that was added in STEP 1 must
    "           be temporarily closed. STEP 1 is the only place where windows
    "           are added to the model with dummy dimensions, so any window in
    "           the model with dummy dimensions needs to be temporarily
    "           closed.
    "           Conversely, any window with non-dummy dimensions in the model
    "           has been touched by a user operation or by the previous
    "           execution of the resolver, which would have left its model
    "           dimensions consistent with its state dimensions. If there is
    "           an inconsistency, then the window has been touched by
    "           something else after the user operation or resolver last
    "           touched it. That touch may have put it in the wrong place. So
    "           any window in the model with non-dummy dimensions inconsistent
    "           with its state dimensions needs to be temporarily closed.
    "           Since a window can be anywhere, closing it may affect the
    "           dimensions of other windows and make them inconsistent after
    "           they've been checked already. So if we close a window, we need
    "           to make another pass.
    let preserveduberwins = {}
    let preservedsubwins = {}
    let passneeded = 1
    while passneeded
        let passneeded = 0
        " If any uberwins have dummy or inconsistent dimensions, remove them from the
        " state along with any other shown uberwin groups with higher priority.
        let uberwinsremoved = 0
        for grouptypename in WinModelShownUberwinGroupTypeNames()
            if WinCommonUberwinGroupExistsInState(grouptypename)
                if uberwinsremoved ||
               \   !WinCommonUberwinGroupDimensionsMatch(grouptypename)
                    let preserveduberwins[grouptypename] =
                   \    WinCommonPreCloseAndReopenUberwins(grouptypename)
                    call WinCommonCloseUberwinsByGroupTypeName(grouptypename)
                    let uberwinsremoved = 1
                    let passneeded = 1
                endif
            endif
        endfor

        let toremove = {}
        for supwinid in WinModelSupwinIds()
            let toremove[supwinid] = []
            " If we removed uberwins, flag all shown subwins for removal
            " Also flag all shown subwins of any supwin with dummy or inconsistent
            " dimensions
            if uberwinsremoved || !WinCommonSupwinDimensionsMatch(supwinid)
                let toremove[supwinid] = WinModelShownSubwinGroupTypeNamesBySupwinId(
               \    supwinid
               \)

            " Otherwise, if any subwin of the supwin has dummy or inconsistent
            " dimensions, flag that subwin's group along with all higher-priority
            " shown subwin groups in the supwin
            else
                let subwinsflagged = 0
                for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(
               \    supwinid
               \)
                    if WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
                        if subwinsflagged || !WinCommonSubwinGroupDimensionsMatch(
                       \    supwinid,
                       \    grouptypename
                       \)
                            call add(toremove[supwinid], grouptypename)
                            let subwinsflagged = 1
                        endif
                    endif
                endfor
            endif
        endfor

        " Remove all flagged subwins from the state
        for supwinid in keys(toremove)
            if !has_key(preservedsubwins, supwinid)
                let preservedsubwins[supwinid] = {}
            endif
            " toremove[supwinid] is reversed so that we close subwins in
            " descending priority order. See comments in
            " WinCommonCloseSubwinsWithHigherPriority
            for grouptypename in reverse(copy(toremove[supwinid]))
                if WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
                    let preservedsubwins[supwinid][grouptypename] =
                   \    WinCommonPreCloseAndReopenSubwins(supwinid, grouptypename)
                    call WinCommonCloseSubwins(supwinid, grouptypename)
                    let passneeded = 1
                endif
            endfor
        endfor
    endwhile

    " STEP 2.3: Add any missing windows to the state, including those that
    "           were temporarily removed, in the correct places
    " If any shown uberwin in the model isn't in the state,
    " add it to the state
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        if !WinCommonUberwinGroupExistsInState(grouptypename)
            try
                let winids = WinCommonOpenUberwins(grouptypename)
                " This Model write in ResolveModelToState is unfortunate, but I
                " see no sensible way to put it anywhere else
                call WinModelChangeUberwinIds(grouptypename, winids)
                if has_key(preserveduberwins, grouptypename)
                    call WinCommonPostCloseAndReopenUberwins(
                   \    grouptypename,
                   \    preserveduberwins[grouptypename]
                   \)
                endif
            catch /.*/
                call EchomLog('warning', 'Resolver step 2.3 failed to add ' . grouptypename . ' uberwin group to state:')
                call EchomLog('warning', v:exception)
                call WinModelHideUberwins(grouptypename)
            endtry
        endif
    endfor

    " If any shown subwin in the model isn't in the state,
    " add it to the state
    for supwinid in WinModelSupwinIds()
        for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            if !WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
                if WinModelSubwinGroupTypeHasAfterimagingSubwin(grouptypename)
                    " Afterimaging subwins may be state-open in at most one supwin
                    " at a time. So if we're opening an afterimaging subwin, it
                    " must first be afterimaged everywhere else.
                    for othersupwinid in WinModelSupwinIds()
                        if othersupwinid ==# supwinid
                            continue
                        endif
                        if WinModelSubwinGroupExists(
                       \    othersupwinid,
                       \    grouptypename
                       \) && !WinModelSubwinGroupIsHidden(
                       \    othersupwinid,
                       \    grouptypename
                       \) && !WinModelSubwinGroupHasAfterimagedSubwin(
                       \    othersupwinid,
                       \    grouptypename
                       \) && WinCommonSubwinGroupExistsInState(
                       \    othersupwinid,
                       \    grouptypename
                       \)
                            call WinCommonAfterimageSubwinsByInfo(
                           \    othersupwinid,
                           \    grouptypename
                           \)
                        endif
                    endfor
                endif
                try
                    let winids = WinCommonOpenSubwins(supwinid, grouptypename)
                    " This Model write in ResolveModelToState is unfortunate, but I
                    " see no sensible way to put it anywhere else
                    call WinModelChangeSubwinIds(supwinid, grouptypename, winids)
                    if has_key(preservedsubwins, supwinid) &&
                   \   has_key(preservedsubwins[supwinid], grouptypename)
                        call WinCommonPostCloseAndReopenSubwins(
                       \    supwinid,
                       \    grouptypename,
                       \    preservedsubwins[supwinid][grouptypename]
                       \)
                    endif
                catch /.*/
                    call EchomLog('warning', 'Resolver step 2.3 failed to add ' . grouptypename . ' subwin group to supwin ' . supwinid . ':')
                    call EchomLog('warning', v:exception)
                    call WinModelHideSubwins(supwinid, grouptypename)
                endtry
            endif
        endfor
    endfor
endfunction

" STEP 3: Make sure that the subwins are afterimaged according to the cursor's
"         final position
function! s:WinResolveCursor()
    call WinCommonUpdateAfterimagingByCursorWindow(s:curpos.win)
endfunction

" STEP 4: Record all window dimensions in the model
function! s:WinResolveRecordDimensions()
    " STEP 4.1: Record all uberwin dimensions in the model
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        try
            let winids = WinModelUberwinIdsByGroupTypeName(grouptypename)
            let dims = WinStateGetWinDimensionsList(winids)
            call WinModelChangeUberwinGroupDimensions(grouptypename, dims)
        catch /.*/
            call EchomLog('warning', 'Resolver step 4.1 found uberwin group ' . grouptypename . ' inconsistent:')
            call EchomLog('warning', v:exception)
        endtry
    endfor

    " STEP 4.2: Record all supwin dimensions in the model
    for supwinid in WinModelSupwinIds()
        try
            let dim = WinStateGetWinDimensions(supwinid)
            call WinModelChangeSupwinDimensions(supwinid, dim.nr, dim.w, dim.h)
        catch
            call EchomLog('warning', 'Resolver step 4.2 found supwin ' . supwinid . ' inconsistent:')
            call EchomLog('warning', v:exception)
        endtry

    " STEP 4.3: Record all subwin dimensions in the model
        let supwinnr = WinStateGetWinnrByWinid(supwinid)
        for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            try
                let winids = WinModelSubwinIdsByGroupTypeName(supwinid, grouptypename)
                let dims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
                call WinModelChangeSubwinGroupDimensions(supwinid, grouptypename, dims)
            catch /.*/
                call EchomLog('warning', 'Resolver step 4.3 found subwin group ' . grouptypename . ' for supwin ' . supwinid . ' inconsistent:')
                call EchomLog('warning', v:exception)
            endtry
        endfor
    endfor
endfunction

" Resolver
let s:resolveIsRunning = 0
function! WinResolve(arg)
    if s:resolveIsRunning
        return
    endif
    let s:resolveIsRunning = 1

    " Retrieve the toIdentify functions
    let s:toIdentifyUberwins = WinModelToIdentifyUberwins()
    let s:toIdentifySubwins = WinModelToIdentifySubwins()

    " STEP 0: Make sure the tab-specific model elements exist
    if !WinModelExists()
        call WinModelInit()
    endif

    " If this is the first time running the resolver after entering a tab, run
    " the appropriate callbacks
    if t:winresolvetabenteredcond
        for TabEnterCallback in WinModelTabEnterPreResolveCallbacks()
            call TabEnterCallback()
        endfor
        let t:winresolvetabenteredcond = 0
    endif

    " STEP 1: The state may have changed since the last WinResolve() call. Adapt the
    "         model to fit it.
    call s:WinResolveStateToModel()

    " Save the cursor position to be restored at the end of the resolver. This
    " is done here because the position is stored in terms of model keys which
    " may not have existed until now
    let s:curpos = WinCommonGetCursorPosition()

    " Run the supwin-added callbacks
    if s:supwinsaddedcond
        for SupwinsAddedCallback in WinModelSupwinsAddedResolveCallbacks()
            call SupwinsAddedCallback()
        endfor
        let s:supwinsaddedcond = 0
    endif

    " STEP 2: Now the model is the way it should be, so adjust the state to fit it.
    call s:WinResolveModelToState()

    " STEP 3: The model and state are now consistent with each other, but
    "         afterimaging may be inconsistent with the final position of the
    "         cursor. Make it consistent.
    call s:WinResolveCursor()

    " STEP 4: Now everything is consistent, so record the dimensions of all
    "         windows in the model. The next resolver run will consider those
    "         dimensions as being the last known consistent data, unless a
    "         user operation overwrites them with its own (also consistent)
    "         data.
    call s:WinResolveRecordDimensions()

    " Restore the cursor position from when the resolver started
    call WinCommonRestoreCursorPosition(s:curpos)
    let s:curpos = {}

    let s:resolveIsRunning = 0
endfunction

" Since the resolve function runs as a CursorHold callback, autocmd events
" need to be explicitly signalled to it
augroup WinResolve
    autocmd!
    
    " Use the TabEnter event to detect when a tab has been entered
    autocmd TabEnter * let t:winresolvetabenteredcond = 1
augroup END
