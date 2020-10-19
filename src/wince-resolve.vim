" Wince Resolver
" See wince.vim
let s:Log = jer_log#LogFunctions('wince-resolve')


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
function! WinceResolveIdentifyAfterimagedSubwin(winid)
    call s:Log.VRB('WinceResolveIdentifyAfterimagedSubwin ', a:winid)
    let wininfo = WinceModelInfoById(a:winid)
    if wininfo.category ==# 'subwin' && 
   \   WinceModelSubwinIsAfterimaged(
   \       wininfo.supwin,
   \       wininfo.grouptype,
   \       wininfo.typename
   \   ) &&
   \   WinceModelSubwinAibufBySubwinId(a:winid) ==# WinceStateGetBufnrByWinid(a:winid)
        call s:Log.VRB('Afterimaged subwin identified as ', wininfo)
        return wininfo
    endif
    call s:Log.VRB('Afterimaged subwin not identifiable')
    return {'category':'none','id':a:winid}
endfunction

" Run all the toIdentify callbacks against a window until one of
" them succeeds. Return the model info obtained.
function! WinceResolveIdentifyWindow(winid)
    call s:Log.DBG('WinceResolveIdentifyWindow ', a:winid)
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
    let uberwinids = WinceModelUberwinIds()
    let subwinids = WinceModelSubwinIds()
    for subwingrouptypename in WinceModelAllSubwinGroupTypeNamesByPriority()
        call s:Log.VRB('Invoking toIdentify from ', subwingrouptypename, ' subwin group type')
        let subwindict = s:toIdentifySubwins[subwingrouptypename](a:winid)
        if !empty(subwindict)
            call s:Log.DBG('Window ', a:winid, ' identified as ', subwindict.supwin, ':', subwingrouptypename, ':', subwindict.typename)
            " If there is no supwin, or if the identified 'supwin' isn't a
            " supwin, the window we are identifying has no place in the model
            if subwindict.supwin ==# -1 ||
           \   index(uberwinids, str2nr(subwindict.supwin)) >=# 0 ||
           \   index(subwinids, str2nr(subwindict.supwin)) >=# 0
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
    call s:Log.VRB('Window still not identified. Checking if it is an afterimaged subwin.')
    let aiinfo = WinceResolveIdentifyAfterimagedSubwin(a:winid)
    if aiinfo.category !=# 'none'
        " No need to sanity check the 'supwin' field like above because this
        " information already comes from the model
        return aiinfo
    endif
    call s:Log.DBG('Window ', a:winid, ' identified as supwin')
    return {
   \    'category': 'supwin',
   \    'id': a:winid
   \}
endfunction

