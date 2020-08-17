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
    call EchomLog('window-resolve', 'verbose', 'WinResolveIdentifyAfterimagedSubwin ', a:winid)
    let wininfo = WinModelInfoById(a:winid)
    if wininfo.category ==# 'subwin' && 
   \   WinModelSubwinIsAfterimaged(
   \       wininfo.supwin,
   \       wininfo.grouptype,
   \       wininfo.typename
   \   ) &&
   \   WinModelSubwinAibufBySubwinId(a:winid) ==# WinStateGetBufnrByWinid(a:winid)
        call EchomLog('window-resolve', 'verbose', 'Afterimaged subwin identified as ', wininfo)
        return wininfo
    endif
    call EchomLog('window-resolve', 'verbose', 'Afterimaged subwin not identifiable')
    return {'category':'none','id':a:winid}
endfunction

" Run all the toIdentify callbacks against a window until one of
" them succeeds. Return the model info obtained.
function! WinResolveIdentifyWindow(winid)
    call EchomLog('window-resolve', 'debug', 'WinResolveIdentifyWindow ', a:winid)
    for uberwingrouptypename in keys(s:toIdentifyUberwins)
        call EchomLog('window-resolve', 'verbose', 'Invoking toIdentify from ', uberwingrouptypename, ' uberwin group type')
        let uberwintypename = s:toIdentifyUberwins[uberwingrouptypename](a:winid)
        if !empty(uberwintypename)
            call EchomLog('window-resolve', 'debug', 'Window ', a:winid, ' identified as ', uberwingrouptypename, ':', uberwintypename)
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
        call EchomLog('window-resolve', 'verbose', 'Invoking toIdentify from ', subwingrouptypename, ' subwin group type')
        let subwindict = s:toIdentifySubwins[subwingrouptypename](a:winid)
        if !empty(subwindict)
            call EchomLog('window-resolve', 'debug', 'Window ', a:winid, ' identified as ', subwindict.supwin, ':', subwingrouptypename, ':', subwindict.typename)
            " If there is no supwin, or if the identified 'supwin' isn't a
            " supwin, the window we are identifying has no place in the model
            if subwindict.supwin ==# -1 ||
           \   index(uberwinids, str2nr(subwindict.supwin)) >=# 0 ||
           \   index(subwinids, str2nr(subwindict.supwin)) >=# 0
                call EchomLog('window-resolve', 'debug', 'Identified subwin gives non-supwin ', subwindict.supwin, ' as its supwin. Identification failed.')
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
    call EchomLog('window-resolve', 'verbose', 'Window still not identified. Checking if it is an afterimaged subwin.')
    let aiinfo = WinResolveIdentifyAfterimagedSubwin(a:winid)
    if aiinfo.category !=# 'none'
        " No need to sanity check the 'supwin' field like above because this
        " information already comes from the model
        return aiinfo
    endif
    call EchomLog('window-resolve', 'debug', 'Window ', a:winid, ' identified as supwin')
    return {
   \    'category': 'supwin',
   \    'id': a:winid
   \}
endfunction

