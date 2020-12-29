" Wince Resolver
" See wince.vim
let s:Log = jer_log#LogFunctions('wince-resolve')

" Internal variables - used by different helpers to communicate with each other
let s:curpos = {}
let s:relistedcond = 0
let s:nonsupwincache = {}

" Input conditions - flags that influence the resolver's behaviour, set before
" it runs
let t:wince_resolvetabenteredcond = 1

" Helpers

" If given the winid of an afterimaged subwin, return model info about the
" subwin
function! WinceResolveIdentifyAfterimagedSubwin(winid)
    call s:Log.VRB('WinceResolveIdentifyAfterimagedSubwin ', a:winid)
    let wininfo = WinceModelInfoById(a:winid)
    if wininfo.category ==# 'subwin' && 
   \   WinceModelSubwinAibufBySubwinId(a:winid) ==#
   \   WinceStateGetBufnrByWinidOrWinnr(a:winid)
        call s:Log.VRB('Afterimaged subwin identified as ', wininfo)
        return wininfo
    endif
    call s:Log.VRB('Window ', a:winid, 'not identifiable as afterimaged subwin')
    return {'category':'none','id':a:winid}
endfunction


" Run all the toIdentify callbacks against a window until one of
" them succeeds. Return the model info obtained.
function! s:IdentifyWindow(winid)
    call s:Log.DBG('IdentifyWindow ', a:winid)

    " While validating info for a subwin, we need to make sure that its listed
    " supwin really is a supwin. This operation needs to consider every non-supwin
    " winid in the model, and it's done lots of time, so it's worth doing some
    " caching. This dict contains every non-supwin model winid in its keys, and
    " should be invalidated with every model write.
    if empty(s:nonsupwincache)
        let uberwinids = WinceModelUberwinIds()
        let subwinids = WinceModelSubwinIds()
        for uberwinid in uberwinids
            let s:nonsupwincache[uberwinid] = 1
        endfor
        for subwinid in subwinids
            let s:nonsupwincache[subwinid] = 1
        endfor
    endif

    " If the state and model for this window are consistent, we can save lots
    " of time by just confirming that the model info is accurate to the state.
    " Unfortunately this can't be done with supwins because a supwin is only
    " identifiable by confirming that it doesn't satisfy ANY uberwin or subwin
    " conditions
    if WinceModelWinExists(a:winid)
        let modelinfo = WinceModelInfoById(a:winid)
        if modelinfo.category ==# 'uberwin'
            if s:toIdentifyUberwins[modelinfo.grouptype](a:winid) ==# modelinfo.typename
                call s:Log.DBG('Model info for window ', a:winid, ' confirmed in state as uberwin ', modelinfo.grouptype, ':', modelinfo.typename)
                let modelinfo.id = a:winid
                return modelinfo
            endif
        elseif modelinfo.category ==# 'subwin'
            let stateinfo = s:toIdentifySubwins[modelinfo.grouptype](a:winid)
            let modelsupwinid = modelinfo.supwin
            if !empty(stateinfo) &&
           \   stateinfo.typename ==# modelinfo.typename &&
           \   stateinfo.supwin ==# modelsupwinid &&
           \   modelsupwinid !=# -1 &&
           \   !has_key(s:nonsupwincache, modelsupwinid)
                call s:Log.DBG('Model info for window ', a:winid, ' confirmed in state as subwin ', modelsupwinid, ':', modelinfo.grouptype, ':', modelinfo.typename)
                let modelinfo.id = a:winid
                return modelinfo
            endif
            if WinceModelSubwinAibufBySubwinId(a:winid) ==#
           \   WinceStateGetBufnrByWinidOrWinnr(a:winid)
                call s:Log.VRB('Model info for window ', a:winid, ' confirmed in state as afterimaged subwin ', modelinfo.supwin, ':', modelinfo.grouptype, ':', modelinfo.typename)
                let modelinfo.id = a:winid
                return modelinfo
            endif
        endif
    endif
    
    " Check if the window is an uberwin
    for uberwingrouptypename in WinceModelAllUberwinGroupTypeNamesByPriority()
        call s:Log.VRB('Invoking toIdentify from ', uberwingrouptypename, ' uberwin group type')
        let uberwintypename = s:toIdentifyUberwins[uberwingrouptypename](a:winid)
        if !empty(uberwintypename)
            call s:Log.DBG('Window ', a:winid, ' identified as ', uberwingrouptypename, ':', uberwintypename)
            return {
           \    'category': 'uberwin',
           \    'grouptype': uberwingrouptypename,
           \    'typename': uberwintypename,
           \    'id': a:winid
           \}
        endif
    endfor

    " Check if the window is a subwin
    for subwingrouptypename in WinceModelAllSubwinGroupTypeNamesByPriority()
        call s:Log.VRB('Invoking toIdentify from ', subwingrouptypename, ' subwin group type')
        let subwindict = s:toIdentifySubwins[subwingrouptypename](a:winid)
        if !empty(subwindict)
            call s:Log.DBG('Window ', a:winid, ' identified as ', subwindict.supwin, ':', subwingrouptypename, ':', subwindict.typename)
            " If there is no supwin, or if the identified 'supwin' isn't a
            " supwin, the window we are identifying has no place in the model
            if subwindict.supwin ==# -1 || has_key(s:nonsupwincache, subwindict.supwin)
                call s:Log.DBG('Identified subwin gives non-supwin ', subwindict.supwin, ' as its supwin. Identification failed.')
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

    call s:Log.DBG('Window ', a:winid, ' identified as supwin')
    return {'category':'supwin', 'id':a:winid}
