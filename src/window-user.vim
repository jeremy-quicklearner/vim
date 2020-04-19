" Window user operations
" See window.vim
" " TODO: Add validation to add/remove/show/hide

" The User Operations

" Resolver callback registration

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

" Group Types

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

" Uberwins

function! WinAddUberwinGroup(grouptypename, hidden)
    call WinModelAssertUberwinGroupDoesntExist(a:grouptypename)

    " If we're adding the uberwin group as hidden, add it only to the model
    if a:hidden
        call WinModelAddUberwins(a:grouptypename, [], [])
        return
    endif

    let grouptype = g:uberwingrouptype[a:grouptypename]
    let info = WinCommonGetCursorPosition()

        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinCommonCloseUberwinsWithHigherPriority(grouptype.priority)

            let winids = WinStateOpenUberwinsByGroupType(grouptype)
 
            let dims = WinStateGetWinDimensionsList(winids)

            call WinModelAddUberwins(a:grouptypename, winids, dims)

        " Reopen the uberwins we closed
        call WinCommonReopenUberwins(highertypes)

        " Opening an uberwin changes how much space is available to supwins
        " and their subwins. So close and reopen all subwins.
        call WinCommonCloseAndReopenAllShownSubwins(info.win)

    call WinCommonRestoreCursorPosition(info)
endfunction

function! WinRemoveUberwinGroup(grouptypename)
    let info = WinCommonGetCursorPosition()

        if !WinModelUberwinGroupIsHidden(a:grouptypename)
            let grouptype = g:uberwingrouptype[a:grouptypename]
            call WinStateCloseUberwinsByGroupType(grouptype)
        endif

        " Opening an uberwin changes how much space is available to supwins
        " and their subwins. Close and reopen all subwins.
        call WinCommonCloseAndReopenAllShownSubwins(info.win)

    call WinCommonRestoreCursorPosition(info)

    call WinModelRemoveUberwins(a:grouptypename)

endfunction

function! WinHideUberwinGroup(grouptypename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)

    let grouptype = g:uberwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()

        call WinStateCloseUberwinsByGroupType(grouptype)
        call WinModelHideUberwins(a:grouptypename)

        " Opening an uberwin changes how much space is available to supwins
        " and their subwins. Close and reopen all subwins.
        call WinCommonCloseAndReopenAllShownSubwins(info.win)

    call WinCommonRestoreCursorPosition(info)
endfunction

function! WinShowUberwinGroup(grouptypename)
    call WinModelAssertUberwinGroupIsHidden(a:grouptypename)

    let grouptype = g:uberwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()

        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinCommonCloseUberwinsWithHigherPriority(grouptype.priority)

            let winids = WinStateOpenUberwinsByGroupType(grouptype)
 
            let dims = WinStateGetWinDimensionsList(winids)

            call WinModelShowUberwins(a:grouptypename, winids, dims)

        " Reopen the uberwins we closed
        call WinCommonReopenUberwins(highertypes)

        " Opening an uberwin changes how much space is available to supwins
        " and their subwins. Close and reopen all subwins.
        call WinCommonCloseAndReopenAllShownSubwins(info.win)

    call WinCommonRestoreCursorPosition(info)
endfunction

" Subwins

function! WinAddSubwinGroup(supwinid, grouptypename, hidden)
    call WinModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)

    " If we're adding the subwin group as hidden, add it only to the model
    if a:hidden
        call WinModelAddSubwins(a:supwinid, a:grouptypename, [], [])
        return
    endif

    let grouptype = g:subwingrouptype[a:grouptypename]
    let info = WinCommonGetCursorPosition()

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, grouptype.priority)

            let winids = WinStateOpenSubwinsByGroupType(a:supwinid, grouptype)

            let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
            let reldims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
 
            call WinModelAddSubwins(a:supwinid, a:grouptypename, winids, reldims)

        " Reopen the subwins we closed
        call WinCommonReopenSubwins(a:supwinid, highertypes)

    call WinCommonRestoreCursorPosition(info)

    let dims = WinStateGetWinDimensions(a:supwinid)
    call WinModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

function! WinRemoveSubwinGroup(supwinid, grouptypename)
    let info = WinCommonGetCursorPosition()

        call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
        let grouptype = g:subwingrouptype[a:grouptypename]

        if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
            call WinCommonCloseSubwins(a:supwinid, a:grouptypename)
        endif

        call WinModelRemoveSubwins(a:supwinid, a:grouptypename)

        call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
       \    a:supwinid,
       \    grouptype.priority
       \)

    call WinCommonRestoreCursorPosition(info)

endfunction

function! WinHideSubwinGroup(supwinid, grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    let grouptype = g:subwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()

        call WinCommonCloseSubwins(a:supwinid, a:grouptypename)

        call WinModelHideSubwins(a:supwinid, a:grouptypename)

        call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
       \    a:supwinid,
       \    grouptype.priority
       \)

    call WinCommonRestoreCursorPosition(info)