" Convert a list of window info dicts (as returned by
" WinResolveIdentifyWindow) and group them by category, supwin id, group
" type, and type. Any incomplete groups are dropped.
function! WinResolveGroupInfo(wininfos)
    call EchomLog('window-resolve', 'verbose', 'WinResolveGroupInfo ', a:wininfos)
    let uberwingroupinfo = {}
    let subwingroupinfo = {}
    let supwininfo = []
    " Group the window info
    for wininfo in a:wininfos
        call EchomLog('window-resolve', 'verbose', 'Examining ', wininfo)
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
   
    call EchomLog('window-resolve', 'verbose', 'Grouped Uberwins: ', uberwingroupinfo)
    call EchomLog('window-resolve', 'verbose', 'Supwins: ', supwininfo)
    call EchomLog('window-resolve', 'verbose', 'Grouped Subwins: ', subwingroupinfo)

    " Validate groups. Prune any incomplete groups. Convert typename-keyed
    " winid dicts to lists
    for grouptypename in keys(uberwingroupinfo)
        call EchomLog('window-resolve', 'verbose', 'Validating uberwin group ', grouptypename)
        for typename in keys(uberwingroupinfo[grouptypename])
            call WinModelAssertUberwinTypeExists(grouptypename, typename)
        endfor
        let uberwingroupinfo[grouptypename].winids = []
        for typename in WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
            if !has_key(uberwingroupinfo[grouptypename], typename)
                call EchomLog('window-resolve', 'verbose', 'Uberwin with type ', typename, ' missing. Expunging group.')
                unlet uberwingroupinfo[grouptypename]
                break
            endif
            call add(uberwingroupinfo[grouptypename].winids,
                    \uberwingroupinfo[grouptypename][typename])
        endfor
    endfor
    for supwinid in keys(subwingroupinfo)
        for grouptypename in keys(subwingroupinfo[supwinid])
            call EchomLog('window-resolve', 'verbose', 'Validating subwin group ', supwinid, ':', grouptypename)
            for typename in keys(subwingroupinfo[supwinid][grouptypename])
                call WinModelAssertSubwinTypeExists(grouptypename, typename)
            endfor
            let subwingroupinfo[supwinid][grouptypename].winids = []
            for typename in WinModelSubwinTypeNamesByGroupTypeName(grouptypename)
                if !has_key(subwingroupinfo[supwinid][grouptypename], typename)
                    call EchomLog('window-resolve', 'verbose', 'Subwin with type ', typename, ' missing. Expunging group.')
                    unlet subwingroupinfo[supwinid][grouptypename]
                    break
                endif
                call add(subwingroupinfo[supwinid][grouptypename].winids,
                        \subwingroupinfo[supwinid][grouptypename][typename])
            endfor
        endfor
    endfor
    let retdict = {'uberwin':uberwingroupinfo,'supwin':supwininfo,'subwin':subwingroupinfo}

    call EchomLog('window-resolve', 'verbose', 'Grouped: ', retdict)
    return retdict
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
    call EchomLog('window-resolve', 'verbose', 'Step 1.1')
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        for typename in WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
            call EchomLog('window-resolve', 'verbose', 'Check if model uberwin ', grouptypename, ':', typename, ' is a terminal window in the state')
            let winid = WinModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': grouptypename,
           \    'typename': typename
           \})
            if winid && WinStateWinIsTerminal(winid)
                call EchomLog('window-resolve', 'info', 'Step 1.1 relisting terminal window ', winid, ' from uberwin ', grouptypename, ':', typename, 'to supwin')
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
                call EchomLog('window-resolve', 'verbose', 'Check if model subwin ', supwinid, ':', grouptypename, ':', typename, ' is a terminal window in the state')
                let winid = WinModelIdByInfo({
               \    'category': 'subwin',
               \    'supwin': supwinid,
               \    'grouptype': grouptypename,
               \    'typename': typename
               \})
                if winid && WinStateWinIsTerminal(winid)
                    call EchomLog('window-resolve', 'info', 'Step 1.1 relisting terminal window ', winid, ' from subwin ' supwinid, ':', grouptypename, ':', typename, 'to supwin')
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
    call EchomLog('window-resolve', 'verbose', 'Step 1.2')
    let modeluberwinids = WinModelUberwinIds()
    " Using a dict so no keys will be duplicated
    let uberwingrouptypestohide = {}
    for modeluberwinid in modeluberwinids
        call EchomLog('window-resolve', 'verbose', 'Checking if model uberwin ', modeluberwinid, ' still exists in state')
        if !WinStateWinExists(modeluberwinid)
           call EchomLog('window-resolve', 'verbose', 'Model uberwin ', modeluberwinid, ' does not exist in state')
           let tohide = WinModelInfoById(modeluberwinid)
           if tohide.category != 'uberwin'
               throw 'Inconsistency in model. ID ' . modeluberwinid . ' is both' .
              \      ' uberwin and ' . tohide.category       
           endif
           let uberwingrouptypestohide[tohide.grouptype] = ''
        endif
    endfor
    for tohide in keys(uberwingrouptypestohide)
         call EchomLog('window-resolve', 'debug', 'Step 1.2 hiding non-state-complete uberwin group ', tohide, ' in model')
         call WinModelHideUberwins(tohide)
    endfor

    " If any supwin in the model isn't in the state, remove it and its subwins
    " from the model
    let modelsupwinids = WinModelSupwinIds()
    for modelsupwinid in modelsupwinids
        call EchomLog('window-resolve', 'verbose', 'Checking if model supwin ', modelsupwinid, ' still exists in state')
        if !WinStateWinExists(modelsupwinid)
            call EchomLog('window-resolve', 'debug', 'Step 1.2 removing state-missing supwin ', modelsupwinid, ' from model')
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
        call EchomLog('window-resolve', 'verbose', 'Checking if model subwin ', modelsubwinid, ' still exists in state')
        if !WinStateWinExists(modelsubwinid)
           call EchomLog('window-resolve', 'verbose', 'Model subwin ', modelsubwinid, ' does not exist in state')
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
            call EchomLog('window-resolve', 'debug', 'Step 1.2 hiding non-state-complete subwin group ', supwinid, ':', subwingrouptypetohide, ' in model')
            call WinModelHideSubwins(supwinid, subwingrouptypetohide)
        endfor
    endfor

    " STEP 1.3: If any window in the state doesn't look the way the model
    "           says it should, relist it in the model
    " If any window is listed in the model as an uberwin but doesn't
    " satisfy its type's constraints, mark the uberwin group hidden
    " in the model and relist the window as a supwin. 
    call EchomLog('window-resolve', 'verbose', 'Step 1.3')
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        for typename in WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
            call EchomLog('window-resolve', 'verbose', 'Checking model uberwin ', grouptypename, ':', typename, ' for toIdentify compliance')
            let winid = WinModelIdByInfo({
           \    'category': 'uberwin',
           \    'grouptype': grouptypename,
           \    'typename': typename
           \})
            if s:toIdentifyUberwins[grouptypename](winid) !=# typename
                call EchomLog('window-resolve', 'info', 'Step 1.3 relisting non-compliant window ', winid, ' from uberwin ', grouptypename, ':', typename, ' to supwin')
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
                    call EchomLog('window-resolve', 'verbose', 'Afterimaged subwin ', supwinid, ':', grouptypename, ':', typename, ' is exempt from toIdentify compliance')
                    continue
                endif
                call EchomLog('window-resolve', 'verbose', 'Checking model subwin ', supwinid, ':', grouptypename, ':', typename, ' for toIdentify compliance')
                let identified = s:toIdentifySubwins[grouptypename](winid)
                if empty(identified) ||
                  \identified.supwin !=# supwinid ||
                  \identified.typename !=# typename
                    call EchomLog('window-resolve', 'info', 'Step 1.3 relisting non-compliant window ', winid, ' from subwin ', supwinid, ':', grouptypename, ':', typename, ' to supwin')
                    call WinModelHideSubwins(supwinid, grouptypename)
                    call WinModelAddSupwin(winid, -1, -1, -1)
                    let s:supwinsaddedcond = 1
                    break
                endif
            endfor
        endfor
    endfor

    " If any window is listed in the model as a supwin but it satisfies the
    " constraints of an uberwin or subwin, remove it and its subwins from the model.
    " STEP 1.4 will pick it up and add it as the appropriate uberwin/subwin type.
    for supwinid in WinModelSupwinIds()
        call EchomLog('window-resolve', 'verbose', 'Checking that model supwin ', supwinid, ' is still a supwin in the state')
        let wininfo = WinResolveIdentifyWindow(supwinid)
        if wininfo.category !=# 'supwin'
            call EchomLog('window-resolve', 'info', 'Winid ', supwinid, ' is listed as a supwin in the model but is identified in the state as ', wininfo.grouptype, ':', wininfo.typename, '. Removing from the model.')
            call WinModelRemoveSupwin(supwinid)
        endif
    endfor

    " STEP 1.4: If any window in the state isn't in the model, add it to the model
    " All winids in the state
    call EchomLog('window-resolve', 'verbose', 'Step 1.4')
    let statewinids = WinStateGetWinidsByCurrentTab()
    " Winids in the state that aren't in the model
    let missingwinids = []
    for statewinid in statewinids
        call EchomLog('window-resolve', 'verbose', 'Checking state winid ', statewinid, ' for model presence')
        if !WinModelWinExists(statewinid)
            call EchomLog('window-resolve', 'verbose', 'State winid ', statewinid, ' not present in model')
            call add(missingwinids, statewinid)
        endif
    endfor
    " Model info for those winids
    let missingwininfos = []
    for missingwinid in missingwinids
        call EchomLog('window-resolve', 'verbose', 'Identify model-missing window ', missingwinid)
        let missingwininfo = WinResolveIdentifyWindow(missingwinid)
        if len(missingwininfo)
            call add(missingwininfos, missingwininfo)
        endif
    endfor
    " Model info for those winids, grouped by category, supwin id, group type,
    " and type
    call EchomLog('window-resolve', 'verbose', 'Group info for model-missing windows')
    let groupedmissingwininfo = WinResolveGroupInfo(missingwininfos)
    call EchomLog('window-resolve', 'verbose', 'Add model-missing uberwins to model')
    for uberwingrouptypename in keys(groupedmissingwininfo.uberwin)
        let winids = groupedmissingwininfo.uberwin[uberwingrouptypename].winids
        call EchomLog('window-resolve', 'info', 'Step 1.4 adding uberwin group ', uberwingrouptypename, ' to model with winids ', winids)
        try
            call WinModelAddOrShowUberwins(
           \    uberwingrouptypename,
           \    winids,
           \    []
           \)
        catch /.*/
            call EchomLog('window-resolve', 'warning', 'Step 1.4 failed to add uberwin group ', uberwingrouptypename, ' to model. Possible duplicate uberwins in state.')
        endtry
    endfor
    call EchomLog('window-resolve', 'verbose', 'Add model-missing supwins to model')
    for supwinid in groupedmissingwininfo.supwin
        call EchomLog('window-resolve', 'info', 'Step 1.4 adding window ', supwinid, ' to model as supwin')
        call WinModelAddSupwin(supwinid, -1, -1, -1)
        let s:supwinsaddedcond = 1
    endfor
    call EchomLog('window-resolve', 'verbose', 'Add model-missing subwins to model')
    for supwinid in keys(groupedmissingwininfo.subwin)
        call EchomLog('window-resolve', 'verbose', 'Subwins of supwin ', supwinid)
        if !WinModelSupwinExists(supwinid)
            call EchomLog('window-resolve', 'verbose', 'Supwin ', supwinid, ' does not exist')
            continue
        endif
        for subwingrouptypename in keys(groupedmissingwininfo.subwin[supwinid])
            let winids = groupedmissingwininfo.subwin[supwinid][subwingrouptypename].winids
            call EchomLog('window-resolve', 'info', 'Step 1.4 adding subwin group ', supwinid, ':', subwingrouptypename, ' to model with winids ', winids)
            try
                call WinModelAddOrShowSubwins(
               \    supwinid,
               \    subwingrouptypename,
               \    winids,
               \    []
               \)
            catch /.*/
                call EchomLog('window-resolve', 'warning', 'Step 1.4 failed to add subwin group ', subwingrouptypename, ' to model. Possible duplicate subwins in state.')
            endtry
        endfor
    endfor

    " STEP 1.5: Supwins that have become terminal windows need to have their
    "      subwins hidden, but this must be done after STEP 1.4 which would add the
    "      subwins back
    "      If any supwin is a terminal window with shown subwins, mark them as
    "      hidden in the model
    call EchomLog('window-resolve', 'verbose', 'Step 1.5')
    for supwinid in WinModelSupwinIds()
        call EchomLog('window-resolve', 'verbose', 'Checking if supwin ', supwinid, ' is a terminal window in the state')
        if WinStateWinIsTerminal(supwinid)
            call EchomLog('window-resolve', 'verbose', 'Supwin ', supwinid, ' is a terminal window in the state')
            for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
                call EchomLog('window-resolve', 'debug', 'Step 1.5 hiding subwin group ', grouptypename, ' of terminal supwin ', supwinid, ' in model')
                call WinModelHideSubwins(supwinid, grouptypename)
            endfor
        endif
    endfor

