" Wince User Operations
" See wince.vim

" Resolver callback registration

" Register a callback to run at the beginning of the resolver, when the
" resolver runs for the first time after entering a tab
function! WinceAddTabEnterPreResolveCallback(callback)
    call WinceModelAddTabEnterPreResolveCallback(a:callback)
    call EchomLog('wince-user', 'config', 'TabEnter pre-resolve callback: ', a:callback)
endfunction

" Register a callback to run partway through the resolver if new supwins have
" been added to the model
function! WinceAddSupwinsAddedResolveCallback(callback)
    call WinceModelAddSupwinsAddedResolveCallback(a:callback)
    call EchomLog('wince-user', 'config', 'Supwins-added pre-resolve callback: ', a:callback)
endfunction

" Register a callback to run after any successful user operation that changes
" the state or model and leaves them consistent
function! WinceAddPostUserOperationCallback(callback)
    call WinceModelAddPostUserOperationCallback(a:callback)
    call EchomLog('wince-user', 'config', 'Post-user operation callback: ', a:callback)
endfunction

function! s:RunPostUserOpCallbacks()
    call EchomLog('wince-user', 'debug', 'Running post-user-operation callbacks')
    for PostUserOpCallback in WinceModelPostUserOperationCallbacks()
        call EchomLog('wince-user', 'verbose', 'Running post-user-operation callback ', PostUserOpCallback)
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
    call EchomLog('wince-user', 'config', 'Uberwin group type: ', a:name)
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
    call EchomLog('wince-user', 'config', 'Subwin group type: ', a:name)
endfunction

" Uberwins

