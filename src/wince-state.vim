" Wince State
" See wince.vim
" Essentially, this file's contents act as a wrapper over the Vim's native
" window commands. The rest of the Wince core can only run those commands via
" this wrapper. Any algorithms that make frequent use of the native window
" commands are implemented at this level.
let s:Log = jer_log#LogFunctions('wince-state')

" Just for fun - lots of extra redrawing
if !exists('g:wince_extra_redraw')
    call s:Log.CFG('wince_extra_redraw initially false')
    let g:wince_extra_redraw = 0
endif
function! s:MaybeRedraw()
    call s:Log.DBG('MaybeRedraw')
    if g:wince_extra_redraw
        call s:Log.DBG('Redraw')
        redraw
    endif
endfunction

" General Getters
function! WinceStateGetTabCount()
    call s:Log.DBG('WinceStateGetTabCount')
    return tabpagenr('$')
endfunction
function! WinceStateGetTabnr()
    call s:Log.DBG('WinceStateGetTabnr')
    return tabpagenr()
endfunction

function! WinceStateGetWinidsByCurrentTab()
    call s:Log.DBG('WinceStateGetWinidsByCurrentTab')
    let winids = []
    for winnr in range(1, winnr('$'))
        call add(winids, jer_win#getid(winnr))
    endfor
    call s:Log.DBG('Winids: ', winids)
    return winids
endfunction

function! WinceStateWinExists(winid)
    call s:Log.DBG('WinceStateWinExists ', a:winid)
    let winexists = jer_win#id2win(a:winid) != 0
    if winexists
        call s:Log.DBG('Window exists with winid ', a:winid)
    else
        call s:Log.DBG('No window with winid ', a:winid)
    endif
    return winexists
endfunction
function! WinceStateAssertWinExists(winid)
    call s:Log.DBG('WinceStateAssertWinExists ', a:winid)
    if !WinceStateWinExists(a:winid)
        throw 'no window with winid ' . a:winid
    endif
endfunction

function! WinceStateGetWinnrByWinid(winid)
    call s:Log.DBG('WinceStateGetWinnrByWinid ', a:winid)
    call WinceStateAssertWinExists(a:winid)
    let winnr = jer_win#id2win(a:winid)
    call s:Log.DBG('Winnr is ', winnr, ' for winid ', a:winid)
    return winnr
endfunction

function! WinceStateGetWinidByWinnr(winnr)
    call s:Log.DBG('WinceStateGetWinidByWinnr ', a:winnr)
    let winid = jer_win#getid(a:winnr)
    call WinceStateAssertWinExists(winid)
    call s:Log.DBG('Winid is ', winid, ' for winnr ', a:winnr)
    return winid
endfunction

function! WinceStateGetBufnrByWinid(winid)
    call s:Log.DBG('WinceStateGetBufnrByWinid ', a:winid)
    call WinceStateAssertWinExists(a:winid)
    let bufnr = winbufnr(a:winid)
    call s:Log.DBG('Bufnr is ', bufnr, ' for winid ', a:winid)
    return bufnr
endfunction

function! WinceStateWinIsTerminal(winid)
    call s:Log.DBG('WinceStateWinIsTerminal ', a:winid)
    let isterm = WinceStateWinExists(a:winid) && getwinvar(jer_win#id2win(a:winid), '&buftype') ==# 'terminal'
    if isterm
        call s:Log.DBG('Window ', a:winid, ' is a terminal window')
    else
        call s:Log.DBG('Window ', a:winid, ' is not a terminal window')
    endif
    return isterm
endfunction

function! WinceStateGetWinDimensions(winid)
    call s:Log.DBG('WinceStateGetWinDimensions ', a:winid)
    call WinceStateAssertWinExists(a:winid)
    let dims = {
   \    'nr': jer_win#id2win(a:winid),
   \    'w': winwidth(a:winid),
   \    'h': winheight(a:winid)
   \}
    call s:Log.DBG('Dimensions of window ', a:winid, ': ', dims)
    return dims
endfunction

function! WinceStateGetWinDimensionsList(winids)
    call s:Log.DBG('WinceStateGetWinDimensionsList ', a:winids)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinceStateGetWinDimensions(winid))
    endfor
    call s:Log.DBG('Dimensions of windows ', a:winids, ': ', dim)
    return dim
endfunction

function! WinceStateGetWinRelativeDimensions(winid, offset)
    call s:Log.DBG('WinceStateGetWinRelativeDimensions ', a:winid, ' ', a:offset)
    call WinceStateAssertWinExists(a:winid)
    if type(a:offset) != v:t_number
        throw 'offset is not a number'
    endif
    let dims = {
   \    'relnr': jer_win#id2win(a:winid) - a:offset,
   \    'w': winwidth(a:winid),
   \    'h': winheight(a:winid)
   \}
    call s:Log.DBG('Relative dimensions of window ', a:winid, 'with offset ', a:offset, ': ', dims)
    return dims
endfunction

function! WinceStateGetWinRelativeDimensionsList(winids, offset)
    call s:Log.DBG('WinceStateGetWinRelativeDimensionsList ', a:winids, ' ', a:offset)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinceStateGetWinRelativeDimensions(winid, a:offset))
    endfor
    call s:Log.DBG('Relative dimensions of windows ', a:winids, 'with offset ', a:offset, ': ', dim)
    return dim