" Convert a list of window info dicts (as returned by
" WinceResolveIdentifyWindow) and group them by category, supwin id, group
" type, and type. Any incomplete groups are dropped.
function! WinceResolveGroupInfo(wininfos)
    call s:Log.VRB('WinceResolveGroupInfo ', a:wininfos)
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
            if !has_key(subwingroupinfo[wininfo.supwin], wininfo.grouptype)
                let subwingroupinfo[wininfo.supwin][wininfo.grouptype] = {}
            endif
            " If there are two subwins of the same type for the same supwin,
            " whichever one this loop sees last will survive
            let subwingroupinfo[wininfo.supwin]
                              \[wininfo.grouptype]
                              \[wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'supwin'
            call add(supwininfo, wininfo.id)
        endif
    endfor
   
    call s:Log.VRB('Grouped Uberwins: ', uberwingroupinfo)
    call s:Log.VRB('Supwins: ', supwininfo)
    call s:Log.VRB('Grouped Subwins: ', subwingroupinfo)

    " Validate groups. Prune any incomplete groups. Convert typename-keyed
    " winid dicts to lists
    for grouptypename in keys(uberwingroupinfo)
        call s:Log.VRB('Validating uberwin group ', grouptypename)
        for typename in keys(uberwingroupinfo[grouptypename])
            call WinceModelAssertUberwinTypeExists(grouptypename, typename)
        endfor
        let uberwingroupinfo[grouptypename].winids = []
        for typename in WinceModelUberwinTypeNamesByGroupTypeName(grouptypename)
            if !has_key(uberwingroupinfo[grouptypename], typename)
                call s:Log.VRB('Uberwin with type ', typename, ' missing. Expunging group.')
                unlet uberwingroupinfo[grouptypename]
                break
            endif
            call add(uberwingroupinfo[grouptypename].winids,
                    \uberwingroupinfo[grouptypename][typename])
        endfor
    endfor
    for supwinid in keys(subwingroupinfo)
        for grouptypename in keys(subwingroupinfo[supwinid])
            call s:Log.VRB('Validating subwin group ', supwinid, ':', grouptypename)
            for typename in keys(subwingroupinfo[supwinid][grouptypename])
                call WinceModelAssertSubwinTypeExists(grouptypename, typename)
            endfor
            let subwingroupinfo[supwinid][grouptypename].winids = []
            for typename in WinceModelSubwinTypeNamesByGroupTypeName(grouptypename)
                if !has_key(subwingroupinfo[supwinid][grouptypename], typename)
                    call s:Log.VRB('Subwin with type ', typename, ' missing. Expunging group.')
                    unlet subwingroupinfo[supwinid][grouptypename]
                    break
                endif
                call add(subwingroupinfo[supwinid][grouptypename].winids,
                        \subwingroupinfo[supwinid][grouptypename][typename])
            endfor
        endfor
    endfor
    let retdict = {'uberwin':uberwingroupinfo,'supwin':supwininfo,'subwin':subwingroupinfo}

    call s:Log.VRB('Grouped: ', retdict)
    return retdict
endfunction

" Resolver steps

" STEP 1 - Adjust the model so it accounts for recent changes to the state
function! s:WinceResolveStateToModel()
    " STEP 1.1: Terminal windows get special handling because the CursorHold event
    "           doesn't execute when the cursor is inside them
    " If any terminal window is listed in the model as an uberwin, mark that
    " uberwin group hidden in the model and relist the window as a supwin
    " If there are multiple uberwins in this group and only one of them is a
    " terminal window, then this change renders that uberwin group incomplete
    " and the non-terminal windows will be ignored in STEP 1.4, then cleaned
    " up in STEP 2.1
    call s:Log.VRB('Step 1.1')
    for grouptypename in WinceModelShownUberwinGroupTypeNames()
        for typename in WinceModelUberwinTypeNamesByGroupTypeName(grouptypename)
            call s:Log.VRB('Check if model uberwin ', grouptypename, ':', typename, ' is a terminal window in the state')
            let winid = WinceModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': grouptypename,
           \    'typename': typename
           \})
            if winid && WinceStateWinIsTerminal(winid)
                call s:Log.INF('Step 1.1 relisting terminal window ', winid, ' from uberwin ', grouptypename, ':', typename, 'to supwin')
                call WinceModelHideUberwins(grouptypename)
                call WinceModelAddSupwin(winid, -1, -1, -1)
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
    for supwinid in WinceModelSupwinIds()
        for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            for typename in WinceModelSubwinTypeNamesByGroupTypeName(grouptypename)
                call s:Log.VRB('Check if model subwin ', supwinid, ':', grouptypename, ':', typename, ' is a terminal window in the state')
                let winid = WinceModelIdByInfo({
               \    'category': 'subwin',
               \    'supwin': supwinid,
               \    'grouptype': grouptypename,
               \    'typename': typename
               \})
                if winid && WinceStateWinIsTerminal(winid)
                    call s:Log.INF('Step 1.1 relisting terminal window ', winid, ' from subwin ' supwinid, ':', grouptypename, ':', typename, 'to supwin')
                    call WinceModelHideSubwins(supwinid, grouptypename)
                    call WinceModelAddSupwin(winid, -1, -1, -1)
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
    call s:Log.VRB('Step 1.2')
    let modeluberwinids = WinceModelUberwinIds()
    " Using a dict so no keys will be duplicated
    let uberwingrouptypestohide = {}
    for modeluberwinid in modeluberwinids
        call s:Log.VRB('Checking if model uberwin ', modeluberwinid, ' still exists in state')
        if !WinceStateWinExists(modeluberwinid)
           call s:Log.VRB('Model uberwin ', modeluberwinid, ' does not exist in state')
           let tohide = WinceModelInfoById(modeluberwinid)
           if tohide.category != 'uberwin'
               throw 'Inconsistency in model. ID ' . modeluberwinid . ' is both' .
              \      ' uberwin and ' . tohide.category       
           endif
           let uberwingrouptypestohide[tohide.grouptype] = ''
        endif
    endfor
    for tohide in keys(uberwingrouptypestohide)
         call s:Log.DBG('Step 1.2 hiding non-state-complete uberwin group ', tohide, ' in model')
         call WinceModelHideUberwins(tohide)
    endfor

    " If any supwin in the model isn't in the state, remove it and its subwins
    " from the model
    let modelsupwinids = WinceModelSupwinIds()
    for modelsupwinid in modelsupwinids
        call s:Log.VRB('Checking if model supwin ', modelsupwinid, ' still exists in state')
        if !WinceStateWinExists(modelsupwinid)
            call s:Log.DBG('Step 1.2 removing state-missing supwin ', modelsupwinid, ' from model')
            call WinceModelRemoveSupwin(modelsupwinid)
        endif
    endfor

    " If any subwin group in the model isn't fully represented in the state,
    " mark it hidden in the model
    let modelsupwinids = WinceModelSupwinIds()
    let modelsubwinids = WinceModelSubwinIds()
    " Using a dict for each supwin so no keys will be duplicated
    let subwingrouptypestohidebysupwin = {}
    for modelsupwinid in modelsupwinids
        let subwingrouptypestohidebysupwin[modelsupwinid] = {}
    endfor
    for modelsubwinid in modelsubwinids
        call s:Log.VRB('Checking if model subwin ', modelsubwinid, ' still exists in state')
        if !WinceStateWinExists(modelsubwinid)
           call s:Log.VRB('Model subwin ', modelsubwinid, ' does not exist in state')
            let tohide = WinceModelInfoById(modelsubwinid)
            if tohide.category != 'subwin'
                throw 'Inconsistency in model. ID ' . modelsubwinid . ' is both' .
               \      ' subwin and ' . tohide.category
            endif
            let subwingrouptypestohidebysupwin[tohide.supwin][tohide.grouptype] = ''
        endif
    endfor
    for supwinid in keys(subwingrouptypestohidebysupwin)
        for subwingrouptypetohide in keys(subwingrouptypestohidebysupwin[supwinid])
            call s:Log.DBG('Step 1.2 hiding non-state-complete subwin group ', supwinid, ':', subwingrouptypetohide, ' in model')
            call WinceModelHideSubwins(supwinid, subwingrouptypetohide)
        endfor
    endfor

    " STEP 1.3: If any window in the state doesn't look the way the model
    "           says it should, relist it in the model
    " If any window is listed in the model as an uberwin but doesn't
    " satisfy its type's constraints, mark the uberwin group hidden
    " in the model and relist the window as a supwin. 
    call s:Log.VRB('Step 1.3')
    for grouptypename in WinceModelShownUberwinGroupTypeNames()
        for typename in WinceModelUberwinTypeNamesByGroupTypeName(grouptypename)
            call s:Log.VRB('Checking model uberwin ', grouptypename, ':', typename, ' for toIdentify compliance')
            let winid = WinceModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': grouptypename,
           \    'typename': typename
           \})
            if s:toIdentifyUberwins[grouptypename](winid) !=# typename
                call s:Log.INF('Step 1.3 relisting non-compliant window ', winid, ' from uberwin ', grouptypename, ':', typename, ' to supwin')
                call WinceModelHideUberwins(grouptypename)
                call WinceModelAddSupwin(winid, -1, -1, -1)
                let s:supwinsaddedcond = 1
                break
            endif
        endfor
    endfor

    " If any window is listed in the model as a subwin but doesn't
    " satisfy its type's constraints, mark the subwin group hidden
    " in the model and relist the window as a supwin.
    for supwinid in WinceModelSupwinIds()
        for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            for typename in WinceModelSubwinTypeNamesByGroupTypeName(grouptypename)
                let winid = WinceModelIdByInfo({
               \    'category': 'subwin',
               \    'supwin': supwinid,
               \    'grouptype': grouptypename,
               \    'typename': typename
               \})
                " toIdentify consistency isn't required if the subwin is
                " afterimaged
                if WinceModelSubwinIsAfterimaged(supwinid, grouptypename, typename)
                    call s:Log.VRB('Afterimaged subwin ', supwinid, ':', grouptypename, ':', typename, ' is exempt from toIdentify compliance')
                    continue
                endif
                call s:Log.VRB('Checking model subwin ', supwinid, ':', grouptypename, ':', typename, ' for toIdentify compliance')
                let identified = s:toIdentifySubwins[grouptypename](winid)
                if empty(identified) ||
                  \identified.supwin !=# supwinid ||
                  \identified.typename !=# typename
                    call s:Log.INF('Step 1.3 relisting non-compliant window ', winid, ' from subwin ', supwinid, ':', grouptypename, ':', typename, ' to supwin')
                    call WinceModelHideSubwins(supwinid, grouptypename)
                    call WinceModelAddSupwin(winid, -1, -1, -1)
                    let s:supwinsaddedcond = 1
                    break
                endif
            endfor
        endfor
    endfor

    " If any window is listed in the model as a supwin but it satisfies the
    " constraints of an uberwin or subwin, remove it and its subwins from the model.
    " STEP 1.4 will pick it up and add it as the appropriate uberwin/subwin type.
    for supwinid in WinceModelSupwinIds()
        call s:Log.VRB('Checking that model supwin ', supwinid, ' is still a supwin in the state')
        let wininfo = WinceResolveIdentifyWindow(supwinid)
        if wininfo.category !=# 'supwin'
            call s:Log.INF('Winid ', supwinid, ' is listed as a supwin in the model but is identified in the state as ', wininfo.grouptype, ':', wininfo.typename, '. Removing from the model.')
            call WinceModelRemoveSupwin(supwinid)
        endif
    endfor

    " STEP 1.4: If any window in the state isn't in the model, add it to the model
    " All winids in the state
    call s:Log.VRB('Step 1.4')
    let statewinids = WinceStateGetWinidsByCurrentTab()
    " Winids in the state that aren't in the model
    let missingwinids = []
    for statewinid in statewinids
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
        let missingwininfo = WinceResolveIdentifyWindow(missingwinid)
        if len(missingwininfo)
            call add(missingwininfos, missingwininfo)
        endif
    endfor
    " Model info for those winids, grouped by category, supwin id, group type,
    " and type
    call s:Log.VRB('Group info for model-missing windows')
    let groupedmissingwininfo = WinceResolveGroupInfo(missingwininfos)
    call s:Log.VRB('Add model-missing uberwins to model')
    for uberwingrouptypename in keys(groupedmissingwininfo.uberwin)
        let winids = groupedmissingwininfo.uberwin[uberwingrouptypename].winids
        call s:Log.INF('Step 1.4 adding uberwin group ', uberwingrouptypename, ' to model with winids ', winids)
        try
            call WinceModelAddOrShowUberwins(
           \    uberwingrouptypename,
           \    winids,
           \    []
           \)
        catch /.*/
            call s:Log.WRN('Step 1.4 failed to add uberwin group ', uberwingrouptypename, ' to model. Possible duplicate uberwins in state.')
        endtry
    endfor
    call s:Log.VRB('Add model-missing supwins to model')
    for supwinid in groupedmissingwininfo.supwin
        call s:Log.INF('Step 1.4 adding window ', supwinid, ' to model as supwin')
        call WinceModelAddSupwin(supwinid, -1, -1, -1)
        let s:supwinsaddedcond = 1
    endfor
    call s:Log.VRB('Add model-missing subwins to model')
    for supwinid in keys(groupedmissingwininfo.subwin)
        call s:Log.VRB('Subwins of supwin ', supwinid)
        if !WinceModelSupwinExists(supwinid)
            call s:Log.VRB('Supwin ', supwinid, ' does not exist')
            continue
        endif
        for subwingrouptypename in keys(groupedmissingwininfo.subwin[supwinid])
            let winids = groupedmissingwininfo.subwin[supwinid][subwingrouptypename].winids
            call s:Log.INF('Step 1.4 adding subwin group ', supwinid, ':', subwingrouptypename, ' to model with winids ', winids)
            try
                call WinceModelAddOrShowSubwins(
               \    supwinid,
               \    subwingrouptypename,
               \    winids,
               \    []
               \)
            catch /.*/
                call s:Log.WRN('Step 1.4 failed to add subwin group ', subwingrouptypename, ' to model. Possible duplicate subwins in state.')
            endtry
        endfor
    endfor

    " STEP 1.5: Supwins that have become terminal windows need to have their
    "      subwins hidden, but this must be done after STEP 1.4 which would add the
    "      subwins back
    " If any supwin is a terminal window with shown subwins, mark them as
    " hidden in the model
    call s:Log.VRB('Step 1.5')
    for supwinid in WinceModelSupwinIds()
        call s:Log.VRB('Checking if supwin ', supwinid, ' is a terminal window in the state')
        if WinceStateWinIsTerminal(supwinid)
            call s:Log.VRB('Supwin ', supwinid, ' is a terminal window in the state')
            for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
                call s:Log.DBG('Step 1.5 hiding subwin group ', grouptypename, ' of terminal supwin ', supwinid, ' in model')
                call WinceModelHideSubwins(supwinid, grouptypename)
            endfor
        endif
    endfor