" For tabline generation
function! WinceUberwinFlagsStr()
    " Due to a bug in Vim, this function sometimes throws E315 in terminal
    " windows
    try
        call EchomLog('wince-user', 'debug', 'Retrieving Uberwin flags string')
        return WinceModelUberwinFlagsStr()
    catch /.*/
        call EchomLog('wince-user', 'debug', 'Failed to retrieve Uberwin flags: ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
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
        call EchomLog('wince-user', 'debug', 'WinceAddUberwinGroup cannot add uberwin group ', a:grouptypename, ': ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    " If we're adding the uberwin group as hidden, add it only to the model
    if a:hidden
        call EchomLog('wince-user', 'info', 'WinceAddUberwinGroup hidden ', a:grouptypename)
        call WinceModelAddUberwins(a:grouptypename, [], [])
        call s:RunPostUserOpCallbacks()
        return
    endif
    
    call EchomLog('wince-user', 'info', 'WinceAddUberwinGroup shown ', a:grouptypename)

    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try
        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let grouptype = g:wince_uberwingrouptype[a:grouptypename]
        let highertypes = WinceCommonCloseUberwinsWithHigherPriority(grouptype.priority)
        call EchomLog('wince-user', 'verbose', 'Closed higher-priority uberwin groups ', highertypes)
        try
            try
                let winids = WinceCommonDoWithoutSubwins(info.win, function('WinceCommonOpenUberwins'), [a:grouptypename, 1], 1)
                let dims = WinceStateGetWinDimensionsList(winids)
                call EchomLog('wince-user', 'verbose', 'Opened uberwin group ', a:grouptypename, ' in state with winids ', winids, ' and dimensions ', dims)
                call WinceModelAddUberwins(a:grouptypename, winids, dims)
                call EchomLog('wince-user', 'verbose', 'Added uberwin group ', a:grouptypename, ' to model')

            catch /.*/
                if !a:suppresserror
                    call EchomLog('wince-user', 'warning', 'WinceAddUberwinGroup failed to open ', a:grouptypename, ' uberwin group:')
                    call EchomLog('wince-user', 'debug', v:throwpoint)
                    call EchomLog('wince-user', 'warning', v:exception)
                endif
                call WinceAddUberwinGroup(a:grouptypename, 1, a:suppresserror)
                return
            endtry

        " Reopen the uberwins we closed
        finally
            call WinceCommonDoWithoutSubwins(info.win, function('WinceCommonReopenUberwins'), [highertypes, 1], 1)
            call EchomLog('wince-user', 'verbose', 'Reopened higher-priority uberwins groups')
        endtry
    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceRemoveUberwinGroup(grouptypename)
    call EchomLog('wince-user', 'info', 'WinceRemoveUberwinGroup ', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try
        let removed = 0
        if !WinceModelUberwinGroupIsHidden(a:grouptypename)
            call WinceCommonCloseUberwinsByGroupTypeName(a:grouptypename)
            call EchomLog('wince-user', 'verbose', 'Closed uberwin group ', a:grouptypename, ' in state')
            let removed = 1
        endif

        call WinceModelRemoveUberwins(a:grouptypename)
        call EchomLog('wince-user', 'verbose', 'Removed uberwin group ', a:grouptypename, ' from model')

        if removed
            " Closing an uberwin changes how much space is available to supwins
            " and their subwins. Close and reopen all subwins.
            call WinceCommonCloseAndReopenAllShownSubwins(info.win)
            call EchomLog('wince-user', 'verbose', 'Closed and reopened all shown subwins')
        endif

    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceHideUberwinGroup(grouptypename)
    try
        call WinceModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    catch /.*/
        call EchomLog('wince-user', 'debug', 'WinceHideUberwinGroup cannot hide uberwin group ', a:grouptypename, ': ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'info', 'WinceHideUberwinGroup ', a:grouptypename)

    let grouptype = g:wince_uberwingrouptype[a:grouptypename]

    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try
        call WinceCommonCloseUberwinsByGroupTypeName(a:grouptypename)
        call EchomLog('wince-user', 'verbose', 'Closed uberwin group ', a:grouptypename, ' in state')
        call WinceModelHideUberwins(a:grouptypename)
        call EchomLog('wince-user', 'verbose', 'Hid uberwin group ', a:grouptypename, ' in model')

        " Closing an uberwin changes how much space is available to supwins
        " and their subwins. Close and reopen all subwins.
        call WinceCommonCloseAndReopenAllShownSubwins(info.win)
        call EchomLog('wince-user', 'verbose', 'Closed and reopened all shown subwins')

    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
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
        call EchomLog('wince-user', 'debug', 'WinceShowUberwinGroup cannot show uberwin group ', a:grouptypename, ': ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'info', 'WinceShowUberwinGroup ', a:grouptypename)

    let grouptype = g:wince_uberwingrouptype[a:grouptypename]

    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try
        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinceCommonCloseUberwinsWithHigherPriority(grouptype.priority)
        call EchomLog('wince-user', 'verbose', 'Closed higher-priority uberwin groups ', highertypes)
        try
            try
                let winids = WinceCommonDoWithoutSubwins(info.win, function('WinceCommonOpenUberwins'), [a:grouptypename, 1], 1)
                let dims = WinceStateGetWinDimensionsList(winids)
                call EchomLog('wince-user', 'verbose', 'Opened uberwin group ', a:grouptypename, ' in state with winids ', winids, ' and dimensions ', dims)
                call WinceModelShowUberwins(a:grouptypename, winids, dims)
                call EchomLog('wince-user', 'verbose', 'Showed uberwin group ', a:grouptypename, ' in model')

            catch /.*/
                if a:suppresserror
                    return
                endif
                call EchomLog('wince-user', 'warning', 'WinceShowUberwinGroup failed to open ', a:grouptypename, ' uberwin group:')
                call EchomLog('wince-user', 'debug', v:throwpoint)
                call EchomLog('wince-user', 'warning', v:exception)
                return
            endtry
        " Reopen the uberwins we closed
        finally
            call WinceCommonDoWithoutSubwins(info.win, function('WinceCommonReopenUberwins'), [highertypes, 1], 1)
            call EchomLog('wince-user', 'verbose', 'Reopened higher-priority uberwins groups')
        endtry
    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Subwins

" For supwins' statusline generation
function! WinceSubwinFlags()
    let flagsstr = ''

    " Due to a bug in Vim, these functions sometimes throws E315 in terminal
    " windows
    try
        call EchomLog('wince-user', 'debug', 'Retrieving subwin flags string for current supwin')
        for grouptypename in WinceModelSubwinGroupTypeNames()
            call EchomLog('wince-user', 'verbose', 'Retrieving subwin flags string for subwin ', grouptypename, ' of current supwin')
            let flagsstr .= WinceCommonSubwinFlagStrByGroup(grouptypename)
        endfor
    catch /.*/
        call EchomLog('wince-user', 'debug', 'Failed to retrieve Subwin flags: ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return ''
    endtry

    call EchomLog('wince-user', 'verbose', 'Subwin flags string for current supwin: ', flagsstr)
    return flagsstr
endfunction

function! WinceAddSubwinGroup(supwinid, grouptypename, hidden, suppresserror)
    try
        call WinceModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call EchomLog('wince-user', 'debug', 'WinceAddSubwinGroup cannot add subwin group ', a:supwinid, ':', a:grouptypename, ': ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    " If we're adding the subwin group as hidden, add it only to the model
    if a:hidden
        call EchomLog('wince-user', 'info', 'WinceAddSubwinGroup hidden ', a:supwinid, ':', a:grouptypename)
        call WinceModelAddSubwins(a:supwinid, a:grouptypename, [], [])
        call s:RunPostUserOpCallbacks()
        return
    endif

    call EchomLog('wince-user', 'info', 'WinceAddSubwinGroup shown ', a:supwinid, ':', a:grouptypename)

    let grouptype = g:wince_subwingrouptype[a:grouptypename]
    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinceCommonCloseSubwinsWithHigherPriority(a:supwinid, grouptype.priority)
        call EchomLog('wince-user', 'verbose', 'Closed higher-priority subwin groups for supwin ', a:supwinid, ': ', highertypes)
        try
            try
                let winids = WinceCommonOpenSubwins(a:supwinid, a:grouptypename)
                let supwinnr = WinceStateGetWinnrByWinid(a:supwinid)
                let reldims = WinceStateGetWinRelativeDimensionsList(winids, supwinnr)
                call EchomLog('wince-user', 'verbose', 'Opened subwin group ', a:supwinid, ':', a:grouptypename, ' in state with winids ', winids, ' and relative dimensions ', reldims)
                call WinceModelAddSubwins(a:supwinid, a:grouptypename, winids, reldims)
                call EchomLog('wince-user', 'verbose', 'Added subwin group ', a:supwinid, ':', a:grouptypename, ' to model')
            catch /.*/
                if !a:suppresserror
                    call EchomLog('wince-user', 'warning', 'WinceAddSubwinGroup failed to open ', a:grouptypename, ' subwin group for supwin ', a:supwinid, ':')
                    call EchomLog('wince-user', 'debug', v:throwpoint)
                    call EchomLog('wince-user', 'warning', v:exception)
                endif
                call WinceAddSubwinGroup(a:supwinid, a:grouptypename, 1, a:suppresserror)
                return
            endtry

        " Reopen the subwins we closed
        finally
            call WinceCommonReopenSubwins(a:supwinid, highertypes)
            call EchomLog('wince-user', 'verbose', 'Reopened higher-priority subwin groups')
        endtry

    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceRemoveSubwinGroup(supwinid, grouptypename)
    try
        call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    catch /.*/
        call EchomLog('wince-user', 'debug', 'WinceRemoveSubwinGroup cannot remove subwin group ', a:supwinid, ':', a:grouptypename, ': ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'info', 'WinceRemoveSubwinGroup ', a:supwinid, ':', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try

        let grouptype = g:wince_subwingrouptype[a:grouptypename]

        let removed = 0
        if !WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
            call WinceCommonCloseSubwins(a:supwinid, a:grouptypename)
            call EchomLog('wince-user', 'verbose', 'Closed subwin group ', a:supwinid, ':', a:grouptypename, ' in state')
            let removed = 1
        endif

        call WinceModelRemoveSubwins(a:supwinid, a:grouptypename)
        call EchomLog('wince-user', 'verbose', 'Removed subwin group ', a:supwinid, ':', a:grouptypename, ' from model')

        if removed
            call WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
           \    a:supwinid,
           \    grouptype.priority
           \)
            call EchomLog('wince-user', 'verbose', 'Closed and reopened all shown subwins of supwin ', a:supwinid, ' with priority higher than ', a:grouptypename)
        endif

    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceHideSubwinGroup(winid, grouptypename)
    try
        let supwinid = WinceModelSupwinIdBySupwinOrSubwinId(a:winid)
        call WinceModelAssertSubwinGroupIsNotHidden(supwinid, a:grouptypename)
    catch /.*/
        call EchomLog('wince-user', 'debug', 'WinceHideSubwinGroup cannot hide subwin group ', a:winid, ':', a:grouptypename, ': ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'info', 'WinceHideSubwinGroup ', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try
        let grouptype = g:wince_subwingrouptype[a:grouptypename]

        call WinceCommonCloseSubwins(supwinid, a:grouptypename)
        call EchomLog('wince-user', 'verbose', 'Closed subwin group ', supwinid, ':', a:grouptypename, ' in state')
        call WinceModelHideSubwins(supwinid, a:grouptypename)
        call EchomLog('wince-user', 'verbose', 'Hid subwin group ', supwinid, ':', a:grouptypename, ' in model')
        call WinceCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
       \    supwinid,
       \    grouptype.priority
       \)
        call EchomLog('wince-user', 'verbose', 'Closed and reopened all shown subwins of supwin ', supwinid, ' with priority higher than ', a:grouptypename)

    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
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
        call EchomLog('wince-user', 'debug', 'WinceShowSubwinGroup cannot show subwin group ', a:srcid, ':', a:grouptypename, ': ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    let grouptype = g:wince_subwingrouptype[a:grouptypename]

    call EchomLog('wince-user', 'info', 'WinceShowSubwinGroup ', supwinid, ':', a:grouptypename)
    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try
        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinceCommonCloseSubwinsWithHigherPriority(supwinid, grouptype.priority)
        call EchomLog('wince-user', 'verbose', 'Closed higher-priority subwin groups for supwin ', supwinid, ': ', highertypes)
        try
            try
                let winids = WinceCommonOpenSubwins(supwinid, a:grouptypename)
                let supwinnr = WinceStateGetWinnrByWinid(supwinid)
                let reldims = WinceStateGetWinRelativeDimensionsList(winids, supwinnr)
                call EchomLog('wince-user', 'verbose', 'Opened subwin group ', supwinid, ':', a:grouptypename, ' in state with winids ', winids, ' and relative dimensions ', reldims)
                call WinceModelShowSubwins(supwinid, a:grouptypename, winids, reldims)
                call EchomLog('wince-user', 'verbose', 'Showed subwin group ', supwinid, ':', a:grouptypename, ' in model')

            catch /.*/
                if a:suppresserror
                    return
                endif
                call EchomLog('wince-user', 'warning', 'WinceShowSubwinGroup failed to open ', a:grouptypename, ' subwin group for supwin ', supwinid, ':')
                call EchomLog('wince-user', 'debug', v:throwpoint)
                call EchomLog('wince-user', 'warning', v:exception)
                return
            endtry

        " Reopen the subwins we closed
        finally
            call WinceCommonReopenSubwins(supwinid, highertypes)
            call EchomLog('wince-user', 'verbose', 'Reopened higher-priority subwin groups')
        endtry

    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
    endtry

    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Retrieve subwins and supwins' statuslines from the model
function! WinceNonDefaultStatusLine()
    call EchomLog('wince-user', 'debug', 'Retrieving non-default statusline for current window')
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
                          \ preservecursor,
                          \ ifuberwindonothing, ifsubwingotosupwin,
                          \ dowithoutuberwins, dowithoutsubwins,
                          \ preservesupdims, relyonresolver)
    call EchomLog('wince-user', 'info', 'WinceDoCmdWithFlags ' . a:cmd . ' ' . a:count . ' [' . a:preservecursor . ',' . a:ifuberwindonothing . ',' . a:ifsubwingotosupwin . ',' . a:dowithoutuberwins . ',' . a:dowithoutsubwins . ',' . ',' . a:preservesupdims . ',' . a:relyonresolver . ']')
    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)

    if info.win.category ==# 'uberwin' && a:ifuberwindonothing
        call EchomLog('wince-user', 'warning', 'Cannot run ', a:cmd, ' in uberwin')
        return
    endif

    if info.win.category ==# 'subwin' && a:ifsubwingotosupwin
        call EchomLog('wince-user', 'debug', 'Going from subwin to supwin')
        if a:preservecursor
            let mode = WinceStateRetrievePreservedMode()
        endif
        call WinceGotoSupwin(info.win.supwin)
        if a:preservecursor
            call WinceStateForcePreserveMode(mode)
        endif
    endif

    let cmdinfo = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Running command from window ', cmdinfo)

    let reselect = 1
    if a:relyonresolver
        let reselect = 0
    endif

    try
        if a:dowithoutuberwins && a:dowithoutsubwins
            call EchomLog('wince-user', 'debug', 'Running command without uberwins or subwins')
            call WinceCommonDoWithoutUberwinsOrSubwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, a:cmd, 1], reselect, a:preservesupdims)
        elseif a:dowithoutuberwins
            call EchomLog('wince-user', 'debug', 'Running command without uberwins')
            call WinceCommonDoWithoutUberwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, a:cmd, 1], reselect)
        elseif a:dowithoutsubwins
            call EchomLog('wince-user', 'debug', 'Running command without subwins')
            call WinceCommonDoWithoutSubwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, a:cmd, 1], reselect)
        else
            call EchomLog('wince-user', 'debug', 'Running command')
            call WinceStateWincmd(a:count, a:cmd, 1)
        endif
    catch /.*/
        call EchomLog('wince-user', 'debug', 'WinceDoCmdWithFlags failed: ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    finally
        if a:relyonresolver
            " This call to the resolver from the user operations is
            " unfortunate, but necessary
            call WinceResolve()
        else
            call WinceCommonRecordAllDimensions()
        endif
        let endinfo = WinceCommonGetCursorPosition()
        if a:preservecursor
            call WinceCommonRestoreCursorPosition(info)
            call EchomLog('wince-user', 'verbose', 'Restored cursor position')
        elseif !a:relyonresolver && WinceModelIdByInfo(info.win) !=# WinceModelIdByInfo(endinfo.win)
            call WinceModelSetPreviousWinInfo(info.win)
            call WinceModelSetCurrentWinInfo(endinfo.win)
        endif
    endtry
    call s:RunPostUserOpCallbacks()
endfunction

" Navigation

" Movement between different categories of windows is restricted and sometimes
" requires afterimaging and deafterimaging
function! s:GoUberwinToUberwin(dstgrouptypename, dsttypename, suppresserror)
    try
        call WinceModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call EchomLog('wince-user', 'debug', 'GoUberwinToUberwin failed: ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'debug', 'GoUberwinToUberwin ', a:dstgrouptypename, ':', a:dsttypename)
    if WinceModelUberwinGroupIsHidden(a:dstgrouptypename)
        call WinceShowUberwinGroup(a:dstgrouptypename, a:suppresserror)
        call EchomLog('wince-user', 'info', 'Showing uberwin group ', a:dstgrouptypename, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
    endif
    let winid = WinceModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('wince-user', 'verbose', 'Destination winid is ', winid)
    call WinceStateMoveCursorToWinidAndUpdateMode(winid)
endfunction

function! s:GoUberwinToSupwin(dstsupwinid)
    call EchomLog('wince-user', 'debug', 'GoUberwinToSupwin ', a:dstsupwinid)
    call WinceStateMoveCursorToWinidAndUpdateMode(a:dstsupwinid)
    let cur = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', cur)
        call EchomLog('wince-user', 'verbose', 'Deafterimaging subwins of destination supwin ', a:dstsupwinid)
        call WinceCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinceCommonRestoreCursorPosition(cur)
    call EchomLog('wince-user', 'verbose', 'Restored cursor position')
endfunction

function! s:GoSupwinToUberwin(srcsupwinid, dstgrouptypename, dsttypename, suppresserror)
    try
        call WinceModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call EchomLog('wince-user', 'debug', 'GoSupwinToUberwin failed: ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'debug', 'GoSupwinToUberwin ', a:srcsupwinid, ', ', a:dstgrouptypename, ':', a:dsttypename)
    if WinceModelUberwinGroupIsHidden(a:dstgrouptypename)
        call EchomLog('wince-user', 'info', 'Showing uberwin group ', a:dstgrouptypename, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
        call WinceShowUberwinGroup(a:dstgrouptypename, a:suppresserror)
    endif
    call EchomLog('wince-user', 'verbose', 'Afterimaging subwins of source supwin ', a:srcsupwinid)
    call WinceCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    let winid = WinceModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('wince-user', 'verbose', 'Destination winid is ', winid)
    call WinceStateMoveCursorToWinidAndUpdateMode(winid)
endfunction

function! s:GoSupwinToSupwin(srcsupwinid, dstsupwinid)
    call EchomLog('wince-user', 'debug', 'GoSupwinToSupwin ', a:srcsupwinid, ', ', a:dstsupwinid)
    call EchomLog('wince-user', 'verbose', 'Afterimaging subwins of soruce supwin ',a:srcsupwinid)
    call WinceCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    " This is done so that WinceStateMoveCursorToWinidAndUpdateMode will restore
    " the mode in the source supwin, and not in whatever the last subwin to be
    " afterimaged turns out to be
    call WinceStateMoveCursorToWinid(a:srcsupwinid)
    call WinceStateMoveCursorToWinidAndUpdateMode(a:dstsupwinid)
    let cur = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', cur)
        call EchomLog('wince-user', 'verbose', 'Deafterimaging subwins of destination supwin ', a:dstsupwinid)
        call WinceCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinceCommonRestoreCursorPosition(cur)
    call EchomLog('wince-user', 'verbose', 'Restored cursor position')
endfunction

function! s:GoSupwinToSubwin(srcsupwinid, dstgrouptypename, dsttypename, suppresserror)
    try
        call WinceModelAssertSubwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call EchomLog('wince-user', 'debug', 'GoSupwinToSubwin failed: ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'debug', 'GoSupwinToSupwin ', a:srcsupwinid, ':', a:dstgrouptypename, ':', a:dsttypename)

    if WinceModelSubwinGroupIsHidden(a:srcsupwinid, a:dstgrouptypename)
        call EchomLog('wince-user', 'info', 'Showing subwin group ', a:srcsupwinid, ':', a:dstgrouptypename, ' so that the cursor can be moved to its subwin ', a:dsttypename)
        call WinceShowSubwinGroup(a:srcsupwinid, a:dstgrouptypename, a:suppresserror)
    endif
    call EchomLog('wince-user', 'verbose', 'Afterimaging subwins of source supwin ', a:srcsupwinid, ' except destination subwin group ', a:dstgrouptypename)
    call WinceCommonAfterimageSubwinsBySupwinExceptOne(a:srcsupwinid, a:dstgrouptypename)
    let winid = WinceModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('wince-user', 'verbose', 'Destination winid is ', winid)
    call WinceStateMoveCursorToWinidAndUpdateMode(winid)
endfunction

function! s:GoSubwinToSupwin(srcsupwinid)
    call EchomLog('wince-user', 'debug', 'GoSubwinToSupwin ', a:srcsupwinid)
    call WinceStateMoveCursorToWinidAndUpdateMode(a:srcsupwinid)
    let cur = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', cur)
        call EchomLog('wince-user', 'verbose', 'Deafterimaging subwins of source supwin ', a:srcsupwinid)
        call WinceCommonDeafterimageSubwinsBySupwin(a:srcsupwinid)
    call WinceCommonRestoreCursorPosition(cur)
    call EchomLog('wince-user', 'verbose', 'Restored cursor position')
endfunction
function! s:GoSubwinToSubwin(srcsupwinid, srcgrouptypename, dsttypename, suppresserror)
    call EchomLog('wince-user', 'debug', 'GoSubwinToSubwin ', a:srcsupwinid, ':', a:srcgrouptypename, ':', a:dsttypename)
    let winid = WinceModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:srcgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('wince-user', 'verbose', 'Destination winid is ', winid)
    call WinceStateMoveCursorToWinidAndUpdateMode(winid)
endfunction

" Move the cursor to a given uberwin
function! WinceGotoUberwin(dstgrouptype, dsttypename, suppresserror)
    try
        call WinceModelAssertUberwinTypeExists(a:dstgrouptype, a:dsttypename)
        call WinceModelAssertUberwinGroupExists(a:dstgrouptype)
    catch /.*/
        if a:suppresserror
            return
        endif
        call EchomLog('wince-user', 'warning', 'Cannot go to uberwin ', a:dstgrouptype, ':', a:dsttypename, ':')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'info', 'WinceGotoUberwin ', a:dstgrouptype, ':', a:dsttypename)

    if WinceModelUberwinGroupIsHidden(a:dstgrouptype)
        call EchomLog('wince-user', 'info', 'Showing uberwin group ', a:dstgrouptype, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
        call WinceShowUberwinGroup(a:dstgrouptype, a:suppresserror)
    endif

    let cur = WinceCommonGetCursorPosition()
    call WinceModelSetPreviousWinInfo(cur.win)
    call EchomLog('wince-user', 'verbose', 'Previous window set to ', cur.win)
    
    " Moving from subwin to uberwin must be done via supwin
    if cur.win.category ==# 'subwin'
        call EchomLog('wince-user', 'debug', 'Moving to supwin first')
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'supwin'
        call s:GoSupwinToUberwin(cur.win.id, a:dstgrouptype, a:dsttypename, a:suppresserror)
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToUberwin(a:dstgrouptype, a:dsttypename, a:suppresserror)
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif

    throw 'Cursor window is neither subwin nor supwin nor uberwin'
endfunction

" Move the cursor to a given supwin
function! WinceGotoSupwin(dstwinid)
    try
        let dstsupwinid = WinceModelSupwinIdBySupwinOrSubwinId(a:dstwinid)
    catch /.*/
        call EchomLog('wince-user', 'warning', 'Cannot go to supwin ', a:dstwinid, ':')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('wince-user', 'info', 'WinceGotoSupwin ', a:dstwinid)

    let cur = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Previous window set to ', cur.win)
    call WinceModelSetPreviousWinInfo(cur.win)

    if cur.win.category ==# 'subwin'
        call EchomLog('wince-user', 'debug', 'Moving to supwin first')
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToSupwin(dstsupwinid)
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif

    if cur.win.category ==# 'supwin'
        if cur.win.id != dstsupwinid
            call s:GoSupwinToSupwin(cur.win.id,  dstsupwinid)
        endif
        call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif
endfunction

" Move the cursor to a given subwin
function! WinceGotoSubwin(dstwinid, dstgrouptypename, dsttypename, suppresserror)
    try
        let dstsupwinid = WinceModelSupwinIdBySupwinOrSubwinId(a:dstwinid)
        call WinceModelAssertSubwinTypeExists(a:dstgrouptypename, a:dsttypename)
        call WinceModelAssertSubwinGroupExists(dstsupwinid, a:dstgrouptypename)
    catch /.*/
        if a:suppresserror
            return
        endif
        call EchomLog('wince-user', 'warning', 'Cannot go to subwin ', a:dstgrouptypename, ':', a:dsttypename, ' of supwin ', a:dstwinid, ':')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry
    
    call EchomLog('wince-user', 'info', 'WinceGotoSubwin ', a:dstwinid, ':', a:dstgrouptypename, ':', a:dsttypename)

    if WinceModelSubwinGroupIsHidden(dstsupwinid, a:dstgrouptypename)
        call EchomLog('wince-user', 'info', 'Showing subwin group ', dstsupwinid, ':', a:dstgrouptypename, ' so that the cursor can be moved to its subwin ', a:dsttypename)
        call WinceShowSubwinGroup(dstsupwinid, a:dstgrouptypename, a:suppresserror)
    endif

    let cur = WinceCommonGetCursorPosition()
    call WinceModelSetPreviousWinInfo(cur.win)
    call EchomLog('wince-user', 'verbose', 'Previous window set to ', cur.win)

    if cur.win.category ==# 'subwin'
        if cur.win.supwin ==# dstsupwinid && cur.win.grouptype ==# a:dstgrouptypename
            call s:GoSubwinToSubwin(cur.win.supwin, cur.win.grouptype, a:dsttypename, a:suppresserror)
            call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
            call s:RunPostUserOpCallbacks()
            return
        endif

        call EchomLog('wince-user', 'debug', 'Moving to supwin first')
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToSupwin(dstsupwinid)
        let cur = WinceCommonGetCursorPosition()
    endif

    if cur.win.category !=# 'supwin'
        throw 'Cursor should be in a supwin now'
    endif

    if cur.win.id !=# dstsupwinid
        call s:GoSupwinToSupwin(cur.win.id, dstsupwinid)
        let cur = WinceCommonGetCursorPosition()
    endif

    call s:GoSupwinToSubwin(cur.win.id, a:dstgrouptypename, a:dsttypename, a:suppresserror)
    call WinceModelSetCurrentWinInfo(WinceCommonGetCursorPosition().win)
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceAddOrShowUberwinGroup(grouptypename)
    call EchomLog('wince-user', 'info', 'WinAddOrShowUberwin ', a:grouptypename)
    if !WinceModelUberwinGroupExists(a:grouptypename)
        call WinceAddUberwinGroup(a:grouptypename, 0, 1)
    else
        call WinceShowUberwinGroup(a:grouptypename, 1)
    endif
endfunction

function! WinceAddOrShowSubwinGroup(supwinid, grouptypename)
    call EchomLog('wince-user', 'info', 'WinAddOrShowSubwin ', a:supwinid, ':', a:grouptypename)
    if !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call WinceAddSubwinGroup(a:supwinid, a:grouptypename, 0, 1)
    else
        call WinceShowSubwinGroup(a:supwinid, a:grouptypename, 1)
    endif
endfunction

function! WinceAddOrGotoUberwin(grouptypename, typename)
    call EchomLog('wince-user', 'info', 'WinceAddOrGotoUberwin ', a:grouptypename, ':', a:typename)
    if !WinceModelUberwinGroupExists(a:grouptypename)
        call WinceAddUberwinGroup(a:grouptypename, 0, 1)
    endif
    call WinceGotoUberwin(a:grouptypename, a:typename, 1)
endfunction

function! WinceAddOrGotoSubwin(supwinid, grouptypename, typename)
    call EchomLog('wince-user', 'info', 'WinceAddOrGotoSubwin ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    if !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call WinceAddSubwinGroup(a:supwinid, a:grouptypename, 0, 1)
    endif
    call WinceGotoSubwin(a:supwinid, a:grouptypename, a:typename, 1)
endfunction

function! s:GotoByInfo(info)
    call EchomLog('wince-user', 'debug', 'GotoByInfo ', a:info)
    if a:info.category ==# 'uberwin'
        call WinceGotoUberwin(a:info.grouptype, a:info.typename, 0)
        return
    endif
    if a:info.category ==# 'supwin'
        call WinceGotoSupwin(a:info.id)
        return
    endif
    if a:info.category ==# 'subwin'
        call WinceGotoSubwin(a:info.supwin, a:info.grouptype, a:info.typename, 0)
        return
    endif
    throw 'Cannot go to window with category ' . a:info.category
endfunction

function! WinceGotoPrevious(count)
    call EchomLog('wince-user', 'info', 'WinceGotoPrevious ', a:count)
    if a:count !=# 0 && a:count % 2 ==# 0
        call EchomLog('wince-user', 'debug', 'Count is even. Doing nothing')
        return
    endif
    let dst = WinceModelPreviousWinInfo()
    if !WinceModelIdByInfo(dst)
        call EchomLog('wince-user', 'debug', 'Previous window does not exist in model. Doing nothing.')
        return
    endif
    
    let src = WinceCommonGetCursorPosition().win

    call WinceModelSetPreviousWinInfo(src)
    call s:GotoByInfo(dst)
    call WinceModelSetCurrentWinInfo(dst)

    call EchomLog('wince-user', 'verbose', 'Previous window set to ', src)
    call s:RunPostUserOpCallbacks()
endfunction

function! s:GoInDirection(count, direction)
    call EchomLog('wince-user', 'debug', 'GoInDirection ', a:count, ', ', a:direction)
    if type(a:count) ==# v:t_string && empty(a:count)
        call EchomLog('wince-user', 'debug', 'Defaulting count to 1')
        let thecount = 1
    else
        let thecount = a:count
    endif
    for iter in range(thecount)
        call EchomLog('wince-user', 'debug', 'Iteration ', iter)
        let srcwinid = WinceStateGetCursorWinId()
        let srcinfo = WinceModelInfoById(srcwinid)
        call EchomLog('wince-user', 'debug', 'Source window is ', srcinfo)
        let srcsupwin = -1
        if srcinfo.category ==# 'subwin'
            let srcsupwin = srcinfo.supwin
        endif
        
        let curwinid = srcwinid
        let prvwinid = 0
        let dstwinid = 0
        while 1
            let prvwinid = curwinid
            call EchomLog('wince-user', 'verbose', 'Silently moving cursor in direction ', a:direction)
            call WinceStateSilentWincmd(1, a:direction, 0)

            let curwinid = WinceStateGetCursorWinId()
            let curwininfo = WinceModelInfoById(curwinid)
            call EchomLog('wince-user', 'verbose', 'Landed in ', curwininfo)
 
            if curwininfo.category ==# 'supwin'
                call EchomLog('wince-user', 'debug', 'Found supwin ', curwinid)
                let dstwinid = curwinid
                break
            endif
            if curwininfo.category ==# 'subwin' && curwininfo.supwin !=# srcwinid &&
           \   curwininfo.supwin !=# srcsupwin
                call EchomLog('wince-user', 'debug', 'Found supwin ', curwininfo.supwin, ' by its subwin ', curwininfo.grouptype, ':', curwininfo.typename)
                let dstwinid = curwininfo.supwin
                break
            endif
            if curwinid == prvwinid
                call EchomLog('wince-user', 'verbose', 'Did not move from last step')
                break
            endif
        endwhile

        call EchomLog('wince-user', 'verbose', 'Selected destination supwin ', dstwinid, '. Silently returning to source window')
        call WinceStateMoveCursorToWinidSilently(srcwinid)
        if dstwinid
            call EchomLog('wince-user', 'verbose', 'Moving to destination supwin ', dstwinid)
            call WinceGotoSupwin(dstwinid)
        endif
    endfor
endfunction

" Move the cursor to the supwin on the left
function! WinceGoLeft(count)
    call EchomLog('wince-user', 'info', 'WinceGoLeft ', a:count)
    call s:GoInDirection(a:count, 'h')
endfunction

" Move the cursor to the supwin below
function! WinceGoDown(count)
    call EchomLog('wince-user', 'info', 'WinceGoDown ', a:count)
    call s:GoInDirection(a:count, 'j')
endfunction

" Move the cursor to the supwin above
function! WinceGoUp(count)
    call EchomLog('wince-user', 'info', 'WinceGoUp ', a:count)
    call s:GoInDirection(a:count, 'k')
endfunction

" Move the cursor to the supwin to the right
function! WinceGoRight(count)
    call EchomLog('wince-user', 'info', 'WinceGoRight ', a:count)
    call s:GoInDirection(a:count, 'l')
endfunction

" Close all windows except for either a given supwin, or the supwin of a given
" subwin
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. It is designed to rely on the resolver.
function! WinceOnly(count)
    call EchomLog('wince-user', 'info', 'WinceOnly ', a:count)
    if type(a:count) ==# v:t_string && empty(a:count)
        let winid = WinceStateGetCursorWinId()
        let thecount = WinceStateGetWinnrByWinid(winid)
        call EchomLog('wince-user', 'debug', 'Defaulting to current winnr ', thecount)
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
        call EchomLog('wince-user', 'debug', 'shifting target to supwin')
        let info = WinceModelInfoById(info.supwin)
    endif

    call EchomLog('wince-user', 'verbose', 'target window ', info)

    call s:GotoByInfo(info)

    call WinceStateWincmd('', 'o', 1)
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Exchange the current supwin (or current subwin's supwin) with a different
" supwin
function! WinceExchange(count)
    let info = WinceCommonGetCursorPosition()

    if info.win.category ==# 'uberwin'
        throw 'Cannot invoke WinceExchange from uberwin'
        return
    endif

    call EchomLog('wince-user', 'info', 'WinceExchange ', a:count)

    if info.win.category ==# 'subwin'
        call EchomLog('wince-user', 'debug', 'Moving to supwin first')
        call WinceGotoSupwin(info.win.supwin)
    endif

    let cmdinfo = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Running command from window ', cmdinfo)

    try
        call WinceCommonDoWithoutUberwinsOrSubwins(cmdinfo.win, function('WinceStateWincmd'), [a:count, 'x', 1], 1, 0)
        if info.win.category ==# 'subwin'
            call EchomLog('wince-user', 'verbose', 'Returning to subwin ' info.win)
            call WinceGotoSubwin(WinceStateGetCursorWinId(), info.win.grouptype, info.win.typename, 0)
        endif
    catch /.*/
        call EchomLog('wince-user', 'debug', 'WinceExchange failed: ')
        call EchomLog('wince-user', 'debug', v:throwpoint)
        call EchomLog('wince-user', 'warning', v:exception)
        return
    endtry
    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! s:ResizeGivenNoSubwins(width, height)
    call EchomLog('wince-user', 'debug', 'ResizeGivenNoSubwins ', ', [', a:width, ',', a:height, ']')

    let winid = WinceModelIdByInfo(WinceCommonGetCursorPosition().win)

    let preclosedim = WinceStateGetWinDimensions(winid)

    call EchomLog('wince-user', 'debug', 'Closing all uberwins')
    let closeduberwingroups = WinceCommonCloseUberwinsWithHigherPriority(-1)
    try
        call WinceStateMoveCursorToWinid(winid)

        let postclosedim = WinceStateGetWinDimensions(winid)
        let deltaw = postclosedim.w - preclosedim.w
        let deltah = postclosedim.h - preclosedim.h
        let finalw = a:width + deltaw
        let finalh = a:height + deltah
        let dow = 1
        let doh = 1
        call EchomLog('wince-user', 'debug', 'Deltas: dw=', deltaw, ' dh=', deltah)

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
            call EchomLog('wince-user', 'debug', 'Resizing to width ', finalw)
            call WinceStateWincmd(finalw, '|', 0)
        endif
        if doh
            call EchomLog('wince-user', 'debug', 'Resizing to height ', finalh)
            call WinceStateWincmd(finalh, '_', 0)
        endif
    finally
        call EchomLog('wince-user', 'debug', 'Reopening all uberwins')
        call WinceCommonReopenUberwins(closeduberwingroups, 1)
    endtry
endfunction

function! WinceResizeCurrentSupwin(width, height)
    let info = WinceCommonGetCursorPosition()

    if info.win.category ==# 'uberwin'
        throw 'Cannot resize an uberwin'
        return
    endif

    call EchomLog('wince-user', 'info', 'WinceResizeCurrentSupwin ', a:width, ' ', a:height)

    if info.win.category ==# 'subwin'
        call EchomLog('wince-user', 'debug', 'Moving to supwin first')
        let mode = WinceStateRetrievePreservedMode()
        call WinceGotoSupwin(info.win.supwin)
        call WinceStateForcePreserveMode(mode)
    endif

    let cmdinfo = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Running command from window ', cmdinfo)

    try
        call WinceCommonDoWithoutSubwins(cmdinfo.win, function('s:ResizeGivenNoSubwins'), [a:width, a:height], 1)
    finally
        call WinceCommonRestoreCursorPosition(info)
    endtry

    call WinceCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinceResizeVertical(count)
    call EchomLog('wince-user', 'info', 'WinceResizeVertical ' . a:count)
    call WinceResizeCurrentSupwin(a:count, -1)
endfunction
function! WinceResizeHorizontal(count)
    call EchomLog('wince-user', 'info', 'WinceResizeHorizontal ' . a:count)
    call WinceResizeCurrentSupwin(-1, a:count)
endfunction
function! WinceResizeHorizontalDefaultNop(count)
    call EchomLog('wince-user', 'info', 'WinceResizeHorizontalDefaultNop ' . a:count)
    if a:count ==# ''
        return
    endif
    call WinceResizeCurrentSupwin(-1, a:count)
endfunction

" Run a command in every supwin
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. Avoid passing commands that change the window state.
function! SupwinDo(command, range)
    call EchomLog('wince-user', 'info', 'SupwinDo <', a:command, '>, ', a:range)
    let info = WinceCommonGetCursorPosition()
    call EchomLog('wince-user', 'verbose', 'Preserved cursor position ', info)
    try
        for supwinid in WinceModelSupwinIds()
            call WinceGotoSupwin(supwinid)
            call EchomLog('wince-user', 'verbose', 'running command <', a:range, a:command, '>')
            execute a:range . a:command
        endfor
    finally
        call WinceCommonRestoreCursorPosition(info)
        call EchomLog('wince-user', 'verbose', 'Restored cursor position')
    endtry
endfunction
