" Window user operations
" See window.vim

" Resolver callback registration

" Register a callback to run at the beginning of the resolver, when the
" resolver runs for the first time after entering a tab
function! WinAddTabEnterPreResolveCallback(callback)
    call WinModelAddTabEnterPreResolveCallback(a:callback)
endfunction

" Register a callback to run partway through the resolver if new supwins have
" been added to the model
function! WinAddSupwinsAddedResolveCallback(callback)
    call WinModelAddSupwinsAddedResolveCallback(a:callback)
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
"              window IDs.
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
endfunction

" Uberwins

" For tabline generation
function! WinUberwinFlagsStr()
    return WinModelUberwinFlagsStr()
endfunction

function! WinAddUberwinGroup(grouptypename, hidden)
    try
        call WinModelAssertUberwinGroupDoesntExist(a:grouptypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

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

            try
                let winids = WinStateOpenUberwinsByGroupType(grouptype)
 
                let dims = WinStateGetWinDimensionsList(winids)

                call WinModelAddUberwins(a:grouptypename, winids, dims)
            catch /.*/
                echom 'WinAddUberwinGroup failed to open ' . a:grouptypename . ' uberwin group:'
                echohl ErrorMsg | echom v:exception | echohl None
            endtry

        " Reopen the uberwins we closed
        call WinCommonReopenUberwins(highertypes)

        " Opening an uberwin changes how much space is available to supwins
        " and their subwins. So close and reopen all subwins.
        call WinCommonCloseAndReopenAllShownSubwins(info.win)

    call WinCommonRestoreCursorPosition(info)
endfunction

function! WinRemoveUberwinGroup(grouptypename)
    let info = WinCommonGetCursorPosition()

        let removed = 0
        if !WinModelUberwinGroupIsHidden(a:grouptypename)
            let grouptype = g:uberwingrouptype[a:grouptypename]
            call WinStateCloseUberwinsByGroupType(grouptype)
            let removed = 1
        endif

        call WinModelRemoveUberwins(a:grouptypename)

        if removed
            " Opening an uberwin changes how much space is available to supwins
            " and their subwins. Close and reopen all subwins.
            call WinCommonCloseAndReopenAllShownSubwins(info.win)
        endif

    call WinCommonRestoreCursorPosition(info)
endfunction

function! WinHideUberwinGroup(grouptypename)
    try
        call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

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
    try
        call WinModelAssertUberwinGroupIsHidden(a:grouptypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

    let grouptype = g:uberwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()

        " Each uberwin must be, at the time it is opened, the one with the
        " highest priority. So close all uberwins with higher priority.
        let highertypes = WinCommonCloseUberwinsWithHigherPriority(grouptype.priority)

            try
                let winids = WinStateOpenUberwinsByGroupType(grouptype)
 
                let dims = WinStateGetWinDimensionsList(winids)

                call WinModelShowUberwins(a:grouptypename, winids, dims)
            catch /.*/
                echom 'WinAddUberwinGroup failed to open ' . a:grouptypename . ' uberwin group:'
                echohl ErrorMsg | echom v:exception | echohl None
            endtry

        " Reopen the uberwins we closed
        call WinCommonReopenUberwins(highertypes)

        " Opening an uberwin changes how much space is available to supwins
        " and their subwins. Close and reopen all subwins.
        call WinCommonCloseAndReopenAllShownSubwins(info.win)

    call WinCommonRestoreCursorPosition(info)
endfunction

" Subwins

" For supwins' statusline generation
function! WinSubwinFlags()
    let flagsstr = ''
    for grouptypename in WinModelSubwinGroupTypeNames()
        let flagsstr .= WinCommonSubwinFlagStrByGroup(grouptypename)
    endfor
    return flagsstr
endfunction

function! WinAddSubwinGroup(supwinid, grouptypename, hidden)
    try
        call WinModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

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

            try
                let winids = WinCommonOpenSubwins(a:supwinid, a:grouptypename)

                let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
                let reldims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)
 
                call WinModelAddSubwins(a:supwinid, a:grouptypename, winids, reldims)
            catch /.*/
                echom 'WinAddSubwinGroup failed to open ' . a:grouptypename . ' subwin group for supwin ' . a:supwinid . ':'
                echohl ErrorMsg | echom v:exception | echohl None
            endtry

        " Reopen the subwins we closed
        call WinCommonReopenSubwins(a:supwinid, highertypes)

    call WinCommonRestoreCursorPosition(info)

    let dims = WinStateGetWinDimensions(a:supwinid)
    call WinModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

function! WinRemoveSubwinGroup(supwinid, grouptypename)
    try
        call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

    let info = WinCommonGetCursorPosition()

        let grouptype = g:subwingrouptype[a:grouptypename]

        let removed = 0
        if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
            call WinCommonCloseSubwins(a:supwinid, a:grouptypename)
            let removed = 1
        endif

        call WinModelRemoveSubwins(a:supwinid, a:grouptypename)

        if removed
            call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
           \    a:supwinid,
           \    grouptype.priority
           \)
        endif

    call WinCommonRestoreCursorPosition(info)
