" Window user operations
" See window.vim

" Resolver callback registration

" Register a callback to run at the beginning of the resolver, when the
" resolver runs for the first time after entering a tab
function! WinAddTabEnterPreResolveCallback(callback)
    call WinModelAddTabEnterPreResolveCallback(a:callback)
    call EchomLog('window-user', 'config', 'TabEnter pre-resolve callback: ', a:callback)
endfunction

" Register a callback to run partway through the resolver if new supwins have
" been added to the model
function! WinAddSupwinsAddedResolveCallback(callback)
    call WinModelAddSupwinsAddedResolveCallback(a:callback)
    call EchomLog('window-user', 'config', 'Supwins-added pre-resolve callback: ', a:callback)
endfunction

" Register a callback to run after any successful user operation that changes
" the state or model and leaves them consistent
function! WinAddPostUserOperationCallback(callback)
    call WinModelAddPostUserOperationCallback(a:callback)
    call EchomLog('window-user', 'config', 'Post-user operation callback: ', a:callback)
endfunction

function! s:RunPostUserOpCallbacks()
    call EchomLog('window-user', 'debug', 'Running post-user-operation callbacks')
    for PostUserOpCallback in WinModelPostUserOperationCallbacks()
        call EchomLog('window-user', 'verbose', 'Running post-user-operation callback ', PostUserOpCallback)
        call PostUserOpCallback()
    endfor
endfunction

" Group Types

" Add an uberwin group type. One uberwin group type represents one or more uberwins
" which are opened together
" one window
" name:        The name of the uberwin group type
" typenames:   The names of the uberwin types in the group
" statuslines: The statusline strings of the uberwin types in the group
" flag:        Flag to insert into the tabline when the uberwins are shown
" hidflag:     Flag to insert into the tabline when the uberwins are hidden
" flagcol:     Number between 1 and 9 representing which User highlight group
"              to use for the tabline flag
" priority:    uberwins will be opened in order of ascending priority
" widths:      Widths of uberwins. -1 means variable width.
" heights:     Heights of uberwins. -1 means variable height.
" toOpen:      Function that opens uberwins of this group type and returns their
"              window IDs. This function is required not to move the cursor
"              between windows before opening the uberwins
" toClose:     Function that closes the uberwins of this group type.
" toIdentify:  Function that, when called in an uberwin of a type from this group
"              type, returns the type name. Returns an empty string if called from
"              any other window
function! WinAddUberwinGroupType(name, typenames, statuslines,
                                \flag, hidflag, flagcol,
                                \priority, widths, heights, toOpen, toClose,
                                \toIdentify)
    call WinModelAddUberwinGroupType(a:name, a:typenames, a:statuslines,
                                    \a:flag, a:hidflag, a:flagcol,
                                    \a:priority, a:widths, a:heights,
                                    \a:toOpen, a:toClose, a:toIdentify)
    call EchomLog('window-user', 'config', 'Uberwin group type: ', a:name)
endfunction

" Add a subwin group type. One subwin group type represents the types of one or more
" subwins which are opened together
" one window
" name:         The name of the subwin group type
" typenames:    The names of the subwin types in the group
" statuslines:  The statusline strings of the uberwin types in the group
" flag:         Flag to insert into the statusline of the supwin of subwins of
"               types in this group type when the subwins are shown
" hidflag:      Flag to insert into the statusline of the supwin of subwins of
"               types in this group type when the subwins are hidden
" flagcol:      Number between 1 and 9 representing which User highlight group
"               to use for the statusline flag
" priority:     Subwins for a supwin will be opened in order of ascending
"               priority
" afterimaging: List of flags for each subwin type i nthe group. If true, afterimage
"               subwins of that type when they and their supwin lose focus
" widths:       Widths of subwins. -1 means variable width.
" heights:      Heights of subwins. -1 means variable height.
" toOpen:       Function that, when called from the supwin, opens subwins of these
"               types and returns their window IDs.
" toClose:      Function that, when called from a supwin, closes the the subwins of
"               this group type for the supwin.
" toIdentify:   Function that, when called in a subwin of a type from this group
"               type, returns a dict with the type name and supwin ID (with keys
"               'typename' and 'supwin' repspectively). Returns an enpty dict if
"               called from any other window
function! WinAddSubwinGroupType(name, typenames, statuslines,
                               \flag, hidflag, flagcol,
                               \priority, afterimaging, widths, heights,
                               \toOpen, toClose, toIdentify)
    call WinModelAddSubwinGroupType(a:name, a:typenames, a:statuslines,
                                   \a:flag, a:hidflag, a:flagcol,
                                   \a:priority, a:afterimaging,
                                   \a:widths, a:heights,
                                   \a:toOpen, a:toClose, a:toIdentify)
    call EchomLog('window-user', 'config', 'Subwin group type: ', a:name)
endfunction

" Uberwins

" For tabline generation
function! WinUberwinFlagsStr()
    " Due to a bug in Vim, this function sometimes throws E315 in terminal
    " windows
    try
        call EchomLog('window-user', 'debug', 'Retrieving Uberwin flags string')
        return WinModelUberwinFlagsStr()
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return ''
    endtry
endfunction