endfunction

" Tab movement
function! WinceStateGotoTab(tabnr)
    call s:Log.INF('WinceStateGotoTab ', a:tabnr)
    execute a:tabnr . 'tabnext'
    call s:MaybeRedraw()
endfunction

" Cursor position preserve/restore
function! WinceStateGetCursorWinId()
    call s:Log.DBG('WinceStateGetCursorWinId')
    let winid = jer_win#getid()
    call s:Log.DBG('Winid of current window: ', winid)
    return winid
endfunction!
function! WinceStateGetCursorPosition()
    call s:Log.DBG('WinceStateGetCursorPosition')
    let winview = winsaveview()
    call s:Log.DBG('Saved cursor position: ', winview)
    return winview
endfunction
function! WinceStateRestoreCursorPosition(pos)
    call s:Log.DBG('WinceStateRestoreCursorPosition ', a:pos)
    call winrestview(a:pos)
endfunction

" Scroll position preserve/restore
function! WinceStatePreserveScrollPosition()
    call s:Log.DBG('WinceStatePreserveScrollPosition')
    let topline = winsaveview().topline
    call s:Log.DBG('Scroll position preserved: ', topline)
    return topline
endfunction
function! WinceStateRestoreScrollPosition(topline)
    call s:Log.DBG('WinceStateRestoreScrollPosition ', a:topline)
    let newview = winsaveview()
    let newview.topline = a:topline
    call WinceStateRestoreCursorPosition(newview)
endfunction