endfunction

function! WinHideSubwinGroup(winid, grouptypename)
    try
        let supwinid = WinModelSupwinIdBySupwinOrSubwinId(a:winid)
        call WinModelAssertSubwinGroupIsNotHidden(supwinid, a:grouptypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

    let grouptype = g:subwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()

        call WinCommonCloseSubwins(supwinid, a:grouptypename)

        call WinModelHideSubwins(supwinid, a:grouptypename)

        call WinCommonCloseAndReopenSubwinsWithHigherPriorityBySupwin(
       \    supwinid,
       \    grouptype.priority
       \)

    call WinCommonRestoreCursorPosition(info)
endfunction

function! WinShowSubwinGroup(supwinid, grouptypename)
    try
        call WinModelAssertSubwinGroupIsHidden(a:supwinid, a:grouptypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

    let grouptype = g:subwingrouptype[a:grouptypename]

    let info = WinCommonGetCursorPosition()

        " Each subwin must be, at the time it is opened, the one with the
        " highest priority for its supwin. So close all supwins with higher priority.
        let highertypes = WinCommonCloseSubwinsWithHigherPriority(a:supwinid, grouptype.priority)

            try
                let winids = WinCommonOpenSubwins(a:supwinid, a:grouptypename)

                let supwinnr = WinStateGetWinnrByWinid(a:supwinid)
                let reldims = WinStateGetWinRelativeDimensionsList(winids, supwinnr)

                call WinModelShowSubwins(a:supwinid, a:grouptypename, winids, reldims)
            catch /.*/
                echom 'WinShowSubwinGroup failed to open ' . a:grouptypename . ' subwin group for supwin ' . a:supwinid . ':'
                echohl ErrorMsg | echom v:exception | echohl None
            endtry

        " Reopen the subwins we closed
        call WinCommonReopenSubwins(a:supwinid, highertypes)

    call WinCommonRestoreCursorPosition(info)

    let dims = WinStateGetWinDimensions(a:supwinid)
    call WinModelChangeSupwinDimensions(a:supwinid, dims.nr, dims.w, dims.h)
endfunction

" Retrieve subwins and supwins' statuslines from the model
function! WinNonDefaultStatusLine()
    let info = WinCommonGetCursorPosition().win
    return WinModelStatusLineByInfo(info)
endfunction

" Execute a Ctrl-W command under various conditions specified by flags
function! WinDoCmdWithFlags(cmd,
                          \ count,
                          \ preservecursor,
                          \ ifuberwindonothing, ifsubwingotosupwin,
                          \ dowithoutuberwins, dowithoutsubwins)
    let info = WinCommonGetCursorPosition()

    if info.win.category ==# 'uberwin' && a:ifuberwindonothing
        return
    endif

    if info.win.category ==# 'subwin' && a:ifsubwingotosupwin
        call WinGotoSupwin(info.win.supwin)
    endif

    if a:dowithoutuberwins && a:dowithoutsubwins
        call WinCommonDoWithoutUberwinsOrSubwins(info.win, function('WinStateWincmd'), [a:count, a:cmd])
    elseif a:dowithoutuberwins
        call WinCommonDoWithoutUberwins(info.win, function('WinStateWincmd'), [a:count, a:cmd])
    elseif a:dowithoutsubwins
        call WinCommonDoWithoutSubwins(info.win, function('WinStateWincmd'), [a:count, a:cmd])
    else
        call WinStateWincmd(a:count, a:cmd)
    endif

    if a:preservecursor
        call WinCommonRestoreCursorPosition(info)
    endif
endfunction

" Navigation

" Movement between different categories of windows is restricted and sometimes
" requires afterimaging and deafterimaging
function! s:GoUberwinToUberwin(dstgrouptypename, dsttypename)
    try
        call WinModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry
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
    try
        call WinModelAssertUberwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry
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
    try
        call WinModelAssertSubwinTypeExists(a:dstgrouptypename, a:dsttypename)
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry
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
   \    'grouptype': a:srcgrouptypename,
   \    'typename': a:dsttypename
   \})
    call WinStateMoveCursorToWinid(winid)