endfunction

" Convert a list of window info dicts (as returned by
" s:IdentifyWindow) and group them by category, supwin id, group
" type, and type. Any incomplete groups are dropped. Any duplicates
" are dropped. The choice of which duplicate to drop is arbitrary.
function! s:GroupInfo(wininfos)
    call s:Log.VRB('s:GroupInfo ', a:wininfos)
    let uberwingroupinfo = {}
    let subwingroupinfo = {}
    let supwininfo = []
    " Group the window info
    for wininfo in a:wininfos
        call s:Log.VRB('Examining ', wininfo)
        if wininfo.category ==# 'uberwin'
            if !has_key(uberwingroupinfo, wininfo.grouptype)
                let uberwingroupinfo[wininfo.grouptype] = {}
            endif
            " If there are two uberwins of the same type, whichever one this
            " loop sees last will survive
            let uberwingroupinfo[wininfo.grouptype][wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'subwin'
            if !has_key(subwingroupinfo, wininfo.supwin)
                let subwingroupinfo[wininfo.supwin] = {}
            endif
            let supwindict = subwingroupinfo[wininfo.supwin]
            if !has_key(supwindict, wininfo.grouptype)
                let supwindict[wininfo.grouptype] = {}
            endif
            " If there are two subwins of the same type for the same supwin,
            " whichever one this loop sees last will survive
            let supwindict[wininfo.grouptype][wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'supwin'
            call add(supwininfo, wininfo.id)
        endif
    endfor
   
    call s:Log.VRB('Grouped Uberwins: ', uberwingroupinfo)
    call s:Log.VRB('Supwins: ', supwininfo)
    call s:Log.VRB('Grouped Subwins: ', subwingroupinfo)

    " Validate groups. Prune any incomplete groups. Convert typename-keyed
    " winid dicts to lists
    for [grouptypename,group] in items(uberwingroupinfo)
        call s:Log.VRB('Validating uberwin group ', grouptypename)
        for typename in keys(group)
            call WinceModelAssertUberwinTypeExists(grouptypename, typename)
        endfor
        let group.winids = []
        for typename in WinceModelUberwinTypeNamesByGroupTypeName(grouptypename)
            if !has_key(group, typename)
                call s:Log.VRB('Uberwin with type ', typename, ' missing. Dropping group.')
                unlet uberwingroupinfo[grouptypename]
                break
            endif
            call add(group.winids,group[typename])
        endfor
    endfor
    for [supwinid,supwin] in items(subwingroupinfo)
        for [grouptypename,group] in items(supwin)
            call s:Log.VRB('Validating subwin group ', supwinid, ':', grouptypename)
            for typename in keys(group)
                call WinceModelAssertSubwinTypeExists(grouptypename, typename)
            endfor
            let group.winids = []
            for typename in WinceModelSubwinTypeNamesByGroupTypeName(grouptypename)
                if !has_key(group, typename)
                    call s:Log.VRB('Subwin with type ', typename, ' missing. Dropping group.')
                    unlet supwin[grouptypename]
                    break
                endif
                call add(group.winids, group[typename])
            endfor
        endfor
    endfor
    let retdict = {'uberwin':uberwingroupinfo,'supwin':supwininfo,'subwin':subwingroupinfo}

    call s:Log.VRB('Grouped: ', retdict)
    return retdict
endfunction

" Resolver steps

" STEP 1 - Adjust the model so it accounts for recent changes to the state
function! s:WinceResolveStateToModel(statewinids)
    " STEP 1.1: If any window in the model isn't in the state, remove it from
    "           the model. Also make sure all terminal windows are supwins.
    call s:Log.VRB('Step 1.1')
    let s:relistedcond = 0

    " If any uberwin group in the model isn't fully represented in the state,
    " mark it hidden in the model
    " If any terminal window is listed in the model as an uberwin, mark that
    " uberwin group hidden in the model and relist the window as a supwin
    " If there are multiple uberwins in this group and only one of them has
    " become a terminal window or been closed, then this change renders that
    " uberwin group incomplete in the state and the non-state-terminal windows
    " in the model group will be ignored in STEP 1.3, then stomped in STEP 2.1
    let uberwingrouptypestohide = {}
    for modeluberwinid in WinceModelUberwinIds()
        call s:Log.VRB('Checking if model uberwin ', modeluberwinid, ' is a non-terminal window in the state')
        let dohidegroup = 1
        let dorelistwin = 0
        if WinceStateWinExists(modeluberwinid)
            if WinceStateWinIsTerminal(modeluberwinid)
                call s:Log.VRB('Model uberwin ', modeluberwinid, ' is a terminal window in the state')
                let dorelistwin = 1
            else
                let dohidegroup = 0
            endif
        else
            call s:Log.VRB('Model uberwin ', modeluberwinid, ' does not exist in state')
        endif

        if dohidegroup
            let modelinfo = WinceModelInfoById(modeluberwinid)
            if modelinfo.category !=# 'uberwin'
                throw 'Inconsistency in model. winid ' . modeluberwinid . ' is both' .
                      ' uberwin and ' . modelinfo.category
            endif
            if !has_key(uberwingrouptypestohide, modelinfo.grouptype)
                let uberwingrouptypestohide[modelinfo.grouptype] = []
            endif
            if dorelistwin
                call add(uberwingrouptypestohide[modelinfo.grouptype], modeluberwinid)
            endif
        endif
    endfor
    for [grouptypename,terminalwinids] in items(uberwingrouptypestohide)
       call s:Log.INF('Step 1.1 hiding non-state-complete uberwin group ', grouptypename)
       call WinceModelHideUberwins(grouptypename)
       for terminalwinid in terminalwinids
           call s:Log.INF('Step 1.1 relisting terminal window ', terminalwinid, ' from uberwin of group ', grouptypename, ' to supwin')
           call WinceModelAddSupwin(terminalwinid, -1, -1, -1)
           let s:relistedcond = 1
       endfor
       let s:nonsupwincache = {}
    endfor

    " If any supwin in the model isn't in the state, remove it and its subwins
    " from the model
    for modelsupwinid in WinceModelSupwinIds()
        call s:Log.VRB('Checking if model supwin ', modelsupwinid, ' still exists in state')
        if !WinceStateWinExists(modelsupwinid)
            call s:Log.INF('Step 1.1 removing state-missing supwin ', modelsupwinid, ' from model')
            let s:nonsupwincache = {}
            call WinceModelRemoveSupwin(modelsupwinid)
        endif
    endfor

    " If any subwin group in the model isn't fully represented in the state,
    " mark it hidden in the model
    " If any terminal window is listed in the model as a subwin, mark that
    " subwin group hidden in the model and relist the window as a supwin
    " If there are multiple subwins in this group and only one of them has
    " become a terminal window or been closed, then this change renders that
    " subwin group incomplete and the non-state-terminal windows in the model
    " group will be ignored in STEP 1.3, then stomped in STEP 2.1
    let subwingrouptypestohidebysupwin = {}
    for modelsubwinid in WinceModelSubwinIds()
        call s:Log.VRB('Checking if model subwin ', modelsubwinid, ' is a non-terminal window in the state')
        let dohidegroup = 1
        let dorelistwin = 0
        if WinceStateWinExists(modelsubwinid)
            if WinceStateWinIsTerminal(modelsubwinid)
                call s:Log.VRB('Model subwin ', modelsubwinid, ' is a terminal window in the state')
                let dorelistwin = 1
            else
                let dohidegroup = 0
            endif
        else
            call s:Log.VRB('Model subwin ', modelsubwinid, ' does not exist in state')
        endif

        if dohidegroup
            let modelinfo = WinceModelInfoById(modelsubwinid)
            if modelinfo.category !=# 'subwin'
                throw 'Inconsistency in model. winid ' . modelsubwinid .
                      ' is both subwin and ' . modelinfo.category
            endif
            if !has_key(subwingrouptypestohidebysupwin, modelinfo.supwin)
                let subwingrouptypestohidebysupwin[modelinfo.supwin] = {}
            endif
            if !has_key(subwingrouptypestohidebysupwin[modelinfo.supwin], modelinfo.grouptype)
                let subwingrouptypestohidebysupwin[modelinfo.supwin][modelinfo.grouptype] = []
            endif
            if dorelistwin
                call add(subwingrouptypestohidebysupwin[modelinfo.supwin][modelinfo.grouptype], modelsubwinid)
            endif
        endif
    endfor
    for [supwinid, subwingrouptypestohide] in items(subwingrouptypestohidebysupwin)
        for [grouptypename, terminalwinids] in items(subwingrouptypestohide)
            call s:Log.INF('Step 1.1 hiding non-state-complete subwin group ', supwinid, ':', grouptypename)
            call WinceModelHideSubwins(supwinid, grouptypename)
            for terminalwinid in terminalwinids
                call s:Log.INF('Step 1.1 relisting terminal window ', terminalwinid, ' from subwin of group ', supwinid, ':', grouptypename, ' to supwin')
                call WinceModelAddSupwin(terminalwinid, -1, -1, -1)
                let s:relistedcond = 1
            endfor
            let s:nonsupwincache = {}
        endfor
    endfor
    
    " STEP 1.2: If any window in the state doesn't look the way the model
    "           says it should, relist it in the model. This is a separate
    "           step from STEP 1.1 because it iterates over groups/types
    "           instead of over winids
    call s:Log.VRB('Step 1.2')

    " If any window is listed in the model as an uberwin but doesn't
    " satisfy its type's constraints, mark the uberwin group hidden
    " in the model and relist the window as a supwin.
    for grouptypename in WinceModelShownUberwinGroupTypeNames()
        " There are two loops here because if there was only one loop, we'd
        " potentially hide an uberwin and then not be able to check the rest
        " of the group due to winids being absent from the model. So
        " pre-retrieve all the winids and then check them.
        let typenamewinids = []
        for typename in WinceModelUberwinTypeNamesByGroupTypeName(grouptypename)
            call add(typenamewinids, [typename, WinceModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': grouptypename,
           \    'typename': typename
           \})])
        endfor
        let hidgroup = 0
        for [typename, winid] in typenamewinids
            call s:Log.VRB('Checking model uberwin ', grouptypename, ':', typename, ' for toIdentify compliance')
            if s:toIdentifyUberwins[grouptypename](winid) !=# typename
                call s:Log.INF('Step 1.2 relisting non-compliant uberwin ', winid, ' from ', grouptypename, ':', typename, ' to supwin and hiding group')
                let s:nonsupwincache = {}
                if !hidgroup
                    call WinceModelHideUberwins(grouptypename)
                    let hidgroup = 1
                endif
                call WinceModelAddSupwin(winid, -1, -1, -1)
                let s:relistedcond = 1
            endif
        endfor
    endfor

    " If any window is listed in the model as a subwin but doesn't
    " satisfy its type's constraints, mark the subwin group hidden
    " in the model and relist the window as a supwin.
    for supwinid in WinceModelSupwinIds()
        for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            " There are two loops here because if there was only one loop, we'd
            " potentially hide a subwin and then not be able to check the rest
            " of the group due to winids being absent from the model. So
            " pre-retrieve all the winids and then check them.
            let typenamewinids = []
            for typename in WinceModelSubwinTypeNamesByGroupTypeName(grouptypename)
                call add(typenamewinids, [typename, WinceModelIdByInfo({
               \    'category': 'subwin',
               \    'supwin': supwinid,
               \    'grouptype': grouptypename,
               \    'typename': typename
               \})])
            endfor
            let hidgroup = 0
            let groupisafterimaged = WinceModelSubwinGroupIsAfterimaged(supwinid, grouptypename)
            let afterimagingtypes = g:wince_subwingrouptype[grouptypename].afterimaging
            for [typename, winid] in typenamewinids
                " toIdentify consistency isn't required if the subwin is
                " afterimaged
                if groupisafterimaged && has_key(afterimagingtypes, typename)
                    call s:Log.VRB('Afterimaged subwin ', supwinid, ':', grouptypename, ':', typename, ' is exempt from toIdentify compliance')
                    continue
                endif
                call s:Log.VRB('Checking model subwin ', supwinid, ':', grouptypename, ':', typename, ' for toIdentify compliance')
                let identified = s:toIdentifySubwins[grouptypename](winid)
                if empty(identified) ||
                  \identified.supwin !=# supwinid ||
                  \identified.typename !=# typename
                    call s:Log.INF('Step 1.2 relisting non-compliant subwin ', winid, ' from ', supwinid, ':', grouptypename, ':', typename, ' to supwin and hiding group')
                    let s:nonsupwincache = {}
                    if !hidgroup
                        call WinceModelHideSubwins(supwinid, grouptypename)
                        let hidgroup = 1
                    endif
                    call WinceModelAddSupwin(winid, -1, -1, -1)
                    let s:relistedcond = 1
                endif
            endfor
        endfor
    endfor

    " If any window is listed in the model as a supwin but it satisfies the
    " constraints of an uberwin or subwin, remove it and its subwins from the model.
    " STEP 1.3 will pick it up and add it as the appropriate uberwin/subwin type.
    for supwinid in WinceModelSupwinIds()
        call s:Log.VRB('Checking that model supwin ', supwinid, ' is a supwin in the state')
        let wininfo = s:IdentifyWindow(supwinid)
        if wininfo.category !=# 'supwin'
           call s:Log.INF('Step 1.2 found winid ', supwinid, ' listed as a supwin in the model but identified in the state as ', wininfo.category, ' ', wininfo.grouptype, ':', wininfo.typename, '. Removing from the model.')
            let s:nonsupwincache = {}
            call WinceModelRemoveSupwin(supwinid)
        endif
    endfor

    " STEP 1.3: If any window in the state isn't in the model, add it to the model
    " All winids in the state
    call s:Log.VRB('Step 1.3')

    " Winids in the state that aren't in the model
    let missingwinids = []
    for statewinid in a:statewinids
        call s:Log.VRB('Checking state winid ', statewinid, ' for model presence')
        if !WinceModelWinExists(statewinid)
            call s:Log.VRB('State winid ', statewinid, ' not present in model')
            call add(missingwinids, statewinid)
        endif
    endfor
    " Model info for those winids
    let missingwininfos = []
    for missingwinid in missingwinids
        call s:Log.VRB('Identify model-missing window ', missingwinid)
        let missingwininfo = s:IdentifyWindow(missingwinid)
        if len(missingwininfo)
            call add(missingwininfos, missingwininfo)
        endif
    endfor
    " Model info for those winids, grouped by category, supwin id, group type,
    " and type
    call s:Log.VRB('Group info for model-missing windows')
    let groupedmissingwininfo = s:GroupInfo(missingwininfos)
    call s:Log.VRB('Add model-missing uberwins to model: ', groupedmissingwininfo.uberwin)
    for [grouptypename, group] in items(groupedmissingwininfo.uberwin)
        call s:Log.INF('Step 1.3 adding uberwin group ', grouptypename, ' to model with winids ', group.winids)
        try
            let s:nonsupwincache = {}
            call WinceModelAddOrShowUberwins(grouptypename, group.winids, [])
        catch /.*/
            call s:Log.WRN('Step 1.3 failed to add uberwin group ', grouptypename, ' to model:')
            call s:Log.DBG(v:throwpoint)
            call s:Log.WRN(v:exception)
        endtry
    endfor
    call s:Log.VRB('Add model-missing supwins to model: ', groupedmissingwininfo.supwin)
    for supwinid in groupedmissingwininfo.supwin
        call s:Log.INF('Step 1.3 adding window ', supwinid, ' to model as supwin')
        call WinceModelAddSupwin(supwinid, -1, -1, -1)
    endfor
    call s:Log.VRB('Add model-missing subwins to model: ', groupedmissingwininfo.subwin)
    for [supwinid, supwin] in items(groupedmissingwininfo.subwin)
        call s:Log.VRB('Subwins of supwin ', supwinid)
        if !WinceModelSupwinExists(supwinid)
            call s:Log.VRB('Supwin ', supwinid, ' does not exist')
            continue
        endif
        for [grouptypename, group] in keys(supwin)
            call s:Log.INF('Step 1.3 adding subwin group ', supwinid, ':', grouptypename, ' to model with winids ', group.winids)
            try
                let s:nonsupwincache = {}
                call WinceModelAddOrShowSubwins(
               \    supwinid,
               \    grouptypename,
               \    group.winids,
               \    []
               \)
            catch /.*/
                call s:Log.WRN('Step 1.3 failed to add subwin group ', grouptypename, ' to model:')
                call s:Log.DBG(v:throwpoint)
                call s:Log.WRN(v:exception)
            endtry
        endfor
    endfor

    " STEP 1.4: Supwins that have become terminal windows need to have their
    "      subwins hidden, but this must be done after STEP 1.3 which would add the
    "      subwins back
    call s:Log.VRB('Step 1.4')

    " If any supwin is a terminal window with shown subwins, mark them as
    " hidden in the model
    for supwinid in WinceModelSupwinIds()
        call s:Log.VRB('Checking if supwin ', supwinid, ' is a terminal window in the state')
        if WinceStateWinIsTerminal(supwinid)
            call s:Log.VRB('Supwin ', supwinid, ' is a terminal window in the state')
            for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
                call s:Log.DBG('Step 1.4 hiding subwin group ', grouptypename, ' of terminal supwin ', supwinid, ' in model')
                let s:nonsupwincache = {}
                call WinceModelHideSubwins(supwinid, grouptypename)
            endfor
        endif
    endfor