endfunction

" STEP 2: Adjust the state so that it matches the model
function! s:WinResolveModelToState()
    " STEP 2.1: Purge the state of windows that aren't in the model
    " TODO? Do something more civilized than stomping each window
    "       individually. So far it's ok but some other group type
    "       may require it in the future. This would require a new
    "       parameter for WinAdd(Uber|Sub)winGroupType - a list of
    "       callbacks which close individual windows and not whole
    "       groups
    call EchomLog('window-resolve', 'verbose', 'Step 2.1')
    for winid in WinStateGetWinidsByCurrentTab()
        " I did actually see this get logged once, so I'm leaving it in
        if !WinStateWinExists(winid)
            call EchomLog('window-resolve', 'error', 'State is inconsistent - winid ', winid, ' is both present and not present')
            continue
        endif

        let wininfo = WinResolveIdentifyWindow(winid)
        call EchomLog('window-resolve', 'debug', 'Identified state window ', winid, ' as ', wininfo)

        " If any window in the state isn't categorizable, remove it from the
        " state
        if wininfo.category ==# 'none'
            call EchomLog('window-resolve', 'info', 'Step 2.1 removing uncategorizable window ', winid, ' from state')
            call WinStateCloseWindow(winid)
            continue
        endif

        " If any supwin in the state isn't in the model, remove it from the
        " state.
        if wininfo.category ==# 'supwin' && !WinModelSupwinExists(wininfo.id)
            call EchomLog('window-resolve', 'info', 'Step 2.1 removing supwin ', winid, ' from state')
            call WinStateCloseWindow(winid)
            continue
        endif

        " If any uberwin in the state isn't shown in the model or has a
        " different winid than the model lists, remove it from the state
        if wininfo.category ==# 'uberwin' && (
       \    !WinModelUberwinGroupExists(wininfo.grouptype) ||
       \    WinModelUberwinGroupIsHidden(wininfo.grouptype) ||
       \    WinModelIdByInfo(wininfo) !=# winid
       \)
            call EchomLog('window-resolve', 'info', "Step 2.1 removing non-model-shown or mis-model-winid'd uberwin ", wininfo.grouptype, ':', wininfo.typename, ' with winid ', winid, ' from state')
            call WinStateCloseWindow(winid)
            continue
        endif

        " If any subwin in the state isn't shown in the model or has a
        " different winid than the model lists, remove it from the state
        if wininfo.category ==# 'subwin' && (
       \    !WinModelSupwinExists(wininfo.supwin) ||
       \    !WinModelSubwinGroupExists(wininfo.supwin, wininfo.grouptype) ||
       \    WinModelSubwinGroupIsHidden(wininfo.supwin, wininfo.grouptype) ||
       \    WinModelIdByInfo(wininfo) !=# winid
       \)
           call EchomLog('window-resolve', 'info', "Step 2.1 removing non-model-shown or mis-model-winid'd subwin ", wininfo.supwin, ':', wininfo.grouptype, ':', wininfo.typename, ' with winid ', winid, ' from state')
           call WinStateCloseWindow(winid)
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
    call EchomLog('window-resolve', 'verbose', 'Step 2.2')
    let preserveduberwins = {}
    let preservedsubwins = {}
    let passneeded = 1
    while passneeded
        call EchomLog('window-resolve', 'debug', 'Start pass')
        let passneeded = 0
        " If any uberwins have dummy or inconsistent dimensions, remove them from the
        " state along with any other shown uberwin groups with higher priority.
        let uberwinsremoved = 0
        for grouptypename in WinModelShownUberwinGroupTypeNames()
            call EchomLog('window-resolve', 'verbose', 'Check uberwin group ', grouptypename)
            if WinCommonUberwinGroupExistsInState(grouptypename)
                if uberwinsremoved ||
               \   !WinCommonUberwinGroupDimensionsMatch(grouptypename)
                    let preserveduberwins[grouptypename] =
                   \    WinCommonPreCloseAndReopenUberwins(grouptypename)
                    call EchomLog('window-resolve', 'verbose', 'Preserved info from uberwin group ', grouptypename, ': ', preserveduberwins[grouptypename])
                    call EchomLog('window-resolve', 'info', 'Step 2.2 removing uberwin group ', grouptypename, ' from state')
                    call WinCommonCloseUberwinsByGroupTypeName(grouptypename)
                    let uberwinsremoved = 1
                    let passneeded = 1
                endif
            endif
        endfor

        let toremove = {}
        for supwinid in WinModelSupwinIds()
            call EchomLog('window-resolve', 'verbose', 'Check subwins of supwin ', supwinid)
            let toremove[supwinid] = []
            " If we removed uberwins, flag all shown subwins for removal
            " Also flag all shown subwins of any supwin with dummy or inconsistent
            " dimensions
            if uberwinsremoved || !WinCommonSupwinDimensionsMatch(supwinid)
                call EchomLog('window-resolve', 'debug', 'Flag all subwin groups for supwin ', supwinid, ' for removal from state')
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
                    call EchomLog('window-resolve', 'verbose', 'Check subwin group ', supwinid, ':', grouptypename)
                    if WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
                        if subwinsflagged || !WinCommonSubwinGroupDimensionsMatch(
                       \    supwinid,
                       \    grouptypename
                       \)
                            call EchomLog('window-resolve', 'debug', 'Flag subwin group ', supwinid, ':', grouptypename, ' for removal from state')
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
                call EchomLog('window-resolve', 'verbose', 'Removing flagged subwin group ', supwinid, ':', grouptypename)
                if WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
                    let preservedsubwins[supwinid][grouptypename] =
                   \    WinCommonPreCloseAndReopenSubwins(supwinid, grouptypename)
                    call EchomLog('window-resolve', 'verbose', 'Preserved info from subwin group ', supwinid, ':', grouptypename, ': ', preservedsubwins[supwinid][grouptypename])
                    call EchomLog('window-resolve', 'info', 'Step 2.2 removing subwin group ', supwinid, ':', grouptypename, ' from state')
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
    call EchomLog('window-resolve', 'verbose', 'Step 2.3')
    for grouptypename in WinModelShownUberwinGroupTypeNames()
        call EchomLog('window-resolve', 'verbose', 'Checking model uberwin group ', grouptypename)
        if !WinCommonUberwinGroupExistsInState(grouptypename)
            try
                call EchomLog('window-resolve', 'info', 'Step 2.3 adding uberwin group ', grouptypename, ' to state')
                let winids = WinCommonOpenUberwins(grouptypename)
                " This Model write in ResolveModelToState is unfortunate, but I
                " see no sensible way to put it anywhere else
                call WinModelChangeUberwinIds(grouptypename, winids)
                if has_key(preserveduberwins, grouptypename)
                    call EchomLog('window-resolve', 'debug', 'Uberwin group ', grouptypename, ' was closed in Step 2.2. Restoring.')
                    call WinCommonPostCloseAndReopenUberwins(
                   \    grouptypename,
                   \    preserveduberwins[grouptypename]
                   \)
                endif
            catch /.*/
                call EchomLog('window-resolve', 'warning', 'Step 2.3 failed to add ', grouptypename, ' uberwin group to state:')
                call EchomLog('window-resolve', 'debug', v:throwpoint)
                call EchomLog('window-resolve', 'warning', v:exception)
                call WinModelHideUberwins(grouptypename)
            endtry
        endif
    endfor

    " If any shown subwin in the model isn't in the state,
    " add it to the state
    for supwinid in WinModelSupwinIds()
        for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
            call EchomLog('window-resolve', 'verbose', 'Checking model subwin group ', supwinid, ':', grouptypename)
            if !WinCommonSubwinGroupExistsInState(supwinid, grouptypename)
                call EchomLog('window-resolve', 'verbose', 'Model subwin group ', supwinid, ':', grouptypename, ' is missing from state')
                if WinModelSubwinGroupTypeHasAfterimagingSubwin(grouptypename)
                    call EchomLog('window-resolve', 'verbose', 'State-missing subwin group ', supwinid, ':', grouptypename, ' is afterimaging. Afterimaging all other subwins of this group type first before restoring')
                    " Afterimaging subwins may be state-open in at most one supwin
                    " at a time. So if we're opening an afterimaging subwin, it
                    " must first be afterimaged everywhere else.
                    for othersupwinid in WinModelSupwinIds()
                        if othersupwinid ==# supwinid
                            continue
                        endif
                        call EchomLog('window-resolve', 'verbose', 'Checking supwin ', othersupwinid, ' for subwins of group type ', grouptypename)
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
                            call EchomLog('window-resolve', 'debug', 'Step 2.3 afterimaging subwin group ', othersupwinid, ':', grouptypename)
                            call WinCommonAfterimageSubwinsByInfo(
                           \    othersupwinid,
                           \    grouptypename
                           \)
                        endif
                    endfor
                endif
                try
                    call EchomLog('window-resolve', 'info', 'Step 2.3 adding subwin group ', supwinid, ':', grouptypename, ' to state')
                    let winids = WinCommonOpenSubwins(supwinid, grouptypename)
                    " This Model write in ResolveModelToState is unfortunate, but I
                    " see no sensible way to put it anywhere else
                    call WinModelChangeSubwinIds(supwinid, grouptypename, winids)
                    if has_key(preservedsubwins, supwinid) &&
                   \   has_key(preservedsubwins[supwinid], grouptypename)
                        call EchomLog('window-resolve', 'debug', 'Subwin group ', supwinid, ':', grouptypename, ' was closed in Step 2.2. Restoring.')
                        call WinCommonPostCloseAndReopenSubwins(
                       \    supwinid,
                       \    grouptypename,
                       \    preservedsubwins[supwinid][grouptypename]
                       \)
                    endif
                catch /.*/
                    call EchomLog('window-resolve', 'warning', 'Step 2.3 failed to add ', grouptypename, ' subwin group to supwin ', supwinid, ':')
                    call EchomLog('window-resolve', 'debug', v:throwpoint)
                    call EchomLog('window-resolve', 'warning', v:exception)
                    call WinModelHideSubwins(supwinid, grouptypename)
                endtry
            endif
        endfor
    endfor