function! WinAddUberwinGroup(grouptypename, hidden)
    try
        call WinModelAssertUberwinGroupDoesntExist(a:grouptypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    " If we're adding the uberwin group as hidden, add it only to the model
    if a:hidden
        call EchomLog('window-user', 'info', 'WinAddUberwinGroup hidden ', a:grouptypename)
        call WinModelAddUberwins(a:grouptypename, [], [])
        call s:RunPostUserOpCallbacks()
        return
    endif
    
    call EchomLog('window-user', 'info', 'WinAddUberwinGroup shown ', a:grouptypename)

    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try
        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let grouptype = g:uberwingrouptype[a:grouptypename]
        let highertypes = WinCommonCloseUberwinsWithHigherPriority(grouptype.priority)
        call EchomLog('window-user', 'verbose', 'Closed higher-priority uberwin groups ', highertypes)
        try
            try
                let winids = WinCommonDoWithoutSubwins(info.win, function('WinCommonOpenUberwins'), [a:grouptypename])
                let dims = WinStateGetWinDimensionsList(winids)
                call EchomLog('window-user', 'verbose', 'Opened uberwin group ', a:grouptypename, ' in state with winids ', winids, ' and dimensions ', dims)
                call WinModelAddUberwins(a:grouptypename, winids, dims)
                call EchomLog('window-user', 'verbose', 'Added uberwin group ', a:grouptypename, ' to model')

            catch /.*/
                call EchomLog('window-user', 'warning', 'WinAddUberwinGroup failed to open ', a:grouptypename, ' uberwin group:')
                call EchomLog('window-user', 'debug', v:throwpoint)
                call EchomLog('window-user', 'warning', v:exception)
                call WinAddUberwinGroup(a:grouptypename, 1)
                return
            endtry

        " Reopen the uberwins we closed
        finally
            call WinCommonDoWithoutSubwins(info.win, function('WinCommonReopenUberwins'), [highertypes])
            call EchomLog('window-user', 'verbose', 'Reopened higher-priority uberwins groups')
        endtry
    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinRemoveUberwinGroup(grouptypename)
    call EchomLog('window-user', 'info', 'WinRemoveUberwinGroup ', a:grouptypename)
    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try
        let removed = 0
        if !WinModelUberwinGroupIsHidden(a:grouptypename)
            call WinCommonCloseUberwinsByGroupTypeName(a:grouptypename)
            call EchomLog('window-user', 'verbose', 'Closed uberwin group ', a:grouptypename, ' in state')
            let removed = 1
        endif

        call WinModelRemoveUberwins(a:grouptypename)
        call EchomLog('window-user', 'verbose', 'Removed uberwin group ', a:grouptypename, ' from model')

        if removed
            " Closing an uberwin changes how much space is available to supwins
            " and their subwins. Close and reopen all subwins.
            call WinCommonCloseAndReopenAllShownSubwins(info.win)
            call EchomLog('window-user', 'verbose', 'Closed and reopened all shown subwins')
        endif

    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinHideUberwinGroup(grouptypename)
    try
        call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'info', 'WinHideUberwinGroup ', a:grouptypename)

    let grouptype = g:uberwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try
        call WinCommonCloseUberwinsByGroupTypeName(a:grouptypename)
        call EchomLog('window-user', 'verbose', 'Closed uberwin group ', a:grouptypename, ' in state')
        call WinModelHideUberwins(a:grouptypename)
        call EchomLog('window-user', 'verbose', 'Hid uberwin group ', a:grouptypename, ' in model')

        " Closing an uberwin changes how much space is available to supwins
        " and their subwins. Close and reopen all subwins.
        call WinCommonCloseAndReopenAllShownSubwins(info.win)
        call EchomLog('window-user', 'verbose', 'Closed and reopened all shown subwins')

    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinShowUberwinGroup(grouptypename)
    try
        call WinModelAssertUberwinGroupIsHidden(a:grouptypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'info', 'WinShowUberwinGroup ', a:grouptypename)

    let grouptype = g:uberwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try
        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinCommonCloseUberwinsWithHigherPriority(grouptype.priority)
        call EchomLog('window-user', 'verbose', 'Closed higher-priority uberwin groups ', highertypes)
        try
            try
                let winids = WinCommonDoWithoutSubwins(info.win, function('WinCommonOpenUberwins'), [a:grouptypename])
                let dims = WinStateGetWinDimensionsList(winids)
                call EchomLog('window-user', 'verbose', 'Opened uberwin group ', a:grouptypename, ' in state with winids ', winids, ' and dimensions ', dims)
                call WinModelShowUberwins(a:grouptypename, winids, dims)
                call EchomLog('window-user', 'verbose', 'Showed uberwin group ', a:grouptypename, ' in model')

            catch /.*/
                call EchomLog('window-user', 'warning', 'WinShowUberwinGroup failed to open ', a:grouptypename, ' uberwin group:')
                call EchomLog('window-user', 'debug', v:throwpoint)
                call EchomLog('window-user', 'warning', v:exception)
                return
            endtry
        " Reopen the uberwins we closed
        finally
            call WinCommonDoWithoutSubwins(info.win, function('WinCommonReopenUberwins'), [highertypes])
            call EchomLog('window-user', 'verbose', 'Reopened higher-priority uberwins groups')
        endtry
    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Subwins