endfunction

" STEP 2: Adjust the state so that it matches the model
function! s:WinceResolveModelToState(statewinids)
    " STEP 2.1: Purge the state of windows that aren't in the model
    call s:Log.VRB('Step 2.1')

    " TODO? Do something more civilized than stomping each window
    "       individually. So far it's ok but some other group type
    "       may require it in the future. This would require a new
    "       parameter for WinceAdd(Uber|Sub)winGroupType - a list of
    "       callbacks which close individual windows and not whole
    "       groups
    for winid in a:statewinids
        " WinStateCloseWindow used to close windows without noautocmd. If a
        " window triggered autocommands when closed, and those autocommands
        " closed other windows that were later in the list, this check would
        " fire. I'm leaving it here in case there are more bugs
        if !WinceStateWinExists(winid)
            call s:Log.ERR('State is inconsistent - winid ', winid, ' is both present and not present')
            continue
        endif

        let wininfo = s:IdentifyWindow(winid)
        call s:Log.DBG('Identified state window ', winid, ' as ', wininfo)

        " If any window in the state isn't categorizable, remove it from the
        " state
        if wininfo.category ==# 'none'
            call s:Log.INF('Step 2.1 removing uncategorizable window ', winid, ' from state')
            call WinceStateCloseWindow(winid, 0)
            continue
        endif

        " If any supwin in the state isn't in the model, remove it from the
        " state.
        if wininfo.category ==# 'supwin' && !WinceModelSupwinExists(wininfo.id)
            call s:Log.INF('Step 2.1 removing supwin ', winid, ' from state')
            call WinceStateCloseWindow(winid, 0)
            continue
        endif

        " If any uberwin in the state isn't shown in the model or has a
        " different winid than the model lists, remove it from the state
        if wininfo.category ==# 'uberwin' && (
       \    !WinceModelShownUberwinGroupExists(wininfo.grouptype) ||
       \    WinceModelIdByInfo(wininfo) !=# winid
       \)
            call s:Log.INF("Step 2.1 removing non-model-shown or mis-model-winid'd uberwin ", wininfo.grouptype, ':', wininfo.typename, ' with winid ', winid, ' from state')
            call WinceStateCloseWindow(winid, 0)
            continue
        endif

        " If any subwin in the state isn't shown in the model or has a
        " different winid than the model lists, remove it from the state
        if wininfo.category ==# 'subwin' && (
       \    !WinceModelShownSubwinGroupExists(wininfo.supwin, wininfo.grouptype) ||
       \    WinceModelIdByInfo(wininfo) !=# winid
       \)
           call s:Log.INF("Step 2.1 removing non-model-shown or mis-model-winid'd subwin ", wininfo.supwin, ':', wininfo.grouptype, ':', wininfo.typename, ' with winid ', winid, ' from state')
           call WinceStateCloseWindow(winid, g:wince_subwingrouptype[wininfo.grouptype].stompWithBelowRight)
           continue
        endif
    endfor

    " STEP 2.2: Temporarily close any windows that may be in the wrong place.
    "           Any window that was added to the model in STEP 1 was added because
    "           it spontaneously appeared in the state. It may have spontaneously
    "           appeared in the wrong place, so any window that was added in STEP 1
    "           must be temporarily closed. STEP 1 is the only place where windows
    "           are added to the model with dummy dimensions, so any window in
    "           the model with dummy dimensions was added in STEP 1 and
    "           therefore needs to be temporarily closed.
    "           Conversely, any window with non-dummy dimensions in the model
    "           was not added in STEP 1 and therefore has been touched by a user
    "           operation or by the previous execution of the resolver, which would
    "           have left its model dimensions consistent with its state
    "           dimensions.
    "           One exception is a window that was relisted in STEP 1. But
    "           since windows can be relisted as supwins (which we have no way
    "           of closing and reopening robustly), we can't just close and
    "           reopen them. Instead, if any window was relisted, just close
    "           *all* uberwins and subwins. This is a bit of a sledgehammer,
    "           but relisting isn't expected to be a common use case.
    "           If there is an inconsistency, then the window has been touched by
    "           something else after the user operation or resolver last
    "           touched it. That touch may have put it in the wrong place.
    "           So any window in the model with non-dummy dimensions inconsistent
    "           with its state dimensions needs to be temporarily closed.
    "           Since a window can be anywhere, closing it may affect the
    "           dimensions of other windows and make them inconsistent after
    "           they've been checked already. So if we close a window, we need
    "           to make another pass.
    call s:Log.VRB('Step 2.2')

    " For the rest of STEP 2, supwin IDs in the model don't change - so cache
    " them
    let supwinids = WinceModelSupwinIds()
    let preserveduberwins = {}
    let preservedsubwins = {}
    let passneeded = 1
    while passneeded
        call s:Log.DBG('Start pass')
        let passneeded = 0
        " If any uberwins have dummy or inconsistent dimensions, remove them from the
        " state along with any other shown uberwin groups with higher priority.
        let uberwinsremoved = 0
        for grouptypename in WinceModelShownUberwinGroupTypeNames()
            call s:Log.VRB('Check uberwin group ', grouptypename)
            if WinceCommonUberwinGroupExistsInState(grouptypename)
                if uberwinsremoved || s:relistedcond ||
               \   !WinceCommonUberwinGroupDimensionsMatch(grouptypename)
                    let preserveduberwins[grouptypename] =
                   \    WinceCommonPreCloseAndReopenUberwins(grouptypename)
                    call s:Log.VRB('Preserved info from uberwin group ', grouptypename, ': ', preserveduberwins[grouptypename])
                    call s:Log.INF('Step 2.2 removing uberwin group ', grouptypename, ' from state')
                    " TODO? Wrap in try-catch? Never seen it fail
                    call WinceCommonCloseUberwinsByGroupTypeName(grouptypename)
                    let uberwinsremoved = 1
                    let passneeded = 1
                endif
            endif
        endfor

        let toremove = {}
        for supwinid in supwinids
            call s:Log.VRB('Check subwins of supwin ', supwinid)
            let toremove[supwinid] = []
            " If we removed uberwins, flag all shown subwins for removal
            " Also flag all shown subwins of any supwin with dummy or inconsistent
            " dimensions
            if uberwinsremoved || s:relistedcond || !WinceCommonSupwinDimensionsMatch(supwinid)
                call s:Log.DBG('Flag all subwin groups for supwin ', supwinid, ' for removal from state')
                let toremove[supwinid] = WinceModelShownSubwinGroupTypeNamesBySupwinId(
               \    supwinid
               \)

            " Otherwise, if any subwin of the supwin has dummy or inconsistent
            " dimensions, flag that subwin's group along with all higher-priority
            " shown subwin groups in the supwin
            else
                let subwinsflagged = 0
                for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(
               \    supwinid
               \)
                    call s:Log.VRB('Check subwin group ', supwinid, ':', grouptypename)
                    if WinceCommonSubwinGroupExistsInState(supwinid, grouptypename)
                        if subwinsflagged || !WinceCommonSubwinGroupDimensionsMatch(
                       \    supwinid,
                       \    grouptypename
                       \)
                            call s:Log.DBG('Flag subwin group ', supwinid, ':', grouptypename, ' for removal from state')
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
            " WinceCommonCloseSubwinsWithHigherPriorityThan
            for grouptypename in reverse(copy(toremove[supwinid]))
                call s:Log.VRB('Removing flagged subwin group ', supwinid, ':', grouptypename)
                if WinceCommonSubwinGroupExistsInState(supwinid, grouptypename)
                    let preservedsubwins[supwinid][grouptypename] =
                   \    WinceCommonPreCloseAndReopenSubwins(supwinid, grouptypename)
                    call s:Log.VRB('Preserved info from subwin group ', supwinid, ':', grouptypename, ': ', preservedsubwins[supwinid][grouptypename])
                    call s:Log.INF('Step 2.2 removing subwin group ', supwinid, ':', grouptypename, ' from state')
                    " TODO? Wrap in try-catch? Never seen it fail
                    call WinceCommonCloseSubwins(supwinid, grouptypename)
                    let passneeded = 1
                endif
            endfor
        endfor
    endwhile

    " STEP 2.3: Add any missing windows to the state, including those that
    "           were temporarily removed, in the correct places
    call s:Log.VRB('Step 2.3')

    " If any shown uberwin in the model isn't in the state,
    " add it to the state
    for grouptypename in WinceModelShownUberwinGroupTypeNames()
        call s:Log.VRB('Checking model uberwin group ', grouptypename)
        if !WinceCommonUberwinGroupExistsInState(grouptypename)
            try
                call s:Log.INF('Step 2.3 adding uberwin group ', grouptypename, ' to state')
                let winids = WinceCommonOpenUberwins(grouptypename)
                " This Model write in ResolveModelToState is unfortunate, but I
                " see no sensible way to put it anywhere else
                let s:nonsupwincache = {}
                call WinceModelChangeUberwinIds(grouptypename, winids)
                if has_key(preserveduberwins, grouptypename)
                    call s:Log.DBG('Uberwin group ', grouptypename, ' was closed in Step 2.2. Restoring.')
                    call WinceCommonPostCloseAndReopenUberwins(
                   \    grouptypename,
                   \    preserveduberwins[grouptypename]
                   \)
                endif
            catch /.*/
                call s:Log.WRN('Step 2.3 failed to add ', grouptypename, ' uberwin group to state:')
                call s:Log.DBG(v:throwpoint)
                call s:Log.WRN(v:exception)
                let s:nonsupwincache = {}
                call WinceModelHideUberwins(grouptypename)
            endtry
        endif
    endfor

    " If any shown subwin in the model isn't in the state,
    " add it to the state
    for supwinid in supwinids
        for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            call s:Log.VRB('Checking model subwin group ', supwinid, ':', grouptypename)
            if !WinceCommonSubwinGroupExistsInState(supwinid, grouptypename)
                call s:Log.VRB('Model subwin group ', supwinid, ':', grouptypename, ' is missing from state')
                if WinceModelSubwinGroupTypeHasAfterimagingSubwin(grouptypename)
                    call s:Log.VRB('State-missing subwin group ', supwinid, ':', grouptypename, ' is afterimaging. Afterimaging all other subwins of this group type first before restoring')
                    " Afterimaging subwins may be state-open in at most one supwin
                    " at a time. So if we're opening an afterimaging subwin, it
                    " must first be afterimaged everywhere else.
                    for othersupwinid in supwinids
                        if othersupwinid ==# supwinid
                            continue
                        endif
                        call s:Log.VRB('Checking supwin ', othersupwinid, ' for subwins of group type ', grouptypename)
                        if WinceModelShownSubwinGroupExists(
                       \    othersupwinid,
                       \    grouptypename
                       \) && !WinceModelSubwinGroupIsAfterimaged(
                       \    othersupwinid,
                       \    grouptypename
                       \) && WinceCommonSubwinGroupExistsInState(
                       \    othersupwinid,
                       \    grouptypename
                       \)
                            call s:Log.DBG('Step 2.3 afterimaging subwin group ', othersupwinid, ':', grouptypename)
                            call WinceCommonAfterimageSubwinsByInfo(
                           \    othersupwinid,
                           \    grouptypename
                           \)
                        endif
                    endfor
                endif
                try
                    call s:Log.INF('Step 2.3 adding subwin group ', supwinid, ':', grouptypename, ' to state')
                    let winids = WinceCommonOpenSubwins(supwinid, grouptypename)
                    " This Model write in ResolveModelToState is unfortunate, but I
                    " see no sensible way to put it anywhere else
                    let s:nonsupwincache = {}
                    call WinceModelChangeSubwinIds(supwinid, grouptypename, winids)
                    if has_key(preservedsubwins, supwinid) &&
                   \   has_key(preservedsubwins[supwinid], grouptypename)
                        call s:Log.DBG('Subwin group ', supwinid, ':', grouptypename, ' was closed in Step 2.2. Restoring.')
                        call WinceCommonPostCloseAndReopenSubwins(
                       \    supwinid,
                       \    grouptypename,
                       \    preservedsubwins[supwinid][grouptypename]
                       \)
                    endif
                catch /.*/
                    call s:Log.WRN('Step 2.3 failed to add ', grouptypename, ' subwin group to supwin ', supwinid, ':')
                    call s:Log.DBG(v:throwpoint)
                    call s:Log.WRN(v:exception)
                    let s:nonsupwincache = {}
                    call WinceModelHideSubwins(supwinid, grouptypename)
                endtry
            endif
        endfor
    endfor