endfunction

function! WinShowSubwinGroup(supwinid, grouptypename)
    call WinModelAssertSubwinGroupIsHidden(a:supwinid, a:grouptypename)

    let grouptype = g:subwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, grouptype.priority)

            let winids = WinStateOpenSubwinsByGroupType(a:supwinid, grouptype)

            let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
            let reldims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)

            call WinModelShowSubwins(a:supwinid, a:grouptypename, winids, reldims)

        " Reopen the subwins we closed
        call WinCommonReopenSubwins(a:supwinid, highertypes)

    call WinCommonRestoreCursorPosition(info)

    let dims = WinStateGetWinDimensions(a:supwinid)
    call WinModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

" Window resizing
function! WinEqualizeSupwins()
    let closedsubwingroupsbysupwin = {}

    let info = WinCommonGetCursorPosition()

       let supwinids = WinModelSupwinIds()
       if empty(supwinids)
           return
       endif

       let startwith = supwinids[0]

       " If the cursor is in a supwin, start with it
       if info.win.category ==# 'supwin'
           let startwith = info.win.id

       " If the cursor is in a subwin, start with its supwin
       elseif info.win.category ==# 'subwin'
           let startwith = info.win.supwin
       endif

       call remove(supwinids, index(supwinids, startwith))
       call insert(supwinids, startwith)

       for supwinid in supwinids
            let closedsubwingroupsbysupwin[supwinid] = 
           \    WinCommonCloseSubwinsWithHigherPriority(supwinid, -1)
        endfor

        call WinStateEqualizeWindows()

        for supwinid in WinModelSupwinIds()
            call WinCommonReopenSubwins(supwinid, closedsubwingroupsbysupwin[supwinid])
            let dims = WinStateGetWinDimensions(supwinid)
            " Afterimage everything after finishing with each supwin to avoid collisions
            call WinCommonAfterimageSubwinsBySupwin(supwinid)
            call WinModelChangeSupwinDimensions(supwinid, dims.nr, dims.w, dims.h)
        endfor

    call WinCommonRestoreCursorPosition(info)
    
endfunction

function! WinZoomCurrentSupwin()
    let info = WinCommonGetCursorPosition()
        if info.win.category ==# 'uberwin'
            return
        endif

        if info.win.category ==# 'subwin'
            let tozoom = info.win.supwin
        elseif info.win.category ==# 'supwin'
            let tozoom = info.win.id
        else
            return
        endif

        let zoomedgrouptypenames = []
        for supwinid in WinModelSupwinIds()
            if supwinid ==# tozoom
                let zoomedgrouptypenames = WinCommonCloseSubwinsWithHigherPriority(
               \    tozoom,
               \    -1
               \)
                continue
            endif
            for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
                call WinHideSubwinGroup(supwinid, grouptypename)
            endfor
        endfor

        call WinStateMoveCursorToWinid(tozoom)
        call WinStateZoomCurrentWindow()
        call WinCommonReopenSubwins(tozoom, zoomedgrouptypenames)

    call WinCommonRestoreCursorPosition(info)
endfunction

" Movement between different categories of windows is restricted and sometimes
" requires afterimaging and deafterimaging
" TODO: Write an 'alwayshide' option that closes subwins when the cursor isn't
" in them
function! s:GoUberwinToUberwin(dstgrouptypename, dsttypename)
    call WinModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    if WinModelUberwinGroupIsHidden(a:dstgrouptypename)
        call WinShowUberwinGroup(a:dstgrouptypename)
    endif
    let winid = WinModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:grouptypename,
   \    'typename': a:typename
   \})
    call WinStateMoveCursorToWinid(winid)
endfunction

function! s:GoUberwinToSupwin(dstsupwinid)
    call WinStateMoveCursorToWinid(a:dstsupwinid)
    let cur = WinCommonGetCursorPosition()
        call WinCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinCommonRestoreCursorPosition(cur)
endfunction