endfunction

" STEP 3: Make sure that the subwins are afterimaged according to the cursor's
"         final position
function! s:WinResolveCursor()
    " STEP 3.1: See comments on WinCommonUpdateAfterimagingByCursorWindow
    call EchomLog('window-resolve', 'verbose', 'Step 3.1')
    call WinCommonUpdateAfterimagingByCursorWindow(s:curpos.win)

    " STEP 3.2: If the model's current window does not match the state's
    "           current window (as it was at the start of this resolver run), then
    "           the state's current window was touched between resolver runs by
    "           something other than the user operations. That other thing won't have
    "           updated the model's previous window, so update it here by using the
    "           model's current window. Then update the model's current window using
    "           the state's current window.
    call EchomLog('window-resolve', 'verbose', 'Step 3.2')
    let modelcurrentwininfo = WinModelCurrentWinInfo()
    let modelcurrentwinid = WinModelIdByInfo(modelcurrentwininfo)
    if WinModelIdByInfo(WinModelPreviousWinInfo()) && modelcurrentwinid &&
   \   WinModelIdByInfo(s:curpos.win) !=# modelcurrentwinid
        call WinModelSetPreviousWinInfo(modelcurrentwininfo)
        call WinModelSetCurrentWinInfo(s:curpos.win)
    endif