endfunction

" STEP 3: Make sure that the subwins are afterimaged according to the cursor's
"         final position
function! s:WinceResolveCursor()
    " STEP 3.1: See comments on WinceCommonUpdateAfterimagingByCursorWindow
    call s:Log.VRB('Step 3.1')
    call WinceCommonUpdateAfterimagingByCursorWindow(s:curpos.win)

    " STEP 3.2: If the model's current window does not match the state's
    "           current window (as it was at the start of this resolver run), then
    "           the state's current window was touched between resolver runs by
    "           something other than the user operations. That other thing won't have
    "           updated the model's previous window, so update it here by using the
    "           model's current window. Then update the model's current window using
    "           the state's current window.
    call s:Log.VRB('Step 3.2')
    let modelcurrentwininfo = WinceModelCurrentWinInfo()
    let modelcurrentwinid = WinceModelIdByInfo(modelcurrentwininfo)
    let resolvecurrentwinid = WinceModelIdByInfo(s:curpos.win)
    if WinceModelIdByInfo(WinceModelPreviousWinInfo()) && modelcurrentwinid &&
   \   resolvecurrentwinid !=# modelcurrentwinid
        " If the current window doesn't exist in the state, then this resolver
        " run must have closed it. Set the current window to the previous
        " window.
        if !WinceStateWinExists(resolvecurrentwinid)
            call WinceModelSetCurrentWinInfo(WinceModelPreviousWinInfo())
        else
            call WinceModelSetPreviousWinInfo(modelcurrentwininfo)
            call WinceModelSetCurrentWinInfo(s:curpos.win)
        endif
    endif
