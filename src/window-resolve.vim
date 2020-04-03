" Window infrastructure Resolve function
" See window.vim

let s:uberwinsaddedcond = 0
let s:supwinsaddedcond = 0
let s:subwinsaddedcond = 0
let t:winresolvetabenteredcond = 1
function! s:WinResolveStateToModel()
    " STEP 1.1: Terminal windows get special handling because the CursorHold event
    "           doesn't execute when the cursor is inside them
    " TODO: If any terminal window is listed in the model as an uberwin, mark that
    "       uberwin group hidden in the model and relist the window as a supwin
    " TODO: If any terminal window is listed in the model as a subwin, mark that
    "       subwin group hidden in the model and relist the window as a supwin
    " TODO: If any terminal window has non-hidden subwins, mark them as
    "       terminal-hidden in the model
    " TODO: If any non-terminal window has terminal-hidden subwins, mark those
    "       subwins as shown in the model
    " TODO: If any window is listed in the model as an uberwin but doesn't
    "       satisfy its type's constraints, mark the uberwin group hidden
    "       in the model and relist the window as a supwin
    " TODO: If any window is listed in the model as a subwin but doesn't
    "       satisfy its type's constraints, mark the subwin group hidden
    "       in the model and relist the window as a supwin. Remember to set
    "       s:supwinsaddedcond = 1

    " STEP 1.2: If any window in the state isn't in the model, add it to the model
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
    let missingwininfo = []
    let toIdentifyUberwins = WinModelToIdentifyUberwins()
    let toIdentifySubwins = WinModelToIdentifySubwins()
    let currentwininfo = WinCommonGetCursorWinInfo()
       for missingwinid in missingwinids
           call WinStateMoveCursorToWinid(missingwinid)
           call add(missingwininfo,
                   \WinCommonIdentifyCurrentWindow(toIdentifyUberwins,
                                                  \toIdentifySubwins))
       endfor
    call WinCommonRestoreCursorWinInfo(currentwininfo)
    " Model info for those winids, grouped by category, supwin id, group type,
    " and type
    let groupedmissingwininfo = WinCommonGroupInfo(missingwininfo)
    for uberwingrouptypename in keys(groupedmissingwininfo.uberwin)
        call WinModelAddOrShowUberwins(
       \    uberwingrouptypename,
       \    groupedmissingwininfo.uberwin[uberwingrouptypename].winids
       \)
    endfor
    let s:uberwinsaddedcond = 1
    for supwinid in groupedmissingwininfo.supwin
        call WinModelAddSupwin(supwinid)
        let s:supwinsaddedcond = 1
    endfor
    for supwinid in keys(groupedmissingwininfo.subwin)
        for subwingrouptypename in keys(groupedmissingwininfo.subwin[supwinid])
            call WinModelAddOrShowSubwins(
           \    supwinid,
           \    subwingrouptypename,
           \    groupedmissingwininfo.subwin[supwinid][subwingrouptypename].winids
           \)
           let s:subwinsaddedcond = 1
        endfor
    endfor
    " TODO: Figure out how to reopen higher-priority windows from here?

    " STEP 1.3: If any window in the model isn't in the state, remove it from
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

    " If any supwin in the model isn't in the state, remove it and its subwins
    " from the model
    for modelsupwinid in modelsupwinids
        if !WinStateWinExists(modelsupwinid)
            call WinModelRemoveSupwin(modelsupwinid)
        endif
    endfor
endfunction

function! s:WinResolveModelToState()
    " STEP 2.1: Purge the state of windows that isn't in the model
    " TODO: If any supwin in the state isn't in the model, remove it from the
    "       state.
    " TODO: If any uberwin in the state isn't shown in the model, remove it
    "       from the state.
    " TODO: If any subwin in the state isn't shown in the model, remove it
    "       from the state

    " STEP 2.2: Temporarily close any windows that may have moved, so that
    "           they can later be reopened in their correct places
    " TODO: If any uberwin's dimensions or position have changed, remove that
    "       uberwin's group and all groups with lower priorities from the state
    " TODO: If any supwin's dimensions or position has changed, remove all of
    "       that supwin's subwins from the state
    " TODO: If any subwin's dimensions or positions have changed, remove that
    "       subwin's group and all groups with lower priorities from the state

    " STEP 2.3: Add any missing windows to the state, including those that
    "           were temporarily removed, in the correct places
    " TODO: If any non-hidden uberwin in the model isn't in the state,
    "       add it to the state
    " TODO: If any non-hidden subwin in the model isn't in the state,
    "       add it to the state
endfunction

" The resolve function
let s:resolveIsRunning = 0
function! WinResolve(arg)
    if s:resolveIsRunning
        return
    endif
    let s:resolveIsRunning = 1

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
