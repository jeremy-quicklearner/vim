" Wince User Operations
" See wince.vim
let s:Log = jer_log#LogFunctions('wince-user')


" Resolver callback registration

" Register a callback to run at the beginning of the resolver, when the
" resolver runs for the first time after entering a tab
function! WinceAddTabEnterPreResolveCallback(callback)
    call WinceModelAddTabEnterPreResolveCallback(a:callback)
    call s:Log.CFG('TabEnter pre-resolve callback: ', a:callback)
endfunction

" Register a callback to run after any successful user operation that changes
" the state or model and leaves them consistent
function! WinceAddPostUserOperationCallback(callback)
    call WinceModelAddPostUserOperationCallback(a:callback)
    call s:Log.CFG('Post-user operation callback: ', a:callback)
endfunction

function! s:RunPostUserOpCallbacks()
    call s:Log.DBG('Running post-user-operation callbacks')
    for PostUserOpCallback in WinceModelPostUserOperationCallbacks()
        call s:Log.VRB('Running post-user-operation callback ', PostUserOpCallback)
        call PostUserOpCallback()
    endfor
endfunction

" Group Types

" Add an uberwin group type. One uberwin group type represents one or more uberwins
" which are opened together
" one window
" name:           The name of the uberwin group type
" typenames:      The names of the uberwin types in the group
" statuslines:    The statusline strings of the uberwin types in the group
" flag:           Flag to insert into the tabline when the uberwins are shown
" hidflag:        Flag to insert into the tabline when the uberwins are hidden
" flagcol:        Number between 1 and 9 representing which User highlight group
"                 to use for the tabline flag
" priority:       uberwin groups will be opened in order of ascending priority
" canHaveLoclist: Flag (one for each uberwin type in the group) signifying
"                 whether uberwins of that type are allowed to have location lists
" widths:         Widths of uberwins. -1 means variable width.
" heights:        Heights of uberwins. -1 means variable height.
" toOpen:         Function that opens uberwins of this group type and returns their
"                 window IDs. This function is required not to move the cursor
"                 between windows before opening the uberwins
" toClose:        Function that closes the uberwins of this group type.
" toIdentify:     Function that, when called in an uberwin of a type from this group
"                 type, returns the type name. Returns an empty string if called from
"                 any other window
function! WinceAddUberwinGroupType(name, typenames, statuslines,
                                \flag, hidflag, flagcol,
                                \priority, canHaveLoclist,
                                \widths, heights, toOpen, toClose,
                                \toIdentify)
    call WinceModelAddUberwinGroupType(a:name, a:typenames, a:statuslines,
                                    \a:flag, a:hidflag, a:flagcol,
                                    \a:priority, a:canHaveLoclist,
                                    \a:widths, a:heights,
                                    \a:toOpen, a:toClose, a:toIdentify)
    call s:Log.CFG('Uberwin group type: ', a:name)
endfunction

" Add a subwin group type. One subwin group type represents the types of one or more
" subwins which are opened together
" one window
" name:                The name of the subwin group type
" typenames:           The names of the subwin types in the group
" statuslines:         The statusline strings of the uberwin types in the group
" flag:                Flag to insert into the statusline of the supwin of subwins of
"                      types in this group type when the subwins are shown
" hidflag:             Flag to insert into the statusline of the supwin of subwins of
"                      types in this group type when the subwins are hidden
" flagcol:             Number between 1 and 9 representing which User highlight group
"                      to use for the statusline flag
" priority:            Subwins for a supwin will be opened in order of ascending
"                      priority
" afterimaging:        List of flags for each subwin type in the group. If true,
"                      afterimage
"                      subwins of that type when they and their supwin lose focus
" canHaveLoclist:      Flag (one for each uberwin type in the group) signifying
"                      whether uberwins of that type are allowed to have location lists
" stompWithBelowRight: Value to use for the the 'splitbelow' and 'splitright'
"                      options when bypassing ToClose and closing windows of
"                      this group type directly. Set this to 0 if your subwin
"                      group opens above or to the left of the supwin, and to 1
"                      otherwise.
" widths:              Widths of subwins. -1 means variable width.
" heights:             Heights of subwins. -1 means variable height.
" toOpen:              Function that, when called from the supwin, opens subwins of these
"                      types and returns their window IDs.
" toClose:             Function that, when called from a supwin, closes the the subwins of
"                      this group type for the supwin.
" toIdentify:          Function that, when called in a subwin of a type from this group
"                      type, returns a dict with the type name and supwin ID (with keys
"                      'typename' and 'supwin' repspectively). Returns an enpty dict if
"                      called from any other window
function! WinceAddSubwinGroupType(name, typenames, statuslines,
                               \flag, hidflag, flagcol,
                               \priority, afterimaging, canHaveLoclist, stompWithBelowRight,
                               \widths, heights,
                               \toOpen, toClose, toIdentify)
    call WinceModelAddSubwinGroupType(a:name, a:typenames, a:statuslines,
                                   \a:flag, a:hidflag, a:flagcol,
                                   \a:priority, a:afterimaging, a:canHaveLoclist, a:stompWithBelowRight,
                                   \a:widths, a:heights,
                                   \a:toOpen, a:toClose, a:toIdentify)
    call s:Log.CFG('Subwin group type: ', a:name)
endfunction

" Uberwins