" For supwins' statusline generation
function! WinSubwinFlags()
    let flagsstr = ''

    " Due to a bug in Vim, these functions sometimes throws E315 in terminal
    " windows
    try
        call EchomLog('window-user', 'debug', 'Retrieving subwin flags string for current supwin')
        for grouptypename in WinModelSubwinGroupTypeNames()
            call EchomLog('window-user', 'verbose', 'Retrieving subwin flags string for subwin ', grouptypename, ' of current supwin')
            let flagsstr .= WinCommonSubwinFlagStrByGroup(grouptypename)
        endfor
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return ''
    endtry

    call EchomLog('window-user', 'verbose', 'Subwin flags string for current supwin: ', flagsstr)
    return flagsstr
endfunction

function! WinAddSubwinGroup(supwinid, grouptypename, hidden)
    try
        call WinModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    " If we're adding the subwin group as hidden, add it only to the model
    if a:hidden
        call EchomLog('window-user', 'info', 'WinAddSubwinGroup hidden ', a:supwinid, ':', a:grouptypename)
        call WinModelAddSubwins(a:supwinid, a:grouptypename, [], [])
        call s:RunPostUserOpCallbacks()
        return
    endif

    call EchomLog('window-user', 'info', 'WinAddSubwinGroup shown ', a:supwinid, ':', a:grouptypename)

    let grouptype = g:subwingrouptype[a:grouptypename]
    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, grouptype.priority)
        call EchomLog('window-user', 'verbose', 'Closed higher-priority subwin groups for supwin ', a:supwinid, ': ', highertypes)
        try
            try
                let winids = WinCommonOpenSubwins(a:supwinid, a:grouptypename)
                let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
                let reldims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
                call EchomLog('window-user', 'verbose', 'Opened subwin group ', a:supwinid, ':', a:grouptypename, ' in state with winids ', winids, ' and relative dimensions ', reldims)
                call WinModelAddSubwins(a:supwinid, a:grouptypename, winids, reldims)
                call EchomLog('window-user', 'verbose', 'Added subwin group ', a:supwinid, ':', a:grouptypename, ' to model')
            catch /.*/
                call EchomLog('window-user', 'warning', 'WinAddSubwinGroup failed to open ', a:grouptypename, ' subwin group for supwin ', a:supwinid, ':')
                call EchomLog('window-user', 'debug', v:throwpoint)
                call EchomLog('window-user', 'warning', v:exception)
                call WinAddSubwinGroup(a:supwinid, a:grouptypename, 1)
                return
            endtry

        " Reopen the subwins we closed
        finally
            call WinCommonReopenSubwins(a:supwinid, highertypes)
            call EchomLog('window-user', 'verbose', 'Reopened higher-priority subwin groups')
        endtry

    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinRemoveSubwinGroup(supwinid, grouptypename)
    try
        call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'info', 'WinRemoveSubwinGroup ', a:supwinid, ':', a:grouptypename)
    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try

        let grouptype = g:subwingrouptype[a:grouptypename]

        let removed = 0
        if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
            call WinCommonCloseSubwins(a:supwinid, a:grouptypename)
            call EchomLog('window-user', 'verbose', 'Closed subwin group ', a:supwinid, ':', a:grouptypename, ' in state')
            let removed = 1
        endif

        call WinModelRemoveSubwins(a:supwinid, a:grouptypename)
        call EchomLog('window-user', 'verbose', 'Removed subwin group ', a:supwinid, ':', a:grouptypename, ' from model')

        if removed
            call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
           \    a:supwinid,
           \    grouptype.priority
           \)
            call EchomLog('window-user', 'verbose', 'Closed and reopened all shown subwins of supwin ', a:supwinid, ' with priority higher than ', a:grouptypename)
        endif

    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinHideSubwinGroup(winid, grouptypename)
    try
        let supwinid = WinModelSupwinIdBySupwinOrSubwinId(a:winid)
        call WinModelAssertSubwinGroupIsNotHidden(supwinid, a:grouptypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'info', 'WinHideSubwinGroup ', a:grouptypename)
    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try
        let grouptype = g:subwingrouptype[a:grouptypename]

        call WinCommonCloseSubwins(supwinid, a:grouptypename)
        call EchomLog('window-user', 'verbose', 'Closed subwin group ', supwinid, ':', a:grouptypename, ' in state')
        call WinModelHideSubwins(supwinid, a:grouptypename)
        call EchomLog('window-user', 'verbose', 'Hid subwin group ', supwinid, ':', a:grouptypename, ' in model')
        call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
       \    supwinid,
       \    grouptype.priority
       \)
        call EchomLog('window-user', 'verbose', 'Closed and reopened all shown subwins of supwin ', supwinid, ' with priority higher than ', a:grouptypename)

    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinShowSubwinGroup(srcid, grouptypename)
    try
        let supwinid = WinModelSupwinIdBySupwinOrSubwinId(a:srcid)
        call WinModelAssertSubwinGroupIsHidden(supwinid, a:grouptypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    let grouptype = g:subwingrouptype[a:grouptypename]

    call EchomLog('window-user', 'info', 'WinShowSubwinGroup ', supwinid, ':', a:grouptypename)
    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinCommonCloseSubwinsWithHigherPriority(supwinid, grouptype.priority)
        call EchomLog('window-user', 'verbose', 'Closed higher-priority subwin groups for supwin ', supwinid, ': ', highertypes)
        try
            try
                let winids = WinCommonOpenSubwins(supwinid, a:grouptypename)
                let supwinnr = WinStateGetWinnrByWinid(supwinid)
                let reldims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
                call EchomLog('window-user', 'verbose', 'Opened subwin group ', supwinid, ':', a:grouptypename, ' in state with winids ', winids, ' and relative dimensions ', reldims)
                call WinModelShowSubwins(supwinid, a:grouptypename, winids, reldims)
                call EchomLog('window-user', 'verbose', 'Showed subwin group ', supwinid, ':', a:grouptypename, ' in model')

            catch /.*/
                call EchomLog('window-user', 'warning', 'WinShowSubwinGroup failed to open ', a:grouptypename, ' subwin group for supwin ', supwinid, ':')
                call EchomLog('window-user', 'debug', v:throwpoint)
                call EchomLog('window-user', 'warning', v:exception)
                return
            endtry

        " Reopen the subwins we closed
        finally
            call WinCommonReopenSubwins(supwinid, highertypes)
            call EchomLog('window-user', 'verbose', 'Reopened higher-priority subwin groups')
        endtry

    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry

    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Retrieve subwins and supwins' statuslines from the model
function! WinNonDefaultStatusLine()
    call EchomLog('window-user', 'debug', 'Retrieving non-default statusline for current window')
    let info = WinCommonGetCursorPosition().win
    return WinModelStatusLineByInfo(info)
endfunction

" Execute a Ctrl-W command under various conditions specified by flags
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. It is designed to be used only by the Commands and
" Mappings, which ensure consistency by passing carefully-chosen flags (and
" sometimes relying on the resolver).
" In particular, a true 'relyonresolver' signifies that this call will leave
" the state and model inconsistent
function! WinDoCmdWithFlags(cmd,
                          \ count,
                          \ preservecursor,
                          \ ifuberwindonothing, ifsubwingotosupwin,
                          \ dowithoutuberwins, dowithoutsubwins,
                          \ relyonresolver)
    call EchomLog('window-user', 'info', 'WinDoCmdWithFlags ', a:cmd, ' ', a:count, ' [', a:preservecursor, ',', a:ifuberwindonothing, ',', a:ifsubwingotosupwin, ',', a:dowithoutuberwins, ',', a:dowithoutsubwins, ',', a:relyonresolver, ']')
    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)

    if info.win.category ==# 'uberwin' && a:ifuberwindonothing
        call EchomLog('window-user', 'debug', 'Doing nothing in uberwin')
        return
    endif

    if info.win.category ==# 'subwin' && a:ifsubwingotosupwin
        call EchomLog('window-user', 'debug', 'Going from subwin to supwin')
        call WinGotoSupwin(info.win.supwin)
    endif

    let cmdinfo = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Running command from window ', cmdinfo)

    try
        if a:dowithoutuberwins && a:dowithoutsubwins
            call EchomLog('window-user', 'debug', 'Running command without uberwins or subwins')
            call WinCommonDoWithoutUberwinsOrSubwins(cmdinfo.win, function('WinStateWincmd'), [a:count, a:cmd])
        elseif a:dowithoutuberwins
            call EchomLog('window-user', 'debug', 'Running command without uberwins')
            call WinCommonDoWithoutUberwins(cmdinfo.win, function('WinStateWincmd'), [a:count, a:cmd])
        elseif a:dowithoutsubwins
            call EchomLog('window-user', 'debug', 'Running command without subwins')
            call WinCommonDoWithoutSubwins(cmdinfo.win, function('WinStateWincmd'), [a:count, a:cmd])
        else
            call EchomLog('window-user', 'debug', 'Running command')
            call WinStateWincmd(a:count, a:cmd)
        endif
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    finally
        let endinfo = WinCommonGetCursorPosition()
        if a:preservecursor
            call WinCommonRestoreCursorPosition(info)
            call EchomLog('window-user', 'verbose', 'Restored cursor position')
        elseif WinModelIdByInfo(info.win) !=# WinModelIdByInfo(endinfo.win)
            call WinModelSetPreviousWinInfo(info.win)
            call WinModelSetCurrentWinInfo(endinfo.win)
        endif
    endtry
    if !a:relyonresolver
        call WinCommonRecordAllDimensions()
        call s:RunPostUserOpCallbacks()
    endif