endfunction

" Resolver implementation
function! s:ResolveInner()
    " Retrieve the toIdentify functions
    call s:Log.VRB('Retrieve toIdentify functions')
    let s:toIdentifyUberwins = WinceModelToIdentifyUberwins()
    let s:toIdentifySubwins = WinceModelToIdentifySubwins()

    " If this is the first time running the resolver after entering a tab, run
    " the appropriate callbacks
    if t:wince_resolvetabenteredcond
        call s:Log.DBG('Tab entered. Running callbacks')
        for TabEnterCallback in WinceModelTabEnterPreResolveCallbacks()
            call s:Log.VRB('Running tab-entered callback ', TabEnterCallback)
            call TabEnterCallback()
        endfor
        let t:wince_resolvetabenteredcond = 0
    endif

    " A list of winids in the state is used in both STEP 1.3 and STEP 2.1,
    " without changing inbetween. So retrieve it only once
    let statewinids = WinceStateGetWinidsByCurrentTab()

    " STEP 1: The state may have changed since the last WinceResolve() call. Adapt the
    "         model to fit it.
    call s:WinceResolveStateToModel(statewinids)

    " Save the cursor position to be restored at the end of the resolver. This
    " is done here because the position is stored in terms of model keys which
    " may not have existed until now
    call s:Log.VRB('Save cursor position')
    let s:curpos = WinceCommonGetCursorPosition()

    " Save the current number of tabs
    let tabcount = WinceStateGetTabCount()

    " STEP 2: Now the model is the way it should be, so adjust the state to fit it.
    call s:WinceResolveModelToState(statewinids)

    " It is possible that STEP 2 closed the tab, and we are now in a
    " different tab. If that is the case, end the resolver run
    " immediately. We can tell the tab has been closed by checking the number
    " of tabs. The resolver will never open a new tab or rearrange existing
    " tabs.
    if tabcount !=# WinceStateGetTabCount()
        let s:resolveIsRunning = 0
        return
    endif

    " STEP 3: The model and state are now consistent with each other, but
    "         afterimaging and tracked cursor positions may be inconsistent with the
    "         final position of the cursor. Make it consistent.
    call s:WinceResolveCursor()

    " STEP 4: Now everything is consistent, so record the dimensions of all
    "         windows in the model. The next resolver run will consider those
    "         dimensions as being the last known consistent data, unless a
    "         user operation overwrites them with its own (also consistent)
    "         data.
    call s:Log.VRB('Step 4')
    call WinceCommonRecordAllDimensions()

    " Restore the cursor position from when the resolver started
    call s:Log.VRB('Restore cursor position')
    call WinceCommonRestoreCursorPosition(s:curpos)
    let s:curpos = {}
endfunction

" Resolver entry point
let s:resolveIsRunning = 0
function! WinceResolve()
    if s:resolveIsRunning
        call s:Log.DBG('Resolver reentrance detected')
        return
    endif

    let s:resolveIsRunning = 1
    call s:Log.DBG('Resolver start')

    let s:nonsupwincache = {}

    try
        call s:ResolveInner()
        call s:Log.DBG('Resolver end')
    catch /.*/
        call s:Log.ERR('Resolver abort:')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
    finally
        let s:resolveIsRunning = 0
    endtry
endfunction

" Since the resolver runs as a CursorHold callback, autocmd events
" need to be explicitly signalled to it
augroup WinceResolve
    autocmd!
    
    " Use the TabEnter event to detect when a tab has been entered
    autocmd TabEnter * let t:wince_resolvetabenteredcond = 1
augroup END
