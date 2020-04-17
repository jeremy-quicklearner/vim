" Window infrastructure Resolve function
" See window.vim

" Internal conditions - flags used by different helpers to communicate with
" each other
let s:uberwinsaddedcond = 0
let s:supwinsaddedcond = 0
let s:subwinsaddedcond = 0

" Input conditions - flags that influence the resolver's behaviour, set before
" it runs
let t:winresolvetabenteredcond = 1

" Helpers
" Run all the toIdentify callbacks against a window until one of
" them succeeds. Return the model info obtained.
function! WinResolveIdentifyWindow(winid)
    " TODO: Special case: The window is an afterimaged subwin
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
           \   index(uberwinids, subwindict.supwin) >=# 0 ||
           \   index(subwinids, subwindict.supwin) >=# 0
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
            " TODO: Handle case where two uberwins of the same type are
            "       present?
            let uberwingroupinfo[wininfo.grouptype][wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'subwin'
            if !has_key(subwingroupinfo, wininfo.supwin)
                let subwingroupinfo[wininfo.supwin] = {}
            endif
            if !has_key(subwingroupinfo[wininfo.supwin], wininfo.grouptype)
                let subwingroupinfo[wininfo.supwin][wininfo.grouptype] = {}
            endif
            " TODO: Handle case where two subwins of the same type are present
            "       for the same supwin?
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
    
    " If any supwin is terminal window with shown subwins, mark them as
    " hidden in the model
    for supwinid in WinModelSupwinIds()
        if WinStateWinExists(supwinid)&& WinStateWinIsTerminal(supwinid)
            for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
                call WinModelHideSubwins(supwinid, grouptypename)
            endfor
        endif
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
    let modelsubwinids = WinModelSubwinIds()
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
            " TODO: toIdentify() consistency isn't required if the subwin is
            " afterimaged
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
    let s:uberwinsaddedcond = 1
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
           let s:subwinsaddedcond = 1
        endfor
    endfor
endfunction

" STEP 2 - Adjust the state so that it matches the model
function! s:WinResolveModelToState()
    " STEP 2.1: Purge the state of window that isn't in the model
    " TODO: Do something more civilized than stomping each window
    "       individually? So far it's ok but some other group type
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
           call WinStateCloseWindow(winid)
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
    "           something else after hte user operation or resolver last
    "           touched it. That touch may have put it in the wrong place. So
    "           any window in the model with non-dummy dimensions inconsistent
    "           with its state dimensions needs to be temporarily closed.
    " TODO: If any uberwins have dummy dimensions or non-dummy dimensions that
    "       are inconsistent with the state, remove them from the state
    "       along with any other shown uberwin groups with higher priority. Set flag
    "       X.

    " TODO: If flag X, add all shown subwin groups to set S of
    "       supwinid/grouptypename keys
    " TODO: Else, for all supwins in the model
    "       TODO: If the supwin has dummy dimensions or non-dummy dimensions
    "             that are inconsistent with the state, add all its shown
    "             subwin groups to set S 
    "       TODO: Else if any subwin of the supwin has dummy dimensions or
    "             non-dummy dimensions that are inconsistent with the state,
    "             add its group to set S along with all shown groups in the
    "             subwin with higher priority

    " TODO: Remove all subwin groups in set S from the state

    " STEP 2.3: Add any missing windows to the state, including those that
    "           were temporarily removed, in the correct places
    " TODO: If any shown uberwin in the model isn't in the state,
    "       add it to the state
    " TODO: If any shown subwin in the model isn't in the state,
    "       add it to the state
endfunction

" STEP 3: Record all window dimensions in the model
function! s:WinResolveRecordDimensions()
    " TODO STEP 3.1: Record all uberwin dimensions in the model
    " TODO STEP 3.2: Record all supwin dimensions in the model
    " TODO STEP 3.3: Record all subwin dimensions in the model
endfunction

" STEP 4: Afterimage any subwins that need it
function! s:WinResolveAfterimage()
    " TODO STEP 4.1: If the cursor is in a subwin, afterimage all shown
    "           afterimaging subwin groups of its supwin except the one
    "           containing the current window
    " TODO STEP 4.2: If the cursor is in a supwin, afterimage all shown
    "           afterimaging subwin groups of all supwins
    " TODO STEP 4.3: If the cursor is in an uberwin, afterimage all shown
    "           afterimaging subwin groups
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
        " A tab has been initialized. Run the tab-init pre-resolve callbacks
        for TabInitCallback in WinModelTabInitPreResolveCallbacks()
            call TabInitCallback()
        endfor
    endif

    " If this is the first time running the resolver after entering a tab, run
    " the appropriate callbacks
    if t:winresolvetabenteredcond
        for TabEnterCallback in WinModelTabEnterPreResolveCallbacks()
            call TabEnterCallback()
        endfor
        let t:winresolvetabenteredcond = 0
    endif

    " Run the pre-resolve callbacks
    for PreResolveCallback in WinModelPreResolveCallbacks()
        call PreResolveCallback()
    endfor

    " STEP 1: The state may have changed since the last WinResolve() call. Adapt the
    "         model to fit it.
    call s:WinResolveStateToModel()

    " Run the conditional callbacks
    if s:uberwinsaddedcond
        for UberwinsAddedCallback in WinModelUberwinsAddedResolveCallbacks()
            call UberwinsAddedCallback()
        endfor
        let s:uberwinsaddedcond = 0
    endif
    if s:supwinsaddedcond
        for SupwinsAddedCallback in WinModelSupwinsAddedResolveCallbacks()
            call SupwinsAddedCallback()
        endfor
        let s:supwinsaddedcond = 0
    endif
    if s:subwinsaddedcond
        for SubwinsAddedCallback in WinModelSubwinsAddedResolveCallbacks()
            call SubwinsAddedCallback()
        endfor
        let s:subwinsaddedcond = 0
    endif

    " Run the resolve callbacks
    for ResolveCallback in WinModelResolveCallbacks()
        call ResolveCallback()
    endfor

    " STEP 2: Now the model is the way it should be, so adjust the state to fit it.
    call s:WinResolveModelToState()

    " STEP 3: Now the state is the way it should be, so record the dimensions
    "         of all windows in the model
    call s:WinResolveRecordDimensions()

    " STEP 4: The model and state are now consistent. Afterimage any subwins
    "         that need it
    call s:WinResolveAfterimage()

    " Run the post-resolve callbacks
    for PostResolveCallback in WinModelPostResolveCallbacks()
        call PostResolveCallback()
    endfor

    let s:resolveIsRunning = 0
endfunction

" Since the resolve function runs as a CursorHold callback, autocmd events
" need to be explicitly signalled to it
augroup WinResolve
    autocmd!
    
    " Use the TabEnter event to detect when a tab has been entered
    autocmd TabEnter * let t:winresolvetabenteredcond = 1
augroup END