endfunction

" Navigation

" Movement between different categories of windows is restricted and sometimes
" requires afterimaging and deafterimaging
function! s:GoUberwinToUberwin(dstgrouptypename, dsttypename)
    try
        call WinModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'debug', 'GoUberwinToUberwin ', a:dstgrouptypename, ':', a:dsttypename)
    if WinModelUberwinGroupIsHidden(a:dstgrouptypename)
        call WinShowUberwinGroup(a:dstgrouptypename)
        call EchomLog('window-user', 'info', 'Showing uberwin group ', a:dstgrouptypename, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
    endif
    let winid = WinModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('window-user', 'verbose', 'Destination winid is ', winid)
    call WinStateMoveCursorToWinid(winid)
endfunction

function! s:GoUberwinToSupwin(dstsupwinid)
    call EchomLog('window-user', 'debug', 'GoUberwinToSupwin ', a:dstsupwinid)
    call WinStateMoveCursorToWinid(a:dstsupwinid)
    let cur = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', cur)
        call EchomLog('window-user', 'verbose', 'Deafterimaging subwins of destination supwin ', a:dstsupwinid)
        call WinCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinCommonRestoreCursorPosition(cur)
    call EchomLog('window-user', 'verbose', 'Restored cursor position')
endfunction

function! s:GoSupwinToUberwin(srcsupwinid, dstgrouptypename, dsttypename)
    try
        call WinModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'debug', 'GoSupwinToUberwin ', a:srcsupwinid, ', ', a:dstgrouptypename, ':', a:dsttypename)
    if WinModelUberwinGroupIsHidden(a:dstgrouptypename)
        call EchomLog('window-user', 'info', 'Showing uberwin group ', a:dstgrouptypename, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
        call WinShowUberwinGroup(a:dstgrouptypename)
    endif
    call EchomLog('window-user', 'verbose', 'Afterimaging subwins of source supwin ', a:srcsupwinid)
    call WinCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    let winid = WinModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('window-user', 'verbose', 'Destination winid is ', winid)
    call WinStateMoveCursorToWinid(winid)
endfunction

function! s:GoSupwinToSupwin(srcsupwinid, dstsupwinid)
    call EchomLog('window-user', 'debug', 'GoSupwinToSupwin ', a:srcsupwinid, ', ', a:dstsupwinid)
    call EchomLog('window-user', 'verbose', 'Afterimaging subwins of soruce supwin ',a:srcsupwinid)
    call WinCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    call WinStateMoveCursorToWinid(a:dstsupwinid)
    let cur = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', cur)
        call EchomLog('window-user', 'verbose', 'Deafterimaging subwins of destination supwin ', a:dstsupwinid)
        call WinCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinCommonRestoreCursorPosition(cur)
    call EchomLog('window-user', 'verbose', 'Restored cursor position')
endfunction

function! s:GoSupwinToSubwin(srcsupwinid, dstgrouptypename, dsttypename)
    try
        call WinModelAssertSubwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'debug', 'GoSupwinToSupwin ', a:srcsupwinid, ':', a:dstgrouptypename, ':', a:dsttypename)

    if WinModelSubwinGroupIsHidden(a:srcsupwinid, a:dstgrouptypename)
        call EchomLog('window-user', 'info', 'Showing subwin group ', a:srcsupwinid, ':', a:dstgrouptypename, ' so that the cursor can be moved to its subwin ', a:dsttypename)
        call WinShowSubwinGroup(a:srcsupwinid, a:dstgrouptypename)
    endif
    call EchomLog('window-user', 'verbose', 'Afterimaging subwins of source supwin ', a:srcsupwinid, ' except destination subwin group ', a:dstgrouptypename)
    call WinCommonAfterimageSubwinsBySupwinExceptOne(a:srcsupwinid, a:dstgrouptypename)
    let winid = WinModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('window-user', 'verbose', 'Destination winid is ', winid)
    call WinStateMoveCursorToWinid(winid)