endfunction

" Move the cursor to a given uberwin
function! WinGotoUberwin(dstgrouptype, dsttypename)
    try
        call WinModelAssertUberwinTypeExists(a:dstgrouptype, a:dsttypename)
        call WinModelAssertUberwinGroupExists(a:dsttypename)
    catch /.*/
        echom 'Cannot go to uberwin ' . a:dstgrouptype . ':' . a:dsttypename . ':'
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

    if WinModelUberwinGroupIsHidden(a:dstgrouptype)
        call WinShowUberwinGroup(a:dstgrouptype)
    endif

    let cur = WinCommonGetCursorPosition()
    call WinModelSetPreviousWinInfo(cur.win)
    
    " Moving from subwin to uberwin must be done via supwin
    if cur.win.category ==# 'subwin'
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'supwin'
        call s:GoSupwinToUberwin(cur.win.id, a:dstgrouptype, a:dsttypename)
        return
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToUberwin(a:dstgrouptypename, a:dsttypename)
        return
    endif

    throw 'Cursor window is neither subwin nor supwin nor uberwin'
endfunction

" Move the cursor to a given supwin
function! WinGotoSupwin(dstwinid)
    try
        let dstsupwinid = WinModelSupwinIdBySupwinOrSubwinId(a:dstwinid)
    catch /.*/
        echom 'Cannot go to supwin ' . a:dstwinid . ':'
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

    let cur = WinCommonGetCursorPosition()
    call WinModelSetPreviousWinInfo(cur.win)

    if cur.win.category ==# 'subwin'
        call s:GoSubwinToSupwin(cur.win.supwin)
        let cur = WinCommonGetCursorPosition()
    endif

    if cur.win.category ==# 'uberwin'
        call s:GoUberwinToSupwin(dstsupwinid)
        return
    endif

    if cur.win.category ==# 'supwin' && cur.win.id != dstsupwinid
        call s:GoSupwinToSupwin(cur.win.id,  dstsupwinid)
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
        echom 'Cannot go to subwin ' . a:dstgrouptypename . ':' . a:dsttypename . ' of supwin ' . a:dstwinid . ':'
        echohl ErrorMsg | echo v:exception | echohl None
        return
    endtry

    if WinModelSubwinGroupIsHidden(dstsupwinid, a:dstgrouptypename)
        call WinShowSubwinGroup(dstsupwinid, a:dstgrouptypename)
    endif

    let cur = WinCommonGetCursorPosition()
    call WinModelSetPreviousWinInfo(cur.win)

    if cur.win.category ==# 'subwin'
        if cur.win.supwin ==# dstsupwinid && cur.win.grouptype ==# a:dstgrouptypename
            call s:GoSubwinToSubwin(cur.win.supwin, cur.win.grouptype, a:dsttypename)
            return
        endif

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
endfunction