" Window shielding
function! WinceStateShieldWindow(winid, onlyscroll)
    call s:Log.INF('WinceStateShieldWindow ', a:winid, ' ', a:onlyscroll)
    let preshield = {
   \    'w': getwinvar(jer_win#id2win(a:winid), '&winfixwidth'),
   \    'h': getwinvar(jer_win#id2win(a:winid), '&winfixheight'),
   \    'sb': getwinvar(jer_win#id2win(a:winid), '&scrollbind'),
   \    'cb': getwinvar(jer_win#id2win(a:winid), '&cursorbind')
   \}
    call s:Log.VRB('Pre-shield fixedness for window ', a:winid, ': ', preshield)
    if !a:onlyscroll
        "call setwinvar(jer_win#id2win(a:winid), '&winfixwidth', 1)
        "call setwinvar(jer_win#id2win(a:winid), '&winfixheight', 1)
    endif
    call setwinvar(jer_win#id2win(a:winid), '&scrollbind', 1)
    call setwinvar(jer_win#id2win(a:winid), '&cursorbind', 0)
    return preshield
endfunction

function! WinceStateUnshieldWindow(winid, preshield)
    call s:Log.INF('WinceStateUnshieldWindow ', a:winid, ' ', a:preshield)
    "call setwinvar(jer_win#id2win(a:winid), '&winfixwidth', a:preshield.w)
    "call setwinvar(jer_win#id2win(a:winid), '&winfixheight', a:preshield.h)
    call setwinvar(jer_win#id2win(a:winid), '&scrollbind', a:preshield.sb)
    call setwinvar(jer_win#id2win(a:winid), '&cursorbind', a:preshield.cb)
endfunction

" Generic Ctrl-W commands
function! WinceStateWincmd(count, cmd, usemode)
    call s:Log.INF('WinceStateWincmd ', a:count, ' ', a:cmd, ' ', a:usemode)
    if type(a:usemode) ==# v:t_dict && !empty(a:usemode)
        noautocmd call jer_mode#ForcePreserve(a:usemode)
        noautocmd call jer_mode#Restore()
    endif
    
    execute a:count . 'wincmd ' . a:cmd
    noautocmd execute "normal \<plug>JerDetectMode"

    call s:MaybeRedraw()

    return jer_mode#Retrieve()
endfunction
function! WinceStateSilentWincmd(count, cmd, usemode)
    call s:Log.INF('WinceStateSilentWincmd ', a:count, ' ', a:cmd, ' ', a:usemode)
    if type(a:usemode) ==# v:t_dict && empty(a:usemode)
        noautocmd call jer_mode#ForcePreserve(a:usemode)
        noautocmd call jer_mode#Restore()
    endif
    
    noautocmd execute a:count . 'wincmd ' . a:cmd
    noautocmd "normal \<plug>JerDetectMode"
    
    call s:MaybeRedraw()

    return jer_mode#Retrieve()
endfunction

" Navigation
function! WinceStateMoveCursorToWinid(winid)
    call s:Log.DBG('WinceStateMoveCursorToWinid ', a:winid)
    call WinceStateAssertWinExists(a:winid)
    call jer_win#gotoid(a:winid)
endfunction

function! WinceStateMoveCursorToWinidSilently(winid)
    call s:Log.DBG('WinceStateMoveCursorToWinidSilently ', a:winid)
    call WinceStateAssertWinExists(a:winid)
    noautocmd silent call jer_win#gotoid(a:winid)
endfunction

function! WinceStateMoveCursorToWinidAndUpdateMode(winid, startmode)
    call s:Log.DBG('WinceStateMoveCursorToWinidAndUpdateMode ', a:winid, ' ', a:startmode)
    let winnr = jer_win#id2win(a:winid)
    if winnr <=# 0 || winnr ># winnr('$')
        return
    endif
    return WinceStateWincmd(winnr, 'w', a:startmode)
endfunction

" Open windows using the toOpen function from a group type and return the
" resulting window IDs. Don't allow any of the new windows to have location
" lists.
function! WinceStateOpenUberwinsByGroupType(grouptype)
    call s:Log.INF('WinceStateOpenUberwinsByGroupType ', a:grouptype.name)
    if !has_key(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let ToOpen = a:grouptype.toOpen
    if type(ToOpen) != v:t_func
        throw 'Given group type has nonfunc toOpen member'
    endif

    let winids = ToOpen()
    call s:Log.INF('Opened uberwin group ', a:grouptype.name, ' with winids ', winids)

    for idx in range(0, len(winids) - 1)
        if a:grouptype.widths[idx] >= 0
            call s:Log.VRB('Fixed width for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixwidth', 1)
        else
            call s:Log.VRB('Free width for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixwidth', 0)
        endif

        if a:grouptype.heights[idx] >= 0
            call s:Log.VRB('Fixed height for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixheight', 1)
        else
            call s:Log.VRB('Free height for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixheight', 0)
        endif

        call s:Log.VRB('Set statusline for uberwin ', a:grouptype.name, ':', a:grouptype.typenames[idx], ' to ', a:grouptype.statuslines[idx])
        call setwinvar(jer_win#id2win(winids[idx]), '&statusline', a:grouptype.statuslines[idx])

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists... Unless the window is itself a location window, in which
        " case of course it should keep its location list. Unfortunately this
        " constitutes special support for the lochelp subwin group.
        if !a:grouptype.canHaveLoclist[idx]
            call setloclist(jer_win#id2win(winids[idx]), [])
        endif
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" Close uberwins using the toClose function from a group type
function! WinceStateCloseUberwinsByGroupType(grouptype)
    call s:Log.INF('WinceStateCloseUberwinsByGroupType ', a:grouptype.name)
    if !has_key(a:grouptype, 'toClose')
        throw 'Given group type has no toClose member'
    endif
    
    let ToClose = a:grouptype.toClose
    if type(ToClose) != v:t_func
        throw 'Given group type has nonfunc toClose member'
    endif

    call ToClose()

    call s:MaybeRedraw()
endfunction

" From a given window, open windows using the toOpen function from a group type and
" return the resulting window IDs. Don't allow any of the new windows to have
" location lists.
function! WinceStateOpenSubwinsByGroupType(supwinid, grouptype)
    call s:Log.INF('WinceStateOpenSubwinsByGroupType ', a:supwinid, ':', a:grouptype.name)
    if !has_key(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let ToOpen = a:grouptype.toOpen
    if type(ToOpen) != v:t_func
        throw 'Given group type has nonfunc toOpen member'
    endif

    if !jer_win#id2win(a:supwinid)
        throw 'Given supwinid ' . a:supwinid . ' does not exist'
    endif

    call jer_win#gotoid(a:supwinid)

    let top = winsaveview().topline
    let winids = ToOpen()
    let view = winsaveview()
    let view.topline = top
    call winrestview(view)

    call s:Log.INF('Opened subwin group ', a:supwinid, ':', a:grouptype.name, ' with winids ', winids)

    for idx in range(0, len(winids) - 1)
        if a:grouptype.widths[idx] >= 0
            call s:Log.VRB('Fixed width for subwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixwidth', 1)
        else
            call s:Log.VRB('Free width for subwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixwidth', 0)
        endif
        if a:grouptype.heights[idx] >= 0
            call s:Log.VRB('Fixed height for subwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixheight', 1)
        else
            call s:Log.VRB('Free height for subwin ', a:grouptype.typenames[idx])
            call setwinvar(jer_win#id2win(winids[idx]), '&winfixheight', 0)
        endif

        call s:Log.VRB('Set statusline for subwin ', a:supwinid, ':', a:grouptype.name, ':', a:grouptype.typenames[idx], ' to ', a:grouptype.statuslines[idx])
        call setwinvar(jer_win#id2win(winids[idx]), '&statusline', a:grouptype.statuslines[idx])

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists... Unless the window is itself a location window, in which
        " case of course it should keep its location list. Unfortunately this
        " constitutes special support for the loclist subwin group.
        if !a:grouptype.canHaveLoclist[idx]
            call setloclist(jer_win#id2win(winids[idx]), [])
        endif
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" Close subwins of a give supwin using the toClose function from a group type
function! WinceStateCloseSubwinsByGroupType(supwinid, grouptype)
    call s:Log.INF('WinceStateCloseSubwinsByGroupType ', a:supwinid, ':', a:grouptype.name)
    if !has_key(a:grouptype, 'toClose')
        throw 'Given group type has no toClose member'
    endif
    
    let ToClose = a:grouptype.toClose
    if type(ToClose) != v:t_func
        throw 'Given group type has nonfunc toClose member'
    endif

    if !jer_win#id2win(a:supwinid)
        throw 'Given supwinid ' . a:supwinid . ' does not exist'
    endif

    call jer_win#gotoid(a:supwinid)

    let top = winsaveview().topline
    call ToClose()
    let view = winsaveview()
    let view.topline = top
    call winrestview(view)

    call s:MaybeRedraw()
endfunction

function! s:PreserveSigns(winid)
    call s:Log.VRB('PreserveSigns ', a:winid)
    let preserved = execute('sign place buffer=' . winbufnr(a:winid))
    call s:Log.DBG('Preserved signs: ', preserved)
    return preserved
endfunction

function! s:RestoreSigns(winid, signs)
    call s:Log.VRB('RestoreSigns ', a:winid, ' ...')
    call s:Log.VRB('Preserved signs: ', a:signs)
    for signstr in split(a:signs, '\n')
        if signstr =~# '^\s*line=\d*\s*id=\d*\s*name=.*$'
            let signid = substitute( signstr, '^.*id=\(\d*\).*$', '\1', '')
            let signname = substitute( signstr, '^.*name=\(.*\).*$', '\1', '')
            let signline = substitute( signstr, '^.*line=\(\d*\).*$', '\1', '')
            let cmd =  'sign place ' . signid .
           \           ' line=' . signline .
           \           ' name=' . signname .
           \           ' buffer=' . winbufnr(a:winid)
            call s:Log.DBG(cmd)
            execute cmd
        endif
    endfor
endfunction

function! s:PreserveManualFolds()
    call s:Log.VRB('PreserveManualFolds')
    " Output
    let folds = {}

    " Step 1: Find folds
    " Stack contains the starting lines of folds whose ending lines have not
    " yet been reached, indexed by their foldlevels. Element 0 has a dummy 0
    " in it because a foldlevel of 0 means the line isn't folded
    let foldstack = [0]

    " Foldlevel of the previous line
    let prevfl = 0
    
    " Traverse every line in the buffer
    for linenr in range(0, line('$') + 1, 1)
        " Pretend there are non-folded lines before and after the real ones
        if linenr <=# 0 || linenr >= line('$') + 1
            let foldlevel = 0
        else
            let foldlevel = foldlevel(linenr)
        endif
        call s:Log.VRB('Line ', linenr, ' has foldlevel ', foldlevel)

        if foldlevel <# 0
            throw 'Negative foldlevel'
        endif

        " If the foldlevel has increased since the previous line, start new
        " folds at the current line - one for each +1 on the foldlevel
        if foldlevel ># prevfl
            for newfl in range(prevfl + 1, foldlevel, 1)
                call s:Log.VRB('Start fold at foldlevel ', newfl)
                call add(foldstack, linenr)
            endfor

        " If the foldlevel has decreased since the previous line, use that
        " line to finish all folds that started since the foldlevel was as
        " small as it is now. Also do this at the end of the buffer, where all
        " folds need to end
        elseif foldlevel <# prevfl
            for biggerfl in range(prevfl, foldlevel + 1, -1)
                if !has_key(folds, biggerfl)
                    let folds[biggerfl] = []
                endif
                call s:Log.VRB('End fold at foldlevel ', biggerfl)
                call add(folds[biggerfl], {
               \    'start': remove(foldstack, biggerfl),
               \    'end': linenr - 1
               \})
            endfor

        " If the foldlevel hasn't changed since the previous line, continue
        " the current fold
        endif

        let prevfl = foldlevel
    endfor

    " Step 2: Determine which folds are closed
    " Vim's fold API cannot see inside closed folds, so we need to open all
    " closed folds after noticing they are closed
    let foldlevels = sort(copy(keys(folds)), 'n')
    for foldlevel in foldlevels
        call s:Log.VRB('Examine folds with foldlevel ', foldlevel)
        for afold in folds[foldlevel]
            " If a fold contains any line where foldclosed and foldclosedend
            " don't match with the start and end of the fold, then that fold
            " is open
            let afold.closed = 1
            for linenr in range(afold.start, afold.end, 1)
                if foldclosed(linenr) !=# afold.start ||
               \   foldclosedend(linenr) !=# afold.end
                    call s:Log.VRB('Fold ', afold, ' is closed')
                    let afold.closed = 0
                    break
                endif
            endfor

            " If a fold is closed, open it so that later iterations with
            " higher foldlevels can inspect other folds inside
            if afold.closed
                execute afold.start . 'foldopen'
            endif
        endfor
    endfor
    
    " Delete all folds so that if the call to s:RestoreFolds happens in the same
    " window, it'll start with a clean slate
    call s:Log.VRB('Deleting all folds')
    normal! zE

    let retdict = {'explen': line('$'), 'folds': folds}
    call s:Log.VRB('Preserved manual folds: ', retdict)
    return retdict
endfunction

function! s:PreserveFolds()
    call s:Log.VRB('PreserveFolds')
    if &foldmethod ==# 'manual'
        call s:Log.VRB('Foldmethod is manual')
        return {'method':'manual','data':s:PreserveManualFolds()}
    elseif &foldmethod ==# 'indent'
        call s:Log.VRB('Foldmethod is indent')
        return {'method':'indent','data':''}
    elseif &foldmethod ==# 'expr'
        call s:Log.VRB('Foldmethod is expr with foldexpr: ', &foldexpr)
        return {'method':'expr','data':&foldexpr}
    elseif &foldmethod ==# 'marker'
        call s:Log.VRB('Foldmethod is marker')
        return {'method':'marker','data':''}
    elseif &foldmethod ==# 'syntax'
        call s:Log.VRB('Foldmethod is syntax')
        return {'method':'syntax','data':''}
    elseif &foldmethos ==# 'diff'
        call s:Log.VRB('Foldmethod is diff')
        return {'method':'diff','data':''}
    else
        throw 'Unknown foldmethod ' . &foldmethod
    endif
endfunction

function! s:RestoreManualFolds(explen, folds)
    call s:Log.VRB('RestoreManualFolds ', a:explen, ' ', a:folds)
    if line('$') <# a:explen
        throw 'Buffer contents have shrunk since folds were preserved'
    endif
    for linenr in range(1, line('$'), 1)
        if foldlevel(linenr) !=# 0
            throw 'Folds already exist'
        endif
    endfor

    for foldlevel in reverse(sort(copy(keys(a:folds)), 'n'))
        for afold in a:folds[foldlevel]
            call s:Log.VRB('Applying fold ', afold)
            execute afold.start . ',' . afold.end . 'fold'
            if !afold.closed
                execute afold.start . 'foldopen'
            endif
        endfor
    endfor
endfunction

function! s:RestoreFolds(method, data)
    call s:Log.INF('RestoreFolds ', a:method, ' ', a:data)
    if a:method ==# 'manual'
        let &foldmethod = 'manual'
        call s:RestoreManualFolds(a:data.explen, a:data.folds)
    elseif a:method ==# 'indent'
        let &foldmethod = 'indent'
    elseif a:method ==# 'expr'
        let &foldmethod = 'expr'
        let &foldexpr = a:data
    elseif a:method ==# 'marker'
        let &foldmethod = 'marker'
    elseif a:method ==# 'syntax'
        let &foldmethod = 'syntax'
    elseif a:method ==# 'diff'
        let &foldmethod = 'diff'
    else
        throw 'Unknown foldmethod ' . &foldmethod
    endif
endfunction

function! WinceStateAfterimageWindow(winid)
    call s:Log.DBG('WinceStateAfterimageWindow ', a:winid)
    " Silent movement (noautocmd) is used here because we want to preserve the
    " state of the window exactly as it was when the function was first
    " called, and autocmds may fire on jer_win#gotoid that change the state
    call WinceStateMoveCursorToWinidSilently(a:winid)

    " Preserve cursor and scroll position
    let view = winsaveview()

    " Preserve some buffer-local options
    let bufsyn = &l:syntax
    let bufsynmc = &l:synmaxcol
    let bufspll = &l:spelllang
    let bufsplc = &l:spellcapcheck
    let bufts = &l:tabstop
    " These options are documented as window-local, but behave in buffer-local
    " ways
    let bufw = &l:wrap
    let bufl = &l:list
    let bufsl = &l:statusline
    let bufcc = &l:colorcolumn
    
    call s:Log.VRB(' syntax: ', bufsyn, ', synmaxcol: ', bufsynmc, ', spelllang: ', bufspll, ', spellcapcheck: ', bufsplc, ', tabstop: ', bufts, ', wrap: ', bufw, ', list: ', bufl, ', statusline: ', bufsl, ', colorcolumn: ', bufcc)

    " Preserve folds
    try
        let folds = s:PreserveFolds()
    catch /.*/
        call s:Log.WRN('Failed to preserve folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        let folds = {'method':'manual','data':{}}
    endtry
    call s:MaybeRedraw()

    " Preserve signs, but also unplace them so that they don't show up if the
    " real buffer is reused for another supwin
    let signs = s:PreserveSigns(a:winid)
    for signstr in split(signs, '\n')
        if signstr =~# '^\s*line=\d*\s*id=\d*\s*name=.*$'
            let signid = substitute( signstr, '^.*id=\(\d*\).*$', '\1', '')
            call s:Log.VRB('Unplace sign ', signid)
            execute 'sign unplace ' . signid
        endif
    endfor
    call s:MaybeRedraw()

    " Preserve buffer contents
    let bufcontents = getline(0, '$')
    call s:Log.VRB('Buffer contents: ', bufcontents)

    " Switch to a new hidden scratch buffer. This will be the afterimage buffer
    " noautocmd is used here because undotree has autocmds that fire when you
    " enew from the tree window and close the diff window
    noautocmd enew!
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    call s:MaybeRedraw()

    " Restore buffer contents
    call setline(1, bufcontents)
    call s:MaybeRedraw()

    " Restore signs
    call s:RestoreSigns(a:winid, signs)
    call s:MaybeRedraw()

    " Restore folds
    try
        call s:RestoreFolds(folds.method, folds.data)
    catch /.*/
        call s:Log.WRN('Failed to restore folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
    endtry
    call s:MaybeRedraw()

    " Restore options
    let &l:syntax = bufsyn   
    let &l:synmaxcol = bufsynmc 
    let &l:spelllang = bufspll  
    let &l:spellcapcheck = bufsplc  
    let &l:tabstop = bufts    
    let &l:wrap = bufw     
    let &l:list = bufl     
    let &l:statusline = bufsl    
    let &l:colorcolumn = bufcc    
    call s:MaybeRedraw()

    " Restore cursor and scroll position
    call winrestview(view)
    call s:MaybeRedraw()

    " Return afterimage buffer ID
    let aibuf = winbufnr('')
    call s:Log.INF('Afterimaged window ', a:winid, ' with buffer ', aibuf)
    return aibuf
endfunction

function! WinceStateCloseWindow(winid, belowright)
    call s:Log.INF('WinceStateCloseWindow ', a:winid, ' ', a:belowright)
    call WinceStateAssertWinExists(a:winid)

    " :close fails if called on the last window. Explicitly exit Vim if
    " there's only one window left.
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        call s:Log.INF('Window ', a:winid, ' is the last window. Exiting Vim.')
        quit
    endif
    
    let winnr = jer_win#id2win(a:winid)

    let oldsr = &splitright
    let oldsb = &splitbelow
    let &splitright = a:belowright
    let &splitbelow = a:belowright
    noautocmd execute winnr . 'close'
    let &splitright = oldsr
    let &splitbelow = oldsb

    call s:MaybeRedraw()
endfunction

let s:preservedwinopts = [
\    'scroll',
\    'linebreak',
\    'breakindent',
\    'breakindentopt',
\    'list',
\    'number',
\    'relativenumber',
\    'numberwidth',
\    'conceallevel',
\    'concealcursor',
\    'cursorcolumn',
\    'cursorline',
\    'colorcolumn',
\    'spell',
\    'scrollbind',
\    'cursorbind',
\    'termwinsize',
\    'termwinkey',
\    'termwinscroll',
\    'foldenable',
\    'foldlevel',
\    'foldcolumn',
\    'foldtext',
\    'foldminlines',
\    'foldexpr',
\    'foldignore',
\    'foldmarker',
\    'foldnestmax',
\    'diff',
\    'rightleft',
\    'rightleftcmd',
\    'arabic',
\    'iminsert',
\    'imsearch',
\    'signcolumn'
\]

" Preserve/Restore for individual windows
function! WinceStatePreCloseAndReopen(winid)
    call s:Log.INF('WinceStatePreCloseAndReopen ', a:winid)
    call WinceStateMoveCursorToWinidSilently(a:winid)
    let retdict = {}

    " Preserve cursor position
    let retdict.view = winsaveview()
    call s:Log.VRB(' view: ', retdict.view)

    " Preserve options
    let retdict.opts = {}
    for optname in s:preservedwinopts
        let optval = eval('&l:' . optname)
        call s:Log.VRB('Preserve ', optname, ': ', optval)
        let retdict.opts[optname] = optval
    endfor

    " Preserve folds
    try
        let fold = s:PreserveFolds()
    catch /.*/
        call s:Log.WRN('Failed to preserve folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        let fold = {'method':'manual','data':{}}
    endtry
    let retdict.fold = fold
    call s:MaybeRedraw()

    " Preserve signs
    let retdict.sign = s:PreserveSigns(a:winid)
    call s:MaybeRedraw()

    return retdict
endfunction

function! WinceStatePostCloseAndReopen(winid, preserved)
    call s:Log.INF('WinceStatePostCloseAndReopen ', a:winid, '...')
    call s:Log.VRB(a:preserved)
    call WinceStateMoveCursorToWinidSilently(a:winid)

    " Restore signs
    call s:RestoreSigns(a:winid, a:preserved.sign)
    call s:MaybeRedraw()

    " Restore folds
    try
        call s:RestoreFolds(a:preserved.fold.method, a:preserved.fold.data)
    catch /.*/
        call s:Log.WRN('Failed to restore folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
    endtry
    call s:MaybeRedraw()

    " Restore options
    for optname in keys(a:preserved.opts)
        let optval = a:preserved.opts[optname]
        execute 'let &l:' . optname . ' = ' . string(optval)
    endfor
  
    " Restore cursor and scroll position
    call winrestview(a:preserved.view)
    call s:MaybeRedraw()
endfunction

function! WinceStateResizeHorizontal(winid, width, preferleftdivider)
    call s:Log.INF('WinceStateResizeHorizontal ', a:winid, ' ', a:width, ' ', a:preferleftdivider)
    call WinceStateMoveCursorToWinidSilently(a:winid)
    let wasfixed = &winfixwidth
    let &winfixwidth = 0
    if !a:preferleftdivider
        call WinceStateSilentWincmd(a:width, '|', 0)
        let &winfixwidth = wasfixed
        return
    endif
    call WinceStateSilentWincmd('','h', 0)
    if jer_win#getid() ==# a:winid
        call WinceStateResizeHorizontal(a:winid, a:width, 0)
        let &winfixwidth = wasfixed
        return
    endif
    if &winfixwidth
        call WinceStateResizeHorizontal(a:winid, a:width, 0)
        return
    endif
    let otherwidth = winwidth(0)
    let oldwidth = winwidth(jer_win#id2win(a:winid))
    let newwidth = otherwidth + oldwidth - a:width
    call WinceStateSilentWincmd(newwidth, '|', 0)
endfunction

function! WinceStateResizeVertical(winid, height, prefertopdivider)
    call s:Log.INF('WinceStateResizeVertical ', a:winid, ' ', a:height, ' ', a:prefertopdivider)
    call WinceStateMoveCursorToWinidSilently(a:winid)
    let wasfixed = &winfixheight
    let &winfixheight = 0
    if !a:prefertopdivider
        call WinceStateSilentWincmd(a:height, '_', 0)
        let &winfixheight = wasfixed
        return
    endif
    call WinceStateSilentWincmd('','k', 0)
    if jer_win#getid() ==# a:winid
        call WinceStateResizeVertical(a:winid, a:height, 0)
        let &winfixheight = wasfixed
        return
    endif
    if &winfixheight
        call WinceStateResizeVertical(a:winid, a:height, 0)
        return
    endif
    let otherheight = winheight(0)
    let oldheight = winheight(jer_win#id2win(a:winid))
    let newheight = otherheight + oldheight - a:height
    call WinceStateSilentWincmd(newheight, '_', 0)
endfunction

function! WinceStateFixednessByWinid(winid)
    call s:Log.DBG('WinceStateFixednessByWinid ', a:winid)
    call WinceStateMoveCursorToWinidSilently(a:winid)
    let fixedness = {'w':&winfixwidth,'h':&winfixheight}
    call s:Log.VRB(fixedness)
    return fixedness
endfunction

function! WinceStateUnfixDimensions(winid)
    call s:Log.INF('WinceStateUnfixDimensions ', a:winid)
    let preunfix = WinceStateFixednessByWinid(a:winid)
    " WinceStateFixednessByWinid moves to the window
    let &winfixwidth = 0
    let &winfixheight = 0
    return preunfix
endfunction

function! WinceStateRefixDimensions(winid, preunfix)
    call s:Log.INF('WinceStateRefixDimensions ', a:winid, ' ', a:preunfix)
    call WinceStateMoveCursorToWinidSilently(a:winid)
    let &winfixwidth = a:preunfix.w
    let &winfixheight = a:preunfix.h
endfunction