endfunction

function! s:GoSubwinToSupwin(srcsupwinid)
    call EchomLog('window-user', 'debug', 'GoSubwinToSupwin ', a:srcsupwinid)
    call WinStateMoveCursorToWinid(a:srcsupwinid)
    let cur = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', cur)
        call EchomLog('window-user', 'verbose', 'Deafterimaging subwins of source supwin ', a:srcsupwinid)
        call WinCommonDeafterimageSubwinsBySupwin(a:srcsupwinid)
    call WinCommonRestoreCursorPosition(cur)
    call EchomLog('window-user', 'verbose', 'Restored cursor position')
endfunction
function! s:GoSubwinToSubwin(srcsupwinid, srcgrouptypename, dsttypename)
    call EchomLog('window-user', 'debug', 'GoSubwinToSubwin ', a:srcsupwinid, ':', a:srcgrouptypename, ':', a:dsttypename)
    let winid = WinModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:srcgrouptypename,
   \    'typename': a:dsttypename
   \})
    call EchomLog('window-user', 'verbose', 'Destination winid is ', winid)
    call WinStateMoveCursorToWinid(winid)
endfunction

" Move the cursor to a given uberwin
function! WinGotoUberwin(dstgrouptype, dsttypename)
    try
        call WinModelAssertUberwinTypeExists(a:dstgrouptype, a:dsttypename)
        call WinModelAssertUberwinGroupExists(a:dsttypename)
    catch /.*/
        call EchomLog('window-user', 'warning', 'Cannot go to uberwin ', a:dstgrouptype, ':', a:dsttypename, ':')
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'info', 'WinGotoUberwin ', a:dstgrouptype, ':', a:dsttypename)

    if WinModelUberwinGroupIsHidden(a:dstgrouptype)
        call EchomLog('window-user', 'info', 'Showing uberwin group ', a:dstgrouptype, ' so that the cursor can be moved to its uberwin ', a:dsttypename)
        call WinShowUberwinGroup(a:dstgrouptype)
    endif

    let cur = WinCommonGetCursorPosition()
    call WinModelSetPreviousWinInfo(cur.win)
    call EchomLog('window-user', 'verbose', 'Previous window set to ', cur.win)
    
    " Moving from subwin to uberwin must be done via supwin
    if cur.win.category ==# 'subwin'
        call EchomLog('window-user', 'debug', 'Moving to supwin first')
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'supwin'
        call s:GoSupwinToUberwin(cur.win.id, a:dstgrouptype, a:dsttypename)
        call WinModelSetCurrentWinInfo(WinCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToUberwin(a:dstgrouptype, a:dsttypename)
        call WinModelSetCurrentWinInfo(WinCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif

    throw 'Cursor window is neither subwin nor supwin nor uberwin'
endfunction

" Move the cursor to a given supwin
function! WinGotoSupwin(dstwinid)
    try
        let dstsupwinid = WinModelSupwinIdBySupwinOrSubwinId(a:dstwinid)
    catch /.*/
        call EchomLog('window-user', 'warning', 'Cannot go to supwin ', a:dstwinid, ':')
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry

    call EchomLog('window-user', 'info', 'WinGotoSupwin ', a:dstwinid)

    let cur = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Previous window set to ', cur.win)
    call WinModelSetPreviousWinInfo(cur.win)

    if cur.win.category ==# 'subwin'
        call EchomLog('window-user', 'debug', 'Moving to supwin first')
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToSupwin(dstsupwinid)
        call WinModelSetCurrentWinInfo(WinCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif

    if cur.win.category ==# 'supwin'
        if cur.win.id != dstsupwinid
            call s:GoSupwinToSupwin(cur.win.id,  dstsupwinid)
        endif
        call WinModelSetCurrentWinInfo(WinCommonGetCursorPosition().win)
        call s:RunPostUserOpCallbacks()
        return
    endif
endfunction

" Move the cursor to a given subwin
function! WinGotoSubwin(dstwinid, dstgrouptypename, dsttypename)
    try
        let dstsupwinid = WinModelSupwinIdBySupwinOrSubwinId(a:dstwinid)
        call WinModelAssertSubwinTypeExists(a:dstgrouptypename, a:dsttypename)
        call WinModelAssertSubwinGroupExists(dstsupwinid, a:dstgrouptypename)
    catch /.*/
        call EchomLog('window-user', 'warning', 'Cannot go to subwin ', a:dstgrouptypename, ':', a:dsttypename, ' of supwin ', a:dstwinid, ':')
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry
    
    call EchomLog('window-user', 'info', 'WinGotoSubwin ', a:dstwinid, ':', a:dstgrouptypename, ':', a:dsttypename)

    if WinModelSubwinGroupIsHidden(dstsupwinid, a:dstgrouptypename)
        call EchomLog('window-user', 'info', 'Showing subwin group ', dstsupwinid, ':', a:dstgrouptypename, ' so that the cursor can be moved to its subwin ', a:dsttypename)
        call WinShowSubwinGroup(dstsupwinid, a:dstgrouptypename)
    endif

    let cur = WinCommonGetCursorPosition()
    call WinModelSetPreviousWinInfo(cur.win)
    call EchomLog('window-user', 'verbose', 'Previous window set to ', cur.win)

    if cur.win.category ==# 'subwin'
        if cur.win.supwin ==# dstsupwinid && cur.win.grouptype ==# a:dstgrouptypename
            call s:GoSubwinToSubwin(cur.win.supwin, cur.win.grouptype, a:dsttypename)
            call WinModelSetCurrentWinInfo(WinCommonGetCursorPosition().win)
            call s:RunPostUserOpCallbacks()
            return
        endif

        call EchomLog('window-user', 'debug', 'Moving to supwin first')
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToSupwin(dstsupwinid)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category !=# 'supwin'
        throw 'Cursor should be in a supwin now'
    endif

    if cur.win.id !=# dstsupwinid
        call s:GoSupwinToSupwin(cur.win.id, dstsupwinid)
        let cur = WinCommonGetCursorPosition()
    endif

    call s:GoSupwinToSubwin(cur.win.id, a:dstgrouptypename, a:dsttypename)
    call WinModelSetCurrentWinInfo(WinCommonGetCursorPosition().win)
    call s:RunPostUserOpCallbacks()
endfunction

function! WinAddOrGotoUberwin(grouptypename, typename)
    call EchomLog('window-user', 'info', 'WinAddOrGotoUberwin ', a:grouptypename, ':', a:typename)
    if !WinModelUberwinGroupExists(a:grouptypename)
        call WinAddUberwinGroup(a:grouptypename, 0)
    endif
    call WinGotoUberwin(a:grouptypename, a:typename)
endfunction

function! WinAddOrGotoSubwin(supwinid, grouptypename, typename)
    call EchomLog('window-user', 'info', 'WinAddOrGotoSubwin ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    if !WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call WinAddSubwinGroup(a:supwinid, a:grouptypename, 0)
    endif
    call WinGotoSubwin(a:supwinid, a:grouptypename, a:typename)
endfunction

function! s:GotoByInfo(info)
    call EchomLog('window-user', 'debug', 'GotoByInfo ', a:info)
    if a:info.category ==# 'uberwin'
        call WinGotoUberwin(a:info.grouptype, a:info.typename)
        return
    endif
    if a:info.category ==# 'supwin'
        call WinGotoSupwin(a:info.id)
        return
    endif
    if a:info.category ==# 'subwin'
        call WinGotoSubwin(a:info.supwin, a:info.grouptype, a:info.typename)
        return
    endif
    throw 'Cannot go to window with category ' . a:info.category
endfunction

function! WinGotoPrevious(count)
    call EchomLog('window-user', 'info', 'WinGotoPrevious ', a:count)
    if a:count !=# 0 && a:count % 2 ==# 0
        call EchomLog('window-user', 'debug', 'Count is even. Doing nothing')
        return
    endif
    let dst = WinModelPreviousWinInfo()
    if !WinModelIdByInfo(dst)
        call EchomLog('window-user', 'debug', 'Previous window does not exist in model. Doing nothing.')
        return
    endif
    
    let src = WinCommonGetCursorPosition().win

    call WinModelSetPreviousWinInfo(src)
    call s:GotoByInfo(dst)
    call WinModelSetCurrentWinInfo(dst)

    call EchomLog('window-user', 'verbose', 'Previous window set to ', src)
    call s:RunPostUserOpCallbacks()
endfunction

function! s:GoInDirection(count, direction)
    call EchomLog('window-user', 'debug', 'GoInDirection ', a:count, ', ', a:direction)
    if type(a:count) ==# v:t_string && empty(a:count)
        call EchomLog('window-user', 'debug', 'Defaulting count to 1')
        let thecount = 1
    else
        let thecount = a:count
    endif
    for iter in range(thecount)
        call EchomLog('window-user', 'debug', 'Iteration ', iter)
        let srcwinid = WinStateGetCursorWinId()
        let srcinfo = WinModelInfoById(srcwinid)
        call EchomLog('window-user', 'debug', 'Source window is ', srcinfo)
        let srcsupwin = -1
        if srcinfo.category ==# 'subwin'
            let srcsupwin = srcinfo.supwin
        endif
        
        let curwinid = srcwinid
        let prvwinid = 0
        let dstwinid = 0
        while 1
            let prvwinid = curwinid
            call EchomLog('window-user', 'verbose', 'Silently moving cursor in direction ', a:direction)
            call WinStateSilentWincmd(1, a:direction)

            let curwinid = WinStateGetCursorWinId()
            let curwininfo = WinModelInfoById(curwinid)
            call EchomLog('window-user', 'verbose', 'Landed in ', curwininfo)
 
            if curwininfo.category ==# 'supwin'
                call EchomLog('window-user', 'debug', 'Found supwin ', curwinid)
                let dstwinid = curwinid
                break
            endif
            if curwininfo.category ==# 'subwin' && curwininfo.supwin !=# srcwinid &&
           \   curwininfo.supwin !=# srcsupwin
                call EchomLog('window-user', 'debug', 'Found supwin ', curwininfo.supwin, ' by its subwin ', curwininfo.grouptype, ':', curwininfo.typename)
                let dstwinid = curwininfo.supwin
                break
            endif
            if curwinid == prvwinid
                call EchomLog('window-user', 'verbose', 'Did not move from last step')
                break
            endif
        endwhile

        call EchomLog('window-user', 'verbose', 'Selected destination supwin ', dstwinid, '. Silently returning to source window')
        call WinStateMoveCursorToWinidSilently(srcwinid)
        if dstwinid
            call EchomLog('window-user', 'verbose', 'Moving to destination supwin ', dstwinid)
            call WinGotoSupwin(dstwinid)
        endif
    endfor
endfunction

" Move the cursor to the supwin on the left
function! WinGoLeft(count)
    call EchomLog('window-user', 'info', 'WinGoLeft ', a:count)
    call s:GoInDirection(a:count, 'h')
endfunction

" Move the cursor to the supwin below
function! WinGoDown(count)
    call EchomLog('window-user', 'info', 'WinGoDown ', a:count)
    call s:GoInDirection(a:count, 'j')
endfunction

" Move the cursor to the supwin above
function! WinGoUp(count)
    call EchomLog('window-user', 'info', 'WinGoUp ', a:count)
    call s:GoInDirection(a:count, 'k')
endfunction

" Move the cursor to the supwin to the right
function! WinGoRight(count)
    call EchomLog('window-user', 'info', 'WinGoRight ', a:count)
    call s:GoInDirection(a:count, 'l')
endfunction

" Close all windows except for either a given supwin, or the supwin of a given
" subwin
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. It is designed to rely on the resolver.
function! WinOnly(count)
    call EchomLog('window-user', 'info', 'WinOnly ', a:count)
    if type(a:count) ==# v:t_string && empty(a:count)
        let winid = WinStateGetCursorWinId()
        let thecount = WinStateGetWinnrByWinid(winid)
        call EchomLog('window-user', 'debug', 'Defaulting to current winnr ', thecount)
    else
        let thecount = a:count
    endif

    let winid = WinStateGetWinidByWinnr(thecount)
    let info = WinModelInfoById(winid)

    if info.category ==# 'uberwin'
        throw 'Cannot invoke WinOnly from uberwin'
        return
    endif
    if info.category ==# 'subwin'
        call EchomLog('window-user', 'debug', 'shifting target to supwin')
        let info = WinModelInfoById(info.supwin)
    endif

    call EchomLog('window-user', 'verbose', 'target window ', info)

    call s:GotoByInfo(info)

    call WinStateWincmd('', 'o')
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

" Exchange the current supwin (or current subwin's supwin) with a different
" supwin
function! WinExchange(count)
    let info = WinCommonGetCursorPosition()

    if info.win.category ==# 'uberwin'
        throw 'Cannot invoke WinExchange from uberwin'
        return
    endif

    call EchomLog('window-user', 'info', 'WinExchange ', a:count)

    if info.win.category ==# 'subwin'
        call EchomLog('window-user', 'debug', 'Moving to supwin first')
        call WinGotoSupwin(info.win.supwin)
    endif

    let cmdinfo = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Running command from window ', cmdinfo)

    try
        call WinCommonDoWithoutUberwinsOrSubwins(cmdinfo.win, function('WinStateWincmd'), [a:count, 'x'])
        if info.win.category ==# 'subwin'
            call EchomLog('window-user', 'verbose', 'Returning to subwin ' info.win)
            call WinGotoSubwin(WinStateGetCursorWinId(), info.win.grouptype, info.win.typename)
        endif
    catch /.*/
        call EchomLog('window-user', 'debug', v:throwpoint)
        call EchomLog('window-user', 'warning', v:exception)
        return
    endtry
    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! s:ResizeGivenNoSubwins(width, height)
    call EchomLog('window-user', 'debug', 'ResizeGivenNoSubwins ', ', [', a:width, ',', a:height, ']')

    let winid = WinModelIdByInfo(WinCommonGetCursorPosition().win)

    let preclosedim = WinStateGetWinDimensions(winid)

    call EchomLog('window-user', 'debug', 'Closing all uberwins')
    let closeduberwingroups = WinCommonCloseUberwinsWithHigherPriority(-1)
    try
        call WinStateMoveCursorToWinid(winid)

        let postclosedim = WinStateGetWinDimensions(winid)
        let deltaw = postclosedim.w - preclosedim.w
        let deltah = postclosedim.h - preclosedim.h
        let finalw = a:width + deltaw
        let finalh = a:height + deltah
        let dow = 1
        let doh = 1
        call EchomLog('window-user', 'debug', 'Deltas: dw=', deltaw, ' dh=', deltah)

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
            call EchomLog('window-user', 'debug', 'Resizing to width ', finalw)
            call WinStateWincmd(finalw, '|')
        endif
        if doh
            call EchomLog('window-user', 'debug', 'Resizing to height ', finalh)
            call WinStateWincmd(finalh, '_')
        endif
    finally
        call EchomLog('window-user', 'debug', 'Reopening all uberwins')
        call WinCommonReopenUberwins(closeduberwingroups)
    endtry
endfunction

function! WinResizeCurrentSupwin(width, height)
    let info = WinCommonGetCursorPosition()

    if info.win.category ==# 'uberwin'
        throw 'Cannot resize an uberwin'
        return
    endif

    call EchomLog('window-user', 'info', 'WinResizeCurrentSupwin ', a:width, ' ', a:height)

    if info.win.category ==# 'subwin'
        call EchomLog('window-user', 'debug', 'Moving to supwin first')
        call WinGotoSupwin(info.win.supwin)
    endif

    let cmdinfo = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Running command from window ', cmdinfo)

    try
        call WinCommonDoWithoutSubwins(cmdinfo.win, function('s:ResizeGivenNoSubwins'), [a:width, a:height])

    finally
        call WinCommonRestoreCursorPosition(info)
    endtry

    call WinCommonRecordAllDimensions()
    call s:RunPostUserOpCallbacks()
endfunction

function! WinResizeHorizontal(count)
    call EchomLog('window-user', 'info', 'WinResizeHorizontal ' . a:count)
    call WinResizeCurrentSupwin(-1, a:count)
endfunction

function! WinResizeVertical(count)
    call EchomLog('window-user', 'info', 'WinResizeVertical ' . a:count)
    call WinResizeCurrentSupwin(a:count, -1)
endfunction

" Run a command in every supwin
" WARNING! This particular user operation is not guaranteed to leave the state
" and model consistent. Avoid passing commands that change the window state.
function! SupwinDo(command, range)
    call EchomLog('window-user', 'info', 'SupwinDo <', a:command, '>, ', a:range)
    let info = WinCommonGetCursorPosition()
    call EchomLog('window-user', 'verbose', 'Preserved cursor position ', info)
    try
        for supwinid in WinModelSupwinIds()
            call WinGotoSupwin(supwinid)
            call EchomLog('window-user', 'verbose', 'running command <', a:range, a:command, '>')
            execute a:range . a:command
        endfor
    finally
        call WinCommonRestoreCursorPosition(info)
        call EchomLog('window-user', 'verbose', 'Restored cursor position')
    endtry
endfunction