function! s:GotoByInfo(info)
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
    if a:count !=# 0 && a:count % 2 ==# 0
        return
    endif
    let dst = WinModelPreviousWinInfo()
    if !WinModelIdByInfo(dst)
        return
    endif
    
    let src = WinCommonGetCursorPosition().win

    call s:GotoByInfo(dst)

    call WinModelSetPreviousWinInfo(src)
endfunction

function! s:GoInDirection(count, direction)
    for iter in range(a:count)
        let srcwinid = WinStateGetCursorWinId()
        let curwinid = srcwinid
        let prvwinid = 0
        let dstwinid = 0
        while 1
            let prvwinid = curwinid
            call WinStateSilentWincmd(1, a:direction)

            let curwinid = WinStateGetCursorWinId()
            let curwininfo = WinModelInfoById(curwinid)
 
            if curwininfo.category ==# 'supwin'
                let dstwinid = curwinid
                break
            endif
            if curwininfo.category ==# 'subwin' && curwininfo.supwin !=# srcwinid
                let dstwinid = curwininfo.supwin
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
    endfor
endfunction

" Move the cursor to the supwin on the left
function! WinGoLeft(count)
    call s:GoInDirection(a:count, 'h')
endfunction

" Move the cursor to the supwin below
function! WinGoDown(count)
    call s:GoInDirection(a:count, 'j')
endfunction

" Move the cursor to the supwin above
function! WinGoUp(count)
    call s:GoInDirection(a:count, 'k')
endfunction

" Move the cursor to the supwin to the right
function! WinGoRight(count)
    call s:GoInDirection(a:count, 'l')
endfunction

" Run a command in every supwin
function! SupwinDo(command, range)
    let info = WinCommonGetCursorPosition()
        for supwinid in WinModelSupwinIds()
            call WinGotoSupwin(supwinid)
            execute a:range . a:command
        endfor
    call WinCommonRestoreCursorPosition(info)
endfunction

function! s:ResizeCurrentSupwin(count, vertical, horizontal)
    let cmdcount = a:count
    if a:count ==# 0
        let cmdcount = ''
    endif
    let info = WinCommonGetCursorPosition()
        if info.win.category ==# 'uberwin'
            return
        endif

        if info.win.category ==# 'subwin'
           let toresize = {'category':'supwin','id':info.win.supwin}
        elseif info.win.category ==# 'supwin'
            let toresize = info.win
        else
            return
        endif

        let zoomedgrouptypenames = []
        for supwinid in WinModelSupwinIds()
            if supwinid ==# toresize.id
                let zoomedgrouptypenames = WinCommonCloseSubwinsWithHigherPriority(
               \    toresize.id,
               \    -1
               \)
                continue
            endif
            for grouptypename in WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
                call WinHideSubwinGroup(supwinid, grouptypename)
            endfor
        endfor

        call WinStateMoveCursorToWinid(toresize.id)
        if a:horizontal
           call WinCommonDoWithoutUberwins(toresize, function('WinStateWincmd'), [cmdcount, '|'])
        endif
        if a:vertical
            call WinCommonDoWithoutUberwins(toresize, function('WinStateWincmd'), [cmdcount, '_'])
        endif
        call WinCommonReopenSubwins(toresize.id, zoomedgrouptypenames)

    call WinCommonRestoreCursorPosition(info)
endfunction

function! WinResizeCurrentSupwinHorizontal(count)
    call s:ResizeCurrentSupwin(a:count, 1, 0)
endfunction

function! WinResizeCurrentSupwinVertical(count)
    call s:ResizeCurrentSupwin(a:count, 0, 1)
endfunction

function! WinResizeCurrentSupwin(count)
    call s:ResizeCurrentSupwin(a:count, 1, 1)
endfunction
