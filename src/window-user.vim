" Window user operations
" See window.vim

" The User Operations

" Register a callback to run after the resolver initializes a tab
function! WinAddTabInitPreResolveCallback(callback)
    call WinModelAddTabInitPreResolveCallback(a:callback)
endfunction

" Register a callback to run at the beginning of the resolver, when the
" resolver runs for the first time after entering a tab
function! WinAddTabEnterPreResolveCallback(callback)
    call WinModelAddTabEnterPreResolveCallback(a:callback)
endfunction

" Register a callback to run at the beginning of the resolver
function! WinAddPreResolveCallback(callback)
    call WinModelAddPreResolveCallback(a:callback)
endfunction

" Register a callback to run partway through the resolver if new supwins have
" been added to the model
function! WinAddSupwinsAddedResolveCallback(callback)
    call WinModelAddSupwinsAddedResolveCallback(a:callback)
endfunction

" Register a callback to run partway through the resolver, when the model has
" been adapted to the state
function! WinAddResolveCallback(callback)
    call WinModelAddResolveCallback(a:callback)
endfunction

" Register a callback to run at the end of the resolver
function! WinAddPostResolveCallback(callback)
    call WinModelAddPostResolveCallback(a:callback)
endfunction

" Add an uberwin group type. One uberwin group type represents one or more uberwins
" which are opened together
" one window
" name:       The name of the uberwin group type
" typenames:  The names of the uberwin types in the group
" flag:       Flag to insert into the tabline when the uberwins are shown
" hidflag:    Flag to insert into the tabline when the uberwins are hidden
" flagcol:    Number between 1 and 9 representing which User highlight group
"             to use for the tabline flag
" priority:   uberwins will be opened in order of ascending priority
" widths:     Widths of uberwins. -1 means variable width.
" heights:    Heights of uberwins. -1 means variable height.
" toOpen:     Function that opens uberwins of these types and returns their window
"             IDs.
" toClose:    Function that closes the the uberwins of this group type.
" toIdentify: Function that, when called in an uberwin of a type from this group
"             type, returns the type name. Returns an empty string if called from any
"             other window
function! WinAddUberwinGroupType(name, typenames, flag, hidflag, flagcol,
                                \priority, widths, heights, toOpen, toClose,
                                \toIdentify)
    call WinModelAddUberwinGroupType(a:name, a:typenames, a:flag, a:hidflag,
                                    \a:flagcol, a:priority, a:widths, a:heights,
                                    \a:toOpen, a:toClose, a:toIdentify)
endfunction

function! WinAddUberwinGroup(grouptypename, hidden)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call WinModelAssertUberwinGroupDoesntExist(a:grouptypename)

    " If we're adding the uberwin group as hidden, add it only to the model
    if a:hidden
        call WinModelAddUberwins(a:grouptypename, [])
        return
    endif

    let grouptype = g:uberwingrouptype[a:grouptypename]
    let info = WinCommonGetCursorWinInfo()

        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinCommonCloseUberwinsWithHigherPriority(grouptype.priority)

            let winids = WinStateOpenUberwinsByGroupType(grouptype)
 
            call WinModelAddUberwins(a:grouptypename, winids)

        " Reopen the uberwins we closed
        call WinCommonReopenUberwins(highertypes)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinRemoveUberwinGroup(grouptypename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)

    let info = WinCommonGetCursorWinInfo()

        if !WinModelUberwinGroupIsHidden(a:grouptypename)
            let grouptype = g:uberwingrouptype[a:grouptypename]
            call WinStateCloseUberwinsByGroupType(grouptype)
        endif

        call WinModelRemoveUberwins(a:grouptypename)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinHideUberwinGroup(grouptypename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)

    let grouptype = g:uberwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorWinInfo()

        call WinStateCloseUberwinsByGroupType(grouptype)
        call WinModelHideUberwins(a:grouptypename)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinShowUberwinGroup(grouptypename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call WinModelAssertUberwinGroupIsHidden(a:grouptypename)

    let grouptype = g:uberwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorWinInfo()

        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinCommonCloseUberwinsWithHigherPriority(grouptype.priority)

            let winids = WinStateOpenUberwinsByGroupType(grouptype)
 
            call WinModelShowUberwins(a:grouptypename, winids)

        " Reopen the uberwins we closed
        call WinCommonReopenUberwins(highertypes)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinGotoUberwin(grouptypename, typename)
    call WinModelAssertUberwinTypeExists(a:grouptypename, a:typename)
    if WinModelUberwinGroupIsHidden(a:grouptypename)
        call WinShowUberwinGroup(a:grouptypename)
    endif

    let winid = WinModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:grouptypename,
   \    'typename': a:typename
   \})
    call WinStateMoveCursorToWinid(winid)
endfunction

" Add a subwin group type. One subwin group type represents the types of one or more
" subwins which are opened together
" one window
" name:         The name of the subwin group type
" typenames:    The names of the subwin types in the group
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
function! WinAddSubwinGroupType(name, typenames, flag, hidflag, flagcol,
                                    \priority, afterimaging, widths, heights,
                                    \toOpen, toClose, toIdentify)
    call WinModelAddSubwinGroupType(a:name, a:typenames, a:flag, a:hidflag,
                                   \a:flagcol, a:priority, a:afterimaging,
                                   \a:widths, a:heights, a:toOpen, a:toClose,
                                   \a:toIdentify)
endfunction

function! WinAddSubwinGroup(supwinid, grouptypename, hidden)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)

    " If we're adding the subwin group as hidden, add it only to the model
    if a:hidden
        call WinModelAddSubwins(a:supwinid, a:grouptypename, [])
        return
    endif

    let grouptype = g:subwingrouptype[a:grouptypename]
    let info = WinCommonGetCursorWinInfo()

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, grouptype.priority)

            let winids = WinStateOpenSubwinsByGroupType(a:supwinid, grouptype)
 
            call WinModelAddSubwins(a:supwinid, a:grouptypename, winids)

        " Reopen the subwins we closed
        call WinCommonReopenSubwins(a:supwinid, highertypes)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinRemoveSubwinGroup(supwinid, grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)

    let info = WinCommonGetCursorWinInfo()

        if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
            let grouptype = g:subwingrouptype[a:grouptypename]
            call WinStateCloseSubwinsByGroupType(a:supwinid, grouptype)
        endif

        call WinModelRemoveSubwins(a:supwinid, a:grouptypename)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinHideSubwinGroup(supwinid, grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    let grouptype = g:subwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorWinInfo()

        call WinStateCloseSubwinsByGroupType(a:supwinid, grouptype)
        call WinModelHideSubwins(a:supwinid, a:grouptypename)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinShowSubwinGroup(supwinid, grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinGroupIsHidden(a:supwinid, a:grouptypename)

    let grouptype = g:subwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorWinInfo()

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, grouptype.priority)

            let winids = WinStateOpenSubwinsByGroupType(a:supwinid, grouptype)
 
            call WinModelShowSubwins(a:supwinid, a:grouptypename, winids)

        " Reopen the subwins we closed
        call WinCommonReopenSubwins(a:supwinid, highertypes)

    call WinCommonRestoreCursorWinInfo(info)
endfunction

function! WinGotoSubwin(supwinid, grouptypename, typename)
    call WinModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    if WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        call WinShowSubwinGroup(a:supwinid, a:grouptypename)
    endif
    let winid = WinModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:supwinid,
   \    'grouptype': a:grouptypename,
   \    'typename': a:typename
   \})
    call WinStateMoveCursorToWinid(winid)
endfunction

" TODO: Zoom on supwins
" TODO: Move from one supwin to another, in a direction