" For tabline generation
function! WinceUberwinFlagsStr()
    " Due to a bug in Vim, this function sometimes throws E315 in terminal
    " windows
    try
        call s:Log.DBG('Retrieving Uberwin flags string')
        return WinceModelUberwinFlagsStr()
    catch /.*/
        call s:Log.DBG('Failed to retrieve Uberwin flags: ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return ''
    endtry
endfunction

function! WinceAddUberwinGroup(grouptypename, hidden, suppresserror)
    try
        call WinceModelAssertUberwinGroupDoesntExist(a:grouptypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.DBG('WinceAddUberwinGroup cannot add uberwin group ', a:grouptypename, ': ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    " If we're adding the uberwin group as hidden, add it only to the model
    if a:hidden
        call s:Log.INF('WinceAddUberwinGroup hidden ', a:grouptypename)
        call WinceModelAddUberwins(a:grouptypename, [], [])
        call s:RunPostUserOpCallbacks()
        return
    endif
    
    call s:Log.INF('WinceAddUberwinGroup shown ', a:grouptypename)

    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try
        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let grouptype = g:wince_uberwingrouptype[a:grouptypename]
        let highertypes = WinceCommonCloseUberwinsWithHigherPriorityThan(grouptype.name)
        call s:Log.VRB('Closed higher-priority uberwin groups ', highertypes)
        try
            try
                let winids = WinceCommonDoWithoutSubwins(info.win, function('WinceCommonOpenUberwins'), [a:grouptypename], 1)
                let dims = WinceStateGetWinDimensionsList(winids)
                call s:Log.VRB('Opened uberwin group ', a:grouptypename, ' in state with winids ', winids, ' and dimensions ', dims)
                call WinceModelAddUberwins(a:grouptypename, winids, dims)
                call s:Log.VRB('Added uberwin group ', a:grouptypename, ' to model')

            catch /.*/
                if !a:suppresserror
                    call s:Log.WRN('WinceAddUberwinGroup failed to open ', a:grouptypename, ' uberwin group:')
                    call s:Log.DBG(v:throwpoint)
                    call s:Log.WRN(v:exception)
                endif
                call WinceAddUberwinGroup(a:grouptypename, 1, a:suppresserror)
                return
            endtry

        " Reopen the uberwins we closed
        finally
            call WinceCommonDoWithoutSubwins(info.win, function('WinceCommonReopenUberwins'), [highertypes], 1)
            call s:Log.VRB('Reopened higher-priority uberwins groups')
        endtry
    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceRemoveUberwinGroup(grouptypename)
    call s:Log.INF('WinceRemoveUberwinGroup ', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try
        let removed = 0
        if !WinceModelUberwinGroupIsHidden(a:grouptypename)
            call WinceCommonCloseUberwinsByGroupTypeName(a:grouptypename)
            call s:Log.VRB('Closed uberwin group ', a:grouptypename, ' in state')
            let removed = 1
        endif

        call WinceModelRemoveUberwins(a:grouptypename)
        call s:Log.VRB('Removed uberwin group ', a:grouptypename, ' from model')

        if removed
            " Closing an uberwin changes how much space is available to supwins
            " and their subwins. Close and reopen all subwins.
            call WinceCommonCloseAndReopenAllShownSubwins(info.win)
            call s:Log.VRB('Closed and reopened all shown subwins')
        endif

    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceHideUberwinGroup(grouptypename)
    try
        call WinceModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    catch /.*/
        call s:Log.DBG('WinceHideUberwinGroup cannot hide uberwin group ', a:grouptypename, ': ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.INF('WinceHideUberwinGroup ', a:grouptypename)

    let grouptype = g:wince_uberwingrouptype[a:grouptypename]

    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try
        call WinceCommonCloseUberwinsByGroupTypeName(a:grouptypename)
        call s:Log.VRB('Closed uberwin group ', a:grouptypename, ' in state')
        call WinceModelHideUberwins(a:grouptypename)
        call s:Log.VRB('Hid uberwin group ', a:grouptypename, ' in model')

        " Closing an uberwin changes how much space is available to supwins
        " and their subwins. Close and reopen all subwins.
        call WinceCommonCloseAndReopenAllShownSubwins(info.win)
        call s:Log.VRB('Closed and reopened all shown subwins')

    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceShowUberwinGroup(grouptypename, suppresserror)
    try
        call WinceModelAssertUberwinGroupIsHidden(a:grouptypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.DBG('WinceShowUberwinGroup cannot show uberwin group ', a:grouptypename, ': ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.INF('WinceShowUberwinGroup ', a:grouptypename)

    let grouptype = g:wince_uberwingrouptype[a:grouptypename]

    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try
        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinceCommonCloseUberwinsWithHigherPriorityThan(grouptype.name)
        call s:Log.VRB('Closed higher-priority uberwin groups ', highertypes)
        try
            try
                let winids = WinceCommonDoWithoutSubwins(info.win, function('WinceCommonOpenUberwins'), [a:grouptypename], 1)
                let dims = WinceStateGetWinDimensionsList(winids)
                call s:Log.VRB('Opened uberwin group ', a:grouptypename, ' in state with winids ', winids, ' and dimensions ', dims)
                call WinceModelShowUberwins(a:grouptypename, winids, dims)
                call s:Log.VRB('Showed uberwin group ', a:grouptypename, ' in model')

            catch /.*/
                if a:suppresserror
                    return
                endif
                call s:Log.WRN('WinceShowUberwinGroup failed to open ', a:grouptypename, ' uberwin group:')
                call s:Log.DBG(v:throwpoint)
                call s:Log.WRN(v:exception)
                return
            endtry
        " Reopen the uberwins we closed
        finally
            call WinceCommonDoWithoutSubwins(info.win, function('WinceCommonReopenUberwins'), [highertypes], 1)
            call s:Log.VRB('Reopened higher-priority uberwins groups')
        endtry
    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Subwins

" For supwins' statusline generation
function! WinceSubwinFlagsForGlobalStatusline()
    let flagsstr = ''

    " Due to a bug in Vim, these functions sometimes throws E315 in terminal
    " windows
    try
        call s:Log.DBG('Retrieving subwin flags string for current supwin')
        for grouptypename in WinceModelSubwinGroupTypeNames()
            call s:Log.VRB('Retrieving subwin flags string for subwin ', grouptypename, ' of current supwin')
            let flagsstr .= WinceCommonSubwinFlagStrByGroup(grouptypename)
        endfor
    catch /.*/
        call s:Log.DBG('Failed to retrieve Subwin flags: ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return ''
    endtry

    call s:Log.VRB('Subwin flags string for current supwin: ', flagsstr)
    return flagsstr
endfunction

function! WinceAddSubwinGroup(supwinid, grouptypename, hidden, suppresserror)
    try
        call WinceModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.DBG('WinceAddSubwinGroup cannot add subwin group ', a:supwinid, ':', a:grouptypename, ': ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    " If we're adding the subwin group as hidden, add it only to the model
    if a:hidden
        call s:Log.INF('WinceAddSubwinGroup hidden ', a:supwinid, ':', a:grouptypename)
        call WinceModelAddSubwins(a:supwinid, a:grouptypename, [], [])
        call s:RunPostUserOpCallbacks()
        return
    endif

    call s:Log.INF('WinceAddSubwinGroup shown ', a:supwinid, ':', a:grouptypename)

    let grouptype = g:wince_subwingrouptype[a:grouptypename]
    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinceCommonCloseSubwinsWithHigherPriorityThan(a:supwinid, a:grouptypename)
        call s:Log.VRB('Closed higher-priority subwin groups for supwin ', a:supwinid, ': ', highertypes)
        try
            try
                let winids = WinceCommonOpenSubwins(a:supwinid, a:grouptypename)
                let supwinnr = WinceStateGetWinnrByWinid(a:supwinid)
                let reldims = WinceStateGetWinRelativeDimensionsList(winids, supwinnr)
                call s:Log.VRB('Opened subwin group ', a:supwinid, ':', a:grouptypename, ' in state with winids ', winids, ' and relative dimensions ', reldims)
                call WinceModelAddSubwins(a:supwinid, a:grouptypename, winids, reldims)
                call s:Log.VRB('Added subwin group ', a:supwinid, ':', a:grouptypename, ' to model')
            catch /.*/
                if !a:suppresserror
                    call s:Log.WRN('WinceAddSubwinGroup failed to open ', a:grouptypename, ' subwin group for supwin ', a:supwinid, ':')
                    call s:Log.DBG(v:throwpoint)
                    call s:Log.WRN(v:exception)
                endif
                call WinceAddSubwinGroup(a:supwinid, a:grouptypename, 1, a:suppresserror)
                return
            endtry

        " Reopen the subwins we closed
        finally
            call WinceCommonReopenSubwins(a:supwinid, highertypes)
            call s:Log.VRB('Reopened higher-priority subwin groups')
        endtry

    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceRemoveSubwinGroup(supwinid, grouptypename)
    try
        let grouptype = WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    catch /.*/
        call s:Log.DBG('WinceRemoveSubwinGroup cannot remove subwin group ', a:supwinid, ':', a:grouptypename, ': ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.INF('WinceRemoveSubwinGroup ', a:supwinid, ':', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try

        let removed = 0
        if !WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
            call WinceCommonCloseSubwins(a:supwinid, a:grouptypename)
            call s:Log.VRB('Closed subwin group ', a:supwinid, ':', a:grouptypename, ' in state')
            let removed = 1
        endif

        call WinceModelRemoveSubwins(a:supwinid, a:grouptypename)
        call s:Log.VRB('Removed subwin group ', a:supwinid, ':', a:grouptypename, ' from model')

        if removed
            call WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
           \    a:supwinid,
           \    a:grouptypename
           \)
            call s:Log.VRB('Closed and reopened all shown subwins of supwin ', a:supwinid, ' with priority higher than ', a:grouptypename)
        endif

    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceHideSubwinGroup(winid, grouptypename)
    try
        let supwinid = WinceModelSupwinIdBySupwinOrSubwinId(a:winid)
        call WinceModelAssertSubwinGroupIsNotHidden(supwinid, a:grouptypename)
    catch /.*/
        call s:Log.DBG('WinceHideSubwinGroup cannot hide subwin group ', a:winid, ':', a:grouptypename, ': ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.INF('WinceHideSubwinGroup ', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try
        let grouptype = g:wince_subwingrouptype[a:grouptypename]

        call WinceCommonCloseSubwins(supwinid, a:grouptypename)
        call s:Log.VRB('Closed subwin group ', supwinid, ':', a:grouptypename, ' in state')
        call WinceModelHideSubwins(supwinid, a:grouptypename)
        call s:Log.VRB('Hid subwin group ', supwinid, ':', a:grouptypename, ' in model')
        call WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
       \    supwinid,
       \    a:grouptypename
       \)
        call s:Log.VRB('Closed and reopened all shown subwins of supwin ', supwinid, ' with priority higher than ', a:grouptypename)

    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceShowSubwinGroup(srcid, grouptypename, suppresserror)
    try
        let supwinid = WinceModelSupwinIdBySupwinOrSubwinId(a:srcid)
        call WinceModelAssertSubwinGroupIsHidden(supwinid, a:grouptypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.DBG('WinceShowSubwinGroup cannot show subwin group ', a:srcid, ':', a:grouptypename, ': ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    let grouptype = g:wince_subwingrouptype[a:grouptypename]

    call s:Log.INF('WinceShowSubwinGroup ', supwinid, ':', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try
        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinceCommonCloseSubwinsWithHigherPriorityThan(supwinid, a:grouptypename)
        call s:Log.VRB('Closed higher-priority subwin groups for supwin ', supwinid, ': ', highertypes)
        try
            try
                let winids = WinceCommonOpenSubwins(supwinid, a:grouptypename)
                let supwinnr = WinceStateGetWinnrByWinid(supwinid)
                let reldims = WinceStateGetWinRelativeDimensionsList(winids, supwinnr)
                call s:Log.VRB('Opened subwin group ', supwinid, ':', a:grouptypename, ' in state with winids ', winids, ' and relative dimensions ', reldims)
                call WinceModelShowSubwins(supwinid, a:grouptypename, winids, reldims)
                call s:Log.VRB('Showed subwin group ', supwinid, ':', a:grouptypename, ' in model')

            catch /.*/
                if a:suppresserror
                    return
                endif
                call s:Log.WRN('WinceShowSubwinGroup failed to open ', a:grouptypename, ' subwin group for supwin ', supwinid, ':')
                call s:Log.DBG(v:throwpoint)
                call s:Log.WRN(v:exception)
                return
            endtry

        " Reopen the subwins we closed
        finally
            call WinceCommonReopenSubwins(supwinid, highertypes)
            call s:Log.VRB('Reopened higher-priority subwin groups')
        endtry

    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry

    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Retrieve subwins and supwins' statuslines from the model
function! WinceNonDefaultStatusLine()
    call s:Log.DBG('Retrieving non-default statusline for current window')
    let info = WinceCommonGetCursorPosition().win
    return WinceModelStatusLineByInfo(info)
endfunction

" Execute a Ctrl-W command under various conditions specified by flags
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. It is designed to be used only by the Commands and
" Mappings, which ensure consistency by passing carefully-chosen flags.
" In particular, the 'relyonresolver' flag causes the resolver to be invoked
" at the end of the operation
function! WinceDoCmdWithFlags(cmd,
                            \ count,
                            \ startmode,
                            \ preservecursor,
                            \ ifuberwindonothing, ifsubwingotosupwin,
                            \ dowithoutuberwins, dowithoutsubwins,
                            \ relyonresolver)
    call s:Log.INF('WinceDoCmdWithFlags ' . a:cmd . ' ' . a:count . ' ' . string(a:startmode) . ' [' . a:preservecursor . ',' . a:ifuberwindonothing . ',' . a:ifsubwingotosupwin . ',' . a:dowithoutuberwins . ',' . a:dowithoutsubwins . ',' . ',' . a:relyonresolver . ']')
    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)

    if info.win.category ==# 'uberwin' && a:ifuberwindonothing
        call s:Log.WRN('Cannot run wincmd ', a:cmd, ' in uberwin')
        return a:startmode
    endif

    let endmode = a:startmode
    if info.win.category ==# 'subwin' && a:ifsubwingotosupwin
        call s:Log.DBG('Going from subwin to supwin')
        " Drop the mode. It'll be restored from a:startmode if we restore the
        " cursor position
        let endmode = WinceGotoSupwin(info.win.supwin, 0)
    endif


    let cmdinfo = WinceCommonGetCursorPosition()
    call s:Log.VRB('Running command from window ', cmdinfo)

    let reselect = 1
    if a:relyonresolver
        let reselect = 0
    endif

    try
        if a:dowithoutuberwins && a:dowithoutsubwins
            call s:Log.DBG('Running command without uberwins or subwins')
            let endmode = WinceCommonDoWithoutUberwinsOrSubwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, a:cmd, endmode], reselect)
        elseif a:dowithoutuberwins
            call s:Log.DBG('Running command without uberwins')
            let endmode = WinceCommonDoWithoutUberwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, a:cmd, endmode], reselect)
        elseif a:dowithoutsubwins
            call s:Log.DBG('Running command without subwins')
            let endmode = WinceCommonDoWithoutSubwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, a:cmd, endmode], reselect)
        else
            call s:Log.DBG('Running command')
            let endmode = WinceStateWincmd(a:count, a:cmd, endmode)
        endif
    catch /.*/
        call s:Log.DBG('WinceDoCmdWithFlags failed: ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return endmode
    finally
        if a:relyonresolver
            " This call to the resolver from the user operations is
            " unfortunate, but necessary
            call WinceResolve()
            let endmode = {'mode':'n'}
        else
            call WinceCommonRecordAllDimensions()
        endif
        let endinfo = WinceCommonGetCursorPosition()
        if a:preservecursor
            call WinceCommonRestoreCursorPosition(info)
            let endmode = a:startmode
            call s:Log.VRB('Restored cursor position')
        elseif !a:relyonresolver && WinceModelIdByInfo(info.win) !=# WinceModelIdByInfo(endinfo.win)
            call WinceModelSetPreviousWinInfo(info.win)
            call WinceModelSetCurrentWinInfo(endinfo.win)
        endif
    endtry
    call s:RunPostUserOpCallbacks()
    return endmode
endfunction

" Navigation

" Movement between different categories of windows is restricted and sometimes
" requires afterimaging and deafterimaging
function! s:GoUberwinToUberwin(dstgrouptypename, dsttypename, startmode, suppresserror)
    try
        call WinceModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.DBG('GoUberwinToUberwin failed: ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.DBG('GoUberwinToUberwin ', a:dstgrouptypename, ':', a:dsttypename)
    if WinceModelUberwinGroupIsHidden(a:dstgrouptypename)
        call WinceShowUberwinGroup(a:dstgrouptypename, a:suppresserror)
        call s:Log.INF('Showing uberwin group ', a:dstgrouptypename, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
    endif
    let winid = WinceModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call s:Log.VRB('Destination winid is ', winid)
    return WinceStateMoveCursorToWinidAndUpdateMode(winid, a:startmode)
endfunction

function! s:GoUberwinToSupwin(dstsupwinid, startmode)
    call s:Log.DBG('GoUberwinToSupwin ', a:dstsupwinid, ' ', a:startmode)
    let endmode = WinceStateMoveCursorToWinidAndUpdateMode(a:dstsupwinid, a:startmode)
    let cur = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', cur)
    call s:Log.VRB('Deafterimaging subwins of destination supwin ', a:dstsupwinid)
    call WinceCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinceCommonRestoreCursorPosition(cur)
    call s:Log.VRB('Restored cursor position')
    return endmode
endfunction

function! s:GoSupwinToUberwin(srcsupwinid, dstgrouptypename, dsttypename, startmode, suppresserror)
    try
        call WinceModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.DBG('GoSupwinToUberwin failed: ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.DBG('GoSupwinToUberwin ', a:srcsupwinid, ', ', a:dstgrouptypename, ':', a:dsttypename)
    if WinceModelUberwinGroupIsHidden(a:dstgrouptypename)
        call s:Log.INF('Showing uberwin group ', a:dstgrouptypename, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
        call WinceShowUberwinGroup(a:dstgrouptypename, a:suppresserror)
    endif
    call s:Log.VRB('Afterimaging subwins of source supwin ', a:srcsupwinid)
    call WinceCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    let winid = WinceModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call s:Log.VRB('Destination winid is ', winid)
    " This is done so that WinceStateMoveCursorToWinidAndUpdateMode can start
    " in (and therefore restore the mode to) the correct window
    call WinceStateMoveCursorToWinidSilently(a:srcsupwinid)
    return WinceStateMoveCursorToWinidAndUpdateMode(winid, a:startmode)
endfunction

function! s:GoSupwinToSupwin(srcsupwinid, dstsupwinid, startmode)
    call s:Log.DBG('GoSupwinToSupwin ', a:srcsupwinid, ', ', a:dstsupwinid)
    call s:Log.VRB('Afterimaging subwins of soruce supwin ',a:srcsupwinid)
    call WinceCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    " This is done so that WinceStateMoveCursorToWinidAndUpdateMode can start
    " in (and therefore restore the mode to) the correct window
    call WinceStateMoveCursorToWinidSilently(a:srcsupwinid)
    let endmode = WinceStateMoveCursorToWinidAndUpdateMode(a:dstsupwinid, a:startmode)
    let cur = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', cur)
    call s:Log.VRB('Deafterimaging subwins of destination supwin ', a:dstsupwinid)
    " Don't update the mode here
    call WinceCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinceCommonRestoreCursorPosition(cur)
    call s:Log.VRB('Restored cursor position')
    return endmode
endfunction

function! s:GoSupwinToSubwin(srcsupwinid, dstgrouptypename, dsttypename, startmode, suppresserror)
    try
        call WinceModelAssertSubwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.DBG('GoSupwinToSubwin failed: ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.DBG('GoSupwinToSupwin ', a:srcsupwinid, ':', a:dstgrouptypename, ':', a:dsttypename)

    if WinceModelSubwinGroupIsHidden(a:srcsupwinid, a:dstgrouptypename)
        call s:Log.INF('Showing subwin group ', a:srcsupwinid, ':', a:dstgrouptypename, ' so that the cursor can be moved to its subwin ', a:dsttypename)
        call WinceShowSubwinGroup(a:srcsupwinid, a:dstgrouptypename, a:suppresserror)
    endif
    call s:Log.VRB('Afterimaging subwins of source supwin ', a:srcsupwinid, ' except destination subwin group ', a:dstgrouptypename)
    call WinceCommonAfterimageSubwinsBySupwinExceptOne(a:srcsupwinid, a:dstgrouptypename)
    let winid = WinceModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call s:Log.VRB('Destination winid is ', winid)
    " This is done so that WinceStateMoveCursorToWinidAndUpdateMode can start
    " in (and therefore restore the mode to) the correct window
    call WinceStateMoveCursorToWinidSilently(a:srcsupwinid)
    return WinceStateMoveCursorToWinidAndUpdateMode(winid, a:startmode)
endfunction

function! s:GoSubwinToSupwin(srcsupwinid, startmode)
    call s:Log.DBG('GoSubwinToSupwin ', a:srcsupwinid)
    let endmode = WinceStateMoveCursorToWinidAndUpdateMode(a:srcsupwinid, a:startmode)
    let cur = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', cur)
    call s:Log.VRB('Deafterimaging subwins of source supwin ', a:srcsupwinid)
    call WinceCommonDeafterimageSubwinsBySupwin(a:srcsupwinid)
    call WinceCommonRestoreCursorPosition(cur)
    call s:Log.VRB('Restored cursor position')
    return endmode
endfunction
function! s:GoSubwinToSubwin(srcsupwinid, srcgrouptypename, dsttypename, startmode, suppresserror)
    call s:Log.DBG('GoSubwinToSubwin ', a:srcsupwinid, ':', a:srcgrouptypename, ':', a:dsttypename)
    let winid = WinceModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:srcgrouptypename,
   \    'typename': a:dsttypename
   \})
    call s:Log.VRB('Destination winid is ', winid)
    return WinceStateMoveCursorToWinidAndUpdateMode(winid, a:startmode)
endfunction

" Move the cursor to a given uberwin
function! WinceGotoUberwin(dstgrouptype, dsttypename, startmode, suppresserror)
    try
        call WinceModelAssertUberwinTypeExists(a:dstgrouptype, a:dsttypename)
        call WinceModelAssertUberwinGroupExists(a:dstgrouptype)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.WRN('Cannot go to uberwin ', a:dstgrouptype, ':', a:dsttypename, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry

    call s:Log.INF('WinceGotoUberwin ', a:dstgrouptype, ':', a:dsttypename, ' ', a:startmode)

    if WinceModelUberwinGroupIsHidden(a:dstgrouptype)
        call s:Log.INF('Showing uberwin group ', a:dstgrouptype, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
        call WinceShowUberwinGroup(a:dstgrouptype, a:suppresserror)
    endif

    let cur = WinceCommonGetCursorPosition()
    call WinceModelSetPreviousWinInfo(cur.win)
    call s:Log.VRB('Previous window set to ', cur.win)
    let endmode = a:startmode
    
    " Moving from subwin to uberwin must be done via supwin
    if cur.win.category ==# 'subwin'
        call s:Log.DBG('Moving to supwin first')
        let endmode = s:GoSubwinToSupwin(cur.win.supwin, endmode)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'supwin'
       let endmode = s:GoSupwinToUberwin(cur.win.id, a:dstgrouptype, a:dsttypename, endmode, a:suppresserror)
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return endmode
    endif

    if cur.win.category ==# 'uberwin'
        let endmode = s:GoUberwinToUberwin(a:dstgrouptype, a:dsttypename, endmode, a:suppresserror)
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return endmode
    endif

    throw 'Cursor window is neither subwin nor supwin nor uberwin'
endfunction

" Move the cursor to a given supwin
function! WinceGotoSupwin(dstwinid, startmode)
    try
        let dstsupwinid = WinceModelSupwinIdBySupwinOrSubwinId(a:dstwinid)
    catch /.*/
        call s:Log.WRN('Cannot go to supwin ', a:dstwinid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return a:startmode
    endtry

    call s:Log.INF('WinceGotoSupwin ', a:dstwinid, ' ', a:startmode)

    let cur = WinceCommonGetCursorPosition()
    call s:Log.VRB('Previous window set to ', cur.win)
    call WinceModelSetPreviousWinInfo(cur.win)

    let endmode = a:startmode

    if cur.win.category ==# 'subwin'
        call s:Log.DBG('Moving to supwin first')
        let endmode = s:GoSubwinToSupwin(cur.win.supwin, endmode)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        let endmode = s:GoUberwinToSupwin(dstsupwinid, endmode)
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return endmode
    endif

    if cur.win.category ==# 'supwin'
        let endmode = a:startmode
        if cur.win.id != dstsupwinid
            let endmode = s:GoSupwinToSupwin(cur.win.id, dstsupwinid, endmode)
        endif
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return endmode
    endif

    return endmode
endfunction

" Move the cursor to a given subwin
function! WinceGotoSubwin(dstwinid, dstgrouptypename, dsttypename, startmode, suppresserror)
    try
        let dstsupwinid = WinceModelSupwinIdBySupwinOrSubwinId(a:dstwinid)
        call WinceModelAssertSubwinGroupExists(dstsupwinid, a:dstgrouptypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call s:Log.WRN('Cannot go to subwin ', a:dstgrouptypename, ':', a:dsttypename, ' of supwin ', a:dstwinid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry
    
    call s:Log.INF('WinceGotoSubwin ', a:dstwinid, ':', a:dstgrouptypename, ':', a:dsttypename, ' ', a:startmode)

    if WinceModelSubwinGroupIsHidden(dstsupwinid, a:dstgrouptypename)
        call s:Log.INF('Showing subwin group ', dstsupwinid, ':', a:dstgrouptypename, ' so that the cursor can be moved to its subwin ', a:dsttypename)
        call WinceShowSubwinGroup(dstsupwinid, a:dstgrouptypename, a:suppresserror)
    endif

    let cur = WinceCommonGetCursorPosition()
    call WinceModelSetPreviousWinInfo(cur.win)
    call s:Log.VRB('Previous window set to ', cur.win)

    let endmode = a:startmode

    if cur.win.category ==# 'subwin'
        if cur.win.supwin ==# dstsupwinid && cur.win.grouptype ==# a:dstgrouptypename
           let endmode =  s:GoSubwinToSubwin(cur.win.supwin, cur.win.grouptype, a:dsttypename, endmode, a:suppresserror)
            call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
            call s:RunPostUserOpCallbacks()
            return endmode
        endif

        call s:Log.DBG('Moving to supwin first')
        let endmode = s:GoSubwinToSupwin(cur.win.supwin, endmode)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        let endmode = s:GoUberwinToSupwin(dstsupwinid, endmode)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category !=# 'supwin'
        throw 'Cursor should be in a supwin now'
    endif

    if cur.win.id !=# dstsupwinid
        let endmode = s:GoSupwinToSupwin(cur.win.id, dstsupwinid, endmode)
        let cur = WinceCommonGetCursorPosition()
    endif

    let endmode = s:GoSupwinToSubwin(cur.win.id, a:dstgrouptypename, a:dsttypename, endmode, a:suppresserror)
    call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
    call s:RunPostUserOpCallbacks()

    return endmode
endfunction

function! WinceAddOrShowUberwinGroup(grouptypename)
    call s:Log.INF('WinAddOrShowUberwin ', a:grouptypename)
    if !WinceModelUberwinGroupExists(a:grouptypename)
        call WinceAddUberwinGroup(a:grouptypename, 0, 1)
    else
        call WinceShowUberwinGroup(a:grouptypename, 1)
    endif
endfunction

function! WinceAddOrShowSubwinGroup(supwinid, grouptypename)
    call s:Log.INF('WinAddOrShowSubwin ', a:supwinid, ':', a:grouptypename)
    if !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call WinceAddSubwinGroup(a:supwinid, a:grouptypename, 0, 1)
    else
        call WinceShowSubwinGroup(a:supwinid, a:grouptypename, 1)
    endif
endfunction

function! WinceAddOrGotoUberwin(grouptypename, typename, startmode)
    call s:Log.INF('WinceAddOrGotoUberwin ', a:grouptypename, ':', a:typename, ' ', a:startmode)
    if !WinceModelUberwinGroupExists(a:grouptypename)
        call WinceAddUberwinGroup(a:grouptypename, 0, 1)
    endif
    return WinceGotoUberwin(a:grouptypename, a:typename, a:startmode, 1)
endfunction

function! WinceAddOrGotoSubwin(supwinid, grouptypename, typename, startmode)
    call s:Log.INF('WinceAddOrGotoSubwin ', a:supwinid, ':', a:grouptypename, ':', a:typename, ' ', a:startmode)
    if !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call WinceAddSubwinGroup(a:supwinid, a:grouptypename, 0, 1)
    endif
    call WinceGotoSubwin(a:supwinid, a:grouptypename, a:typename, a:startmode, 1)
endfunction

function! s:GotoByInfo(info, startmode)
    call s:Log.DBG('GotoByInfo ', a:info)
    if a:info.category ==# 'uberwin'
        return WinceGotoUberwin(a:info.grouptype, a:info.typename, a:startmode, 0)
    endif
    if a:info.category ==# 'supwin'
        return WinceGotoSupwin(a:info.id, a:startmode)
    endif
    if a:info.category ==# 'subwin'
        return WinceGotoSubwin(a:info.supwin, a:info.grouptype, a:info.typename, a:startmode, 0)
    endif
    throw 'Cannot go to window with category ' . a:info.category
endfunction

function! WinceGotoPrevious(count, startmode)
    call s:Log.INF('WinceGotoPrevious ', a:count, ' ', a:startmode)
    if a:count !=# 0 && a:count % 2 ==# 0
        call s:Log.DBG('Count is even. Doing nothing')
        return
    endif
    let dst = WinceModelPreviousWinInfo()
    if !WinceModelIdByInfo(dst)
        call s:Log.DBG('Previous window does not exist in model. Doing nothing.')
        return
    endif
    
    let src = WinceCommonGetCursorPosition().win

    call WinceModelSetPreviousWinInfo(src)
    let endmode = s:GotoByInfo(dst, a:startmode)
    call WinceModelSetCurrentWinInfo(dst)

    call s:Log.VRB('Previous window set to ', src)
    call s:RunPostUserOpCallbacks()
    return endmode
endfunction

function! s:GoInDirection(count, direction, startmode)
    call s:Log.DBG('GoInDirection ', a:count, ', ', a:direction, ' ', a:startmode)
    if type(a:count) ==# v:t_string && empty(a:count)
        call s:Log.DBG('Defaulting count to 1')
        let thecount = 1
    else
        let thecount = a:count
    endif
    let endmode = a:startmode
    for iter in range(thecount)
        call s:Log.DBG('Iteration ', iter)
        let srcwinid = WinceStateGetCursorWinId()
        let srcinfo = WinceModelInfoById(srcwinid)
        call s:Log.DBG('Source window is ', srcinfo)
        let srcsupwin = -1
        if srcinfo.category ==# 'subwin'
            let srcsupwin = srcinfo.supwin
        endif
        
        let curwinid = srcwinid
        let prvwinid = 0
        let dstwinid = 0
        while 1
            let prvwinid = curwinid
            call s:Log.VRB('Silently moving cursor in direction ', a:direction)
            call WinceStateSilentWincmd(1, a:direction, 0)

            let curwinid = WinceStateGetCursorWinId()
            let curwininfo = WinceModelInfoById(curwinid)
            call s:Log.VRB('Landed in ', curwininfo)
 
            if curwininfo.category ==# 'supwin'
                call s:Log.DBG('Found supwin ', curwinid)
                let dstwinid = curwinid
                break
            endif
            if curwininfo.category ==# 'subwin' && curwininfo.supwin !=# srcwinid &&
           \   curwininfo.supwin !=# srcsupwin
                call s:Log.DBG('Found supwin ', curwininfo.supwin, ' by its subwin ', curwininfo.grouptype, ':', curwininfo.typename)
                let dstwinid = curwininfo.supwin
                break
            endif
            if curwinid == prvwinid
                call s:Log.VRB('Did not move from last step')
                break
            endif
        endwhile

        call s:Log.VRB('Selected destination supwin ', dstwinid, '. Silently returning to source window')
        call WinceStateMoveCursorToWinidSilently(srcwinid)
        if dstwinid
            call s:Log.VRB('Moving to destination supwin ', dstwinid)
            let endmode = WinceGotoSupwin(dstwinid, endmode)
        endif
    endfor
    return endmode
endfunction

" Move the cursor to the supwin on the left
function! WinceGoLeft(count, startmode)
    call s:Log.INF('WinceGoLeft ', a:count, ' ', a:startmode)
    return s:GoInDirection(a:count, 'h', a:startmode)
endfunction

" Move the cursor to the supwin below
function! WinceGoDown(count, startmode)
    call s:Log.INF('WinceGoDown ', a:count, ' ', a:startmode)
    return s:GoInDirection(a:count, 'j', a:startmode)
endfunction

" Move the cursor to the supwin above
function! WinceGoUp(count, startmode)
    call s:Log.INF('WinceGoUp ', a:count, ' ', a:startmode)
    return s:GoInDirection(a:count, 'k', a:startmode)
endfunction

" Move the cursor to the supwin to the right
function! WinceGoRight(count, startmode)
    call s:Log.INF('WinceGoRight ', a:count, ' ', a:startmode)
    return s:GoInDirection(a:count, 'l', a:startmode)
endfunction

" Close all windows except for either a given supwin, or the supwin of a given
" subwin
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. It is designed to rely on the resolver.
function! WinceOnly(count, startmode)
    call s:Log.INF('WinceOnly ', a:count, ' ', a:startmode)
    if type(a:count) ==# v:t_string && empty(a:count)
        let winid = WinceStateGetCursorWinId()
        let thecount = WinceStateGetWinnrByWinid(winid)
        call s:Log.DBG('Defaulting to current winnr ', thecount)
    else
        let thecount = a:count
    endif

    let winid = WinceStateGetWinidByWinnr(thecount)
    let info = WinceModelInfoById(winid)

    if info.category ==# 'uberwin'
        throw 'Cannot invoke WinceOnly from uberwin'
        return
    endif
    if info.category ==# 'subwin'
        call s:Log.DBG('shifting target to supwin')
        let info = WinceModelInfoById(info.supwin)
    endif

    call s:Log.VRB('target window ', info)

    call s:GotoByInfo(info)

    let endmode = WinceStateWincmd('', 'o', 1)
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
    return endmode
endfunction

" Exchange the current supwin (or current subwin's supwin) with a different
" supwin
function! WinceExchange(count, startmode)
    call s:Log.INF('WinceExchange ', a:count, ' ', a:startmode)
    let info = WinceCommonGetCursorPosition()

    if info.win.category ==# 'uberwin'
        throw 'Cannot invoke WinceExchange from uberwin'
        return
    endif

    call s:Log.INF('WinceExchange ', a:count)

    if info.win.category ==# 'subwin'
        call s:Log.DBG('Moving to supwin first')
        " Don't change the mode
        call WinceGotoSupwin(info.win.supwin, 0)
    endif

    let cmdinfo = WinceCommonGetCursorPosition()
    call s:Log.VRB('Running command from window ', cmdinfo)

    try
        let endmode =  WinceCommonDoWithoutUberwinsOrSubwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, 'x', a:startmode], 0)
        if info.win.category ==# 'subwin'
            call s:Log.VRB('Returning to subwin ', info.win)
            " Drop the mode
            let endmode = {'mode':'n'}
            call WinceGotoSubwin(WinceStateGetCursorWinId(), info.win.grouptype, info.win.typename, 0, 0)
        endif
    catch /.*/
        call s:Log.DBG('WinceExchange failed: ')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
    return endmode
endfunction

function! s:ResizeGivenNoSubwins(width, height)
    call s:Log.DBG('ResizeGivenNoSubwins ', ', [', a:width, ',', a:height, ']')

    let winid = WinceModelIdByInfo(WinceCommonGetCursorPosition().win)

    let preclosedim = WinceCommonPreserveDimensions()

    call s:Log.DBG('Closing all uberwins')
    let closeduberwingroups = WinceCommonCloseUberwinsWithHigherPriorityThan('')
    try
        call WinceStateMoveCursorToWinid(winid)

        let postclosedim = WinceCommonPreserveDimensions()
        let deltaw = postclosedim[winid].w - preclosedim[winid].w
        let deltah = postclosedim[winid].h - preclosedim[winid].h
        let finalw = a:width + deltaw
        let finalh = a:height + deltah
        let dow = 1
        let doh = 1
        call s:Log.DBG('Deltas: dw=', deltaw, ' dh=', deltah)

        if a:width ==# ''
            let finalw = ''
        endif
        if a:height ==# ''
            let finalh = ''
        endif
        if type(a:width) ==# v:t_number && a:width <# 0
            let dow = 0
        endif
        if type(a:height) ==# v:t_number && a:height <# 0
            let doh = 0
        endif

        if dow
            call s:Log.DBG('Resizing to width ', finalw)
            call WinceStateWincmd(finalw, '|', 0)
        endif
        if doh
            call s:Log.DBG('Resizing to height ', finalh)
            call WinceStateWincmd(finalh, '_', 0)
        endif

        let postresizedim = WinceCommonPreserveDimensions()
        for otherwinid in keys(postclosedim)
            if postresizedim[otherwinid].w !=# postclosedim[otherwinid].w ||
           \   postresizedim[otherwinid].h !=# postclosedim[otherwinid].h
               call remove(preclosedim, otherwinid)
            endif
        endfor
    finally
        call s:Log.DBG('Reopening all uberwins')
        call WinceCommonReopenUberwins(closeduberwingroups)
        call WinceCommonRestoreDimensions(preclosedim)
    endtry
endfunction

function! WinceResizeCurrentSupwin(width, height, startmode)
    let info = WinceCommonGetCursorPosition()

    if info.win.category ==# 'uberwin'
        throw 'Cannot resize an uberwin'
        return a:startmode
    endif

    call s:Log.INF('WinceResizeCurrentSupwin ', a:width, ' ', a:height)

    if info.win.category ==# 'subwin'
        call s:Log.DBG('Moving to supwin first')
        " Don't change the mode
        call WinceGotoSupwin(info.win.supwin, 0)
    endif

    let cmdinfo = WinceCommonGetCursorPosition()
    call s:Log.VRB('Running command from window ', cmdinfo)

    try
        call WinceCommonDoWithoutSubwins(cmdinfo.win, function('s:ResizeGivenNoSubwins'), [a:width, a:height], 1)
    finally
        call WinceCommonRestoreCursorPosition(info)
    endtry

    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
    return a:startmode
endfunction

function! WinceResizeVertical(count, startmode)
    call s:Log.INF('WinceResizeVertical ' . a:count)
    return WinceResizeCurrentSupwin(a:count, -1, a:startmode)
endfunction
function! WinceResizeHorizontal(count, startmode)
    call s:Log.INF('WinceResizeHorizontal ' . a:count)
    return WinceResizeCurrentSupwin(-1, a:count, a:startmode)
endfunction
function! WinceResizeHorizontalDefaultNop(count, startmode)
    call s:Log.INF('WinceResizeHorizontalDefaultNop ' . a:count)
    if a:count ==# ''
        return a:startmode
    endif
    return WinceResizeCurrentSupwin(-1, a:count, a:startmode)
endfunction

" Run a command in every supwin
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. Avoid passing commands that change the window state.
function! SupwinDo(command, range)
    call s:Log.INF('SupwinDo <', a:command, '>, ', a:range)
    let info = WinceCommonGetCursorPosition()
    call s:Log.VRB('Preserved cursor position ', info)
    try
        for supwinid in WinceModelSupwinIds()
            " Don't change the mode
            call WinceGotoSupwin(supwinid, 0)
            call s:Log.VRB('running command <', a:range, a:command, '>')
            execute a:range . a:command
        endfor
    finally
        call WinceCommonRestoreCursorPosition(info)
        call s:Log.VRB('Restored cursor position')
    endtry
endfunction