endfunction

" STEP 2: Adjust the state so that it matches the model
function! s:WinceResolveModelToState()
    " STEP 2.1: Purge the state of windows that aren't in the model
    " TODO? Do something more civilized than stomping each window
    "       individually. So far it's ok but some other group type
    "       may require it in the future. This would require a new
    "       parameter for WinAdd(Uber|Sub)winGroupType - a list of
    "       callbacks which close individual windows and not whole
    "       groups
    call s:Log.VRB('Step 2.1')
    for winid in WinceStateGetWinidsByCurrentTab()
        " WinStateCloseWindow used to close windows without noautocmd. If a
        " window triggered autocommands when closed, and those autocommands
        " closed other windows that were later in the list, this check would
        " fire. I'm leaving it here in case there are more bugs
        if !WinceStateWinExists(winid)
            call s:Log.ERR('State is inconsistent - winid ', winid, ' is both present and not present')
            continue
        endif

        let wininfo = WinceResolveIdentifyWindow(winid)
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
       \    !WinceModelUberwinGroupExists(wininfo.grouptype) ||
       \    WinceModelUberwinGroupIsHidden(wininfo.grouptype) ||
       \    WinceModelIdByInfo(wininfo) !=# winid
       \)
            call s:Log.INF("Step 2.1 removing non-model-shown or mis-model-winid'd uberwin ", wininfo.grouptype, ':', wininfo.typename, ' with winid ', winid, ' from state')
            call WinceStateCloseWindow(winid, 0)
            continue
        endif

        " If any subwin in the state isn't shown in the model or has a
        " different winid than the model lists, remove it from the state
        if wininfo.category ==# 'subwin' && (
       \    !WinceModelSupwinExists(wininfo.supwin) ||
       \    !WinceModelSubwinGroupExists(wininfo.supwin, wininfo.grouptype) ||
       \    WinceModelSubwinGroupIsHidden(wininfo.supwin, wininfo.grouptype) ||
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
                if uberwinsremoved ||
               \   !WinceCommonUberwinGroupDimensionsMatch(grouptypename)
                    let preserveduberwins[grouptypename] =
                   \    WinceCommonPreCloseAndReopenUberwins(grouptypename)
                    call s:Log.VRB('Preserved info from uberwin group ', grouptypename, ': ', preserveduberwins[grouptypename])
                    call s:Log.INF('Step 2.2 removing uberwin group ', grouptypename, ' from state')
                    call WinceCommonCloseUberwinsByGroupTypeName(grouptypename)
                    let uberwinsremoved = 1
                    let passneeded = 1
                endif
            endif
        endfor

        let toremove = {}
        for supwinid in WinceModelSupwinIds()
            call s:Log.VRB('Check subwins of supwin ', supwinid)
            let toremove[supwinid] = []
            " If we removed uberwins, flag all shown subwins for removal
            " Also flag all shown subwins of any supwin with dummy or inconsistent
            " dimensions
            if uberwinsremoved || !WinceCommonSupwinDimensionsMatch(supwinid)
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
            " WinceCommonCloseSubwinsWithHigherPriority
            for grouptypename in reverse(copy(toremove[supwinid]))
                call s:Log.VRB('Removing flagged subwin group ', supwinid, ':', grouptypename)
                if WinceCommonSubwinGroupExistsInState(supwinid, grouptypename)
                    let preservedsubwins[supwinid][grouptypename] =
                   \    WinceCommonPreCloseAndReopenSubwins(supwinid, grouptypename)
                    call s:Log.VRB('Preserved info from subwin group ', supwinid, ':', grouptypename, ': ', preservedsubwins[supwinid][grouptypename])
                    call s:Log.INF('Step 2.2 removing subwin group ', supwinid, ':', grouptypename, ' from state')
                    call WinceCommonCloseSubwins(supwinid, grouptypename)
                    let passneeded = 1
                endif
            endfor
        endfor
    endwhile

    " STEP 2.3: Add any missing windows to the state, including those that
    "           were temporarily removed, in the correct places
    " If any shown uberwin in the model isn't in the state,
    " add it to the state
    call s:Log.VRB('Step 2.3')
    for grouptypename in WinceModelShownUberwinGroupTypeNames()
        call s:Log.VRB('Checking model uberwin group ', grouptypename)
        if !WinceCommonUberwinGroupExistsInState(grouptypename)
            try
                call s:Log.INF('Step 2.3 adding uberwin group ', grouptypename, ' to state')
                let winids = WinceCommonOpenUberwins(grouptypename, 1)
                " This Model write in ResolveModelToState is unfortunate, but I
                " see no sensible way to put it anywhere else
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
                call WinceModelHideUberwins(grouptypename)
            endtry
        endif
    endfor

    " If any shown subwin in the model isn't in the state,
    " add it to the state
    for supwinid in WinceModelSupwinIds()
        for grouptypename in WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            call s:Log.VRB('Checking model subwin group ', supwinid, ':', grouptypename)
            if !WinceCommonSubwinGroupExistsInState(supwinid, grouptypename)
                call s:Log.VRB('Model subwin group ', supwinid, ':', grouptypename, ' is missing from state')
                if WinceModelSubwinGroupTypeHasAfterimagingSubwin(grouptypename)
                    call s:Log.VRB('State-missing subwin group ', supwinid, ':', grouptypename, ' is afterimaging. Afterimaging all other subwins of this group type first before restoring')
                    " Afterimaging subwins may be state-open in at most one supwin
                    " at a time. So if we're opening an afterimaging subwin, it
                    " must first be afterimaged everywhere else.
                    for othersupwinid in WinceModelSupwinIds()
                        if othersupwinid ==# supwinid
                            continue
                        endif
                        call s:Log.VRB('Checking supwin ', othersupwinid, ' for subwins of group type ', grouptypename)
                        if WinceModelSubwinGroupExists(
                       \    othersupwinid,
                       \    grouptypename
                       \) && !WinceModelSubwinGroupIsHidden(
                       \    othersupwinid,
                       \    grouptypename
                       \) && !WinceModelSubwinGroupHasAfterimagedSubwin(
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
    if WinceModelIdByInfo(WinceModelPreviousWinInfo()) && modelcurrentwinid &&
   \   WinceModelIdByInfo(s:curpos.win) !=# modelcurrentwinid
        " If the current window doesn't exist in the state, then this resolver
        " run must have closed it. Set the current window to the previous
        " window.
        if !WinceStateWinExists(WinceModelIdByInfo(s:curpos.win))
            call WinceModelSetCurrentWinInfo(WinceModelPreviousWinInfo())
        else
            call WinceModelSetPreviousWinInfo(modelcurrentwininfo)
            call WinceModelSetCurrentWinInfo(s:curpos.win)
        endif
    endif
endfunction

" Resolver
let s:resolveIsRunning = 0
function! WinceResolve()
    if s:resolveIsRunning
        call s:Log.DBG('Resolver reentrance detected')
        return
    endif
    let s:resolveIsRunning = 1
    call s:Log.DBG('Resolver start')

    " Retrieve the toIdentify functions
    call s:Log.VRB('Retrieve toIdentify functions')
    let s:toIdentifyUberwins = WinceModelToIdentifyUberwins()
    let s:toIdentifySubwins = WinceModelToIdentifySubwins()

    " STEP 0: Make sure the tab-specific model elements exist
    call s:Log.VRB('Step 0')
    if !WinceModelExists()
        call s:Log.DBG('Initialize tab-specific portion of model')
        call WinceModelInit()
    endif

    " If this is the first time running the resolver after entering a tab, run
    " the appropriate callbacks
    if t:winresolvetabenteredcond
        call s:Log.DBG('Tab entered. Running callbacks')
        for TabEnterCallback in WinceModelTabEnterPreResolveCallbacks()
            call s:Log.VRB('Running tab-entered callback ', TabEnterCallback)
            call TabEnterCallback()
        endfor
        let t:winresolvetabenteredcond = 0
    endif

    " STEP 1: The state may have changed since the last WinceResolve() call. Adapt the
    "         model to fit it.
    call s:WinceResolveStateToModel()

    " Save the cursor position to be restored at the end of the resolver. This
    " is done here because the position is stored in terms of model keys which
    " may not have existed until now
    call s:Log.VRB('Save cursor position')
    let s:curpos = WinceCommonGetCursorPosition()

    " Save the current number of tabs
    let tabcount = WinceStateGetTabCount()

    " Run the supwin-added callbacks
    if s:supwinsaddedcond
        call s:Log.DBG('Step 1 added a supwin. Running callbacks')
        for SupwinsAddedCallback in WinceModelSupwinsAddedResolveCallbacks()
            call s:Log.VRB('Running supwins-added callback ', SupwinsAddedCallback)
            call SupwinsAddedCallback()
        endfor
        let s:supwinsaddedcond = 0
    endif

    " STEP 2: Now the model is the way it should be, so adjust the state to fit it.
    call s:WinceResolveModelToState()

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

    call s:Log.DBG('Resolver end')
    let s:resolveIsRunning = 0
endfunction

" Since the resolve function runs as a CursorHold callback, autocmd events
" need to be explicitly signalled to it
augroup WinceResolve
    autocmd!
    
    " Use the TabEnter event to detect when a tab has been entered
    autocmd TabEnter * let t:winresolvetabenteredcond = 1
augroup END