function! s:GoSupwinToUberwin(srcsupwinid, dstgrouptypename, dsttypename)
    call WinModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    if WinModelUberwinGroupIsHidden(a:dstgrouptypename)
        call WinShowUberwinGroup(a:dstgrouptypename)
    endif
    call WinCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    let winid = WinModelIdByInfo({
   \    'category': 'uberwin',
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call WinStateMoveCursorToWinid(winid)
endfunction

function! s:GoSupwinToSupwin(srcsupwinid, dstsupwinid)
    call WinCommonAfterimageSubwinsBySupwin(a:srcsupwinid)
    call WinStateMoveCursorToWinid(a:dstsupwinid)
    let cur = WinCommonGetCursorPosition()
        call WinCommonDeafterimageSubwinsBySupwin(a:dstsupwinid)
    call WinCommonRestoreCursorPosition(cur)
endfunction

function! s:GoSupwinToSubwin(srcsupwinid, dstgrouptypename, dsttypename)
    call WinModelAssertSubwinTypeExists(a:dstgrouptypename, a:dsttypename)
    if WinModelSubwinGroupIsHidden(a:srcsupwinid, a:dstgrouptypename)
        call WinShowSubwinGroup(a:srcsupwinid, a:dstgrouptypename)
    endif
    call WinCommonAfterimageSubwinsBySupwinExceptOne(a:srcsupwinid, a:dstgrouptypename)
    let winid = WinModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:dstgrouptypename,
   \    'typename': a:dsttypename
   \})
    call WinStateMoveCursorToWinid(winid)
endfunction

function! s:GoSubwinToSupwin(srcsupwinid)
    call WinStateMoveCursorToWinid(a:srcsupwinid)
    let cur = WinCommonGetCursorPosition()
        call WinCommonDeafterimageSubwinsBySupwin(a:srcsupwinid)
    call WinCommonRestoreCursorPosition(cur)
endfunction
function! s:GoSubwinToSubwin(srcsupwinid, srcgrouptypename, dsttypename)
    let winid = WinModelIdByInfo({
   \    'category': 'subwin',
   \    'supwin': a:srcsupwinid,
   \    'grouptype': a:srcgrouptype,
   \    'typename': a:dsttypename
   \})
    call WinStateMoveCursorToWinid(winid)
endfunction

" Move the cursor to a given uberwin
function! WinGotoUberwin(dstgrouptype, dsttypename)
    let cur = WinCommonGetCursorPosition()
    
    " Moving from subwin to uberwin must be done via supwin
    if cur.win.category ==# 'subwin'
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'supwin'
        call s:GoSupwinToUberwin(curwin.id, a:dstgrouptype, a:dsttypename)
        return
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToUberwin(a:dstgrouptypename, a:dsttypename)
        return
    endif

    throw 'Cursor window is neither supwin nor uberwin'
endfunction

" Move the cursor to a given supwin
function! WinGotoSupwin(dstsupwinid)
    let cur = WinCommonGetCursorPosition()

    if cur.win.category ==# 'subwin'
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur.win = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToSupwin(a:dstsupwinid)
        return
    endif

    if cur.win.category ==# 'supwin' && cur.win.id != a:dstsupwinid
        call s:GoSupwinToSupwin(cur.win.id,  a:dstsupwinid)
        return
    endif
endfunction

" Move the cursor to a given subwin
function! WinGotoSubwin(dstsupwinid, dstgrouptypename, dsttypename)
    let cur = WinCommonGetCursorPosition()

    if cur.win.category ==# 'subwin'
        if cur.win.supwin ==# a:dstsupwinid && cur.win.grouptype ==# a:dstgrouptypename
            call s:GoSubwinToSubwin(cur.win.supwin, cur.win.grouptype, a:dsttypename)
            return
        endif

        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToSupwin(a:dstsupwinid)
        let cur.win = WinCommonGetCursorPosition()
    endif

    if cur.win.category !=# 'supwin'
        throw 'Cursor should be in a supwin now'
    endif

    if cur.win.id !=# a:dstsupwinid
        call s:GoSupwinToSupwin(cur.win.id, a:dstsupwinid)
        let cur = WinCommonGetCursorPosition()
    endif

    call s:GoSupwinToSubwin(cur.win.id, a:dstgrouptypename, a:dsttypename)
endfunction

function! s:GoInDirection(direction)
    let srcwinid = WinStateGetCursorWinId()
    let curwinid = srcwinid
    let prvwinid = 0
    let dstwinid = 0
    while 1
        let prvwinid = curwinid
        execute 'call WinStateMoveCursor' . a:direction . 'Silently()'
        let curwinid = WinStateGetCursorWinId()
 
        if WinModelSupwinExists(curwinid)
            let dstwinid = curwinid
            break
        endif
        if curwinid == prvwinid
            break
        endif
    endwhile

    call WinStateMoveCursorToWinidSilently(srcwinid)
    if dstwinid
        call WinGotoSupwin(dstwinid)
    endif
endfunction

" Move the cursor to the supwin on the left
function! WinGoLeft()
    call s:GoInDirection('Left')
endfunction

" Move the cursor to the supwin below
function! WinGoDown()
    call s:GoInDirection('Down')
endfunction

" Move the cursor to the supwin above
function! WinGoUp()
    call s:GoInDirection('Up')
endfunction

" Move the cursor to the supwin to the right
function! WinGoRight()
    call s:GoInDirection('Right')
endfunction

" TODO: Something like WinDo but just for supwins