endfunction

" Resolver
let s:resolveIsRunning = 0
function! WinResolve()
    if s:resolveIsRunning
        call EchomLog('window-resolve', 'debug', 'Resolver reentrance detected')
        return
    endif
    let s:resolveIsRunning = 1
    call EchomLog('window-resolve', 'debug', 'Resolver start')

    " Retrieve the toIdentify functions
    call EchomLog('window-resolve', 'verbose', 'Retrieve toIdentify functions')
    let s:toIdentifyUberwins = WinModelToIdentifyUberwins()
    let s:toIdentifySubwins = WinModelToIdentifySubwins()

    " STEP 0: Make sure the tab-specific model elements exist
    call EchomLog('window-resolve', 'verbose', 'Step 0')
    if !WinModelExists()
        call EchomLog('window-resolve', 'debug', 'Initialize tab-specific portion of model')
        call WinModelInit()
    endif

    " If this is the first time running the resolver after entering a tab, run
    " the appropriate callbacks
    if t:winresolvetabenteredcond
        call EchomLog('window-resolve', 'debug', 'Tab entered. Running callbacks')
        for TabEnterCallback in WinModelTabEnterPreResolveCallbacks()
            call EchomLog('window-resolve', 'verbose', 'Running tab-entered callback ', TabEnterCallback)
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
    call EchomLog('window-resolve', 'verbose', 'Save cursor position')
    let s:curpos = WinCommonGetCursorPosition()

    " Save the current number of tabs
    let tabcount = WinStateGetTabCount()

    " Run the supwin-added callbacks
    if s:supwinsaddedcond
        call EchomLog('window-resolve', 'debug', 'Step 1 added a supwin. Running callbacks')
        for SupwinsAddedCallback in WinModelSupwinsAddedResolveCallbacks()
            call EchomLog('window-resolve', 'verbose', 'Running supwins-added callback ', SupwinsAddedCallback)
            call SupwinsAddedCallback()
        endfor
        let s:supwinsaddedcond = 0
    endif

    " STEP 2: Now the model is the way it should be, so adjust the state to fit it.
    call s:WinResolveModelToState()

    " It is possible that STEP 2 closed the tab, and we are now in a
    " different tab. If that is the case, end the resolver run
    " immediately. We can tell the tab has been closed by checking the number
    " of tabs. The resolver will never open a new tab or rearrange existing
    " tabs.
    if tabcount !=# WinStateGetTabCount()
        let s:resolveIsRunning = 0
        return
    endif

    " STEP 3: The model and state are now consistent with each other, but
    "         afterimaging and tracked cursor positions may be inconsistent with the
    "         final position of the cursor. Make it consistent.
    call s:WinResolveCursor()

    " STEP 4: Now everything is consistent, so record the dimensions of all
    "         windows in the model. The next resolver run will consider those
    "         dimensions as being the last known consistent data, unless a
    "         user operation overwrites them with its own (also consistent)
    "         data.
    call EchomLog('window-resolve', 'verbose', 'Step 4')
    call WinCommonRecordAllDimensions()

    " Restore the cursor position from when the resolver started
    call EchomLog('window-resolve', 'verbose', 'Restore cursor position')
    call WinCommonRestoreCursorPosition(s:curpos)
    let s:curpos = {}

    call EchomLog('window-resolve', 'debug', 'Resolver end')
    let s:resolveIsRunning = 0
endfunction

" Since the resolve function runs as a CursorHold callback, autocmd events
" need to be explicitly signalled to it
augroup WinResolve
    autocmd!
    
    " Use the TabEnter event to detect when a tab has been entered
    autocmd TabEnter * let t:winresolvetabenteredcond = 1
augroup END
