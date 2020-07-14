" Window state manipulation functions
" See window.vim

" Just for fun - lots of extra redrawing
if !exists('g:windraw')
    call EchomLog('window-state', 'config', 'windraw initially false')
    let g:windraw = 0
endif
function! s:MaybeRedraw()
    call EchomLog('window-state', 'debug', 'MaybeRedraw')
    if g:windraw
        call EchomLog('window-state', 'debug', 'Redraw')
        redraw
    endif
endfunction

" General Getters
function! WinStateGetWinidsByCurrentTab()
    call EchomLog('window-state', 'debug', 'WinStateGetWinidsByCurrentTab')
    let winids = []
    for winnr in range(1, winnr('$'))
        call add(winids, win_getid(winnr))
    endfor
    call EchomLog('window-state', 'debug', 'Winids: ', winids)
    return winids
endfunction

function! WinStateWinExists(winid)
    call EchomLog('window-state', 'debug', 'WinStateWinExists ', a:winid)
    let winexists = win_id2win(a:winid) != 0
    if winexists
        call EchomLog('window-state', 'debug', 'Window exists with winid ', a:winid)
    else
        call EchomLog('window-state', 'debug', 'No window with winid ', a:winid)
    endif
    return winexists
endfunction
function! WinStateAssertWinExists(winid)
    call EchomLog('window-state', 'debug', 'WinStateAssertWinExists ', a:winid)
    if !WinStateWinExists(a:winid)
        throw 'no window with winid ' . a:winid
    endif
endfunction

function! WinStateGetWinnrByWinid(winid)
    call EchomLog('window-state', 'debug', 'WinStateGetWinnrByWinid ', a:winid)
    call WinStateAssertWinExists(a:winid)
    let winnr = win_id2win(a:winid)
    call EchomLog('window-state', 'debug', 'Winnr is ', winnr, ' for winid ', a:winid)
    return winnr
endfunction

function! WinStateGetWinidByWinnr(winnr)
    call EchomLog('window-state', 'debug', 'WinStateGetWinidByWinnr ', a:winnr)
    let winid = win_getid(a:winnr)
    call WinStateAssertWinExists(winid)
    call EchomLog('window-state', 'debug', 'Winid is ', winid, ' for winnr ', a:winnr)
    return winid
endfunction

function! WinStateGetBufnrByWinid(winid)
    call EchomLog('window-state', 'debug', 'WinStateGetBufnrByWinid ', a:winid)
    call WinStateAssertWinExists(a:winid)
    let bufnr = winbufnr(a:winid)
    call EchomLog('window-state', 'debug', 'Bufnr is ', bufnr, ' for winid ', a:winid)
    return bufnr
endfunction

function! WinStateWinIsTerminal(winid)
    call EchomLog('window-state', 'debug', 'WinStateWinIsTerminal ', a:winid)
    let isterm = WinStateWinExists(a:winid) && getwinvar(a:winid, '&buftype') ==# 'terminal'
    if isterm
        call EchomLog('window-state', 'debug', 'Window ', a:winid, ' is a terminal window')
    else
        call EchomLog('window-state', 'debug', 'Window ', a:winid, ' is not a terminal window')
    endif
    return isterm
endfunction

function! WinStateGetWinDimensions(winid)
    call EchomLog('window-state', 'debug', 'WinStateGetWinDimensions ', a:winid)
    call WinStateAssertWinExists(a:winid)
    let dims = {
   \    'nr': win_id2win(a:winid),
   \    'w': winwidth(a:winid),
   \    'h': winheight(a:winid)
   \}
    call EchomLog('window-state', 'debug', 'Dimensions of window ', a:winid, ': ', dims)
    return dims
endfunction

function! WinStateGetWinDimensionsList(winids)
    call EchomLog('window-state', 'debug', 'WinStateGetWinDimensionsList ', a:winids)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinStateGetWinDimensions(winid))
    endfor
    call EchomLog('window-state', 'debug', 'Dimensions of windows ', a:winids, ': ', dim)
    return dim
endfunction

function! WinStateGetWinRelativeDimensions(winid, offset)
    call EchomLog('window-state', 'debug', 'WinStateGetWinRelativeDimensions ', a:winid, ' ', a:offset)
    call WinStateAssertWinExists(a:winid)
    if type(a:offset) != v:t_number
        throw 'offset is not a number'
    endif
    let dims = {
   \    'relnr': win_id2win(a:winid) - a:offset,
   \    'w': winwidth(a:winid),
   \    'h': winheight(a:winid)
   \}
    call EchomLog('window-state', 'debug', 'Relative dimensions of window ', a:winid, 'with offset ', a:offset, ': ', dims)
    return dims
endfunction

function! WinStateGetWinRelativeDimensionsList(winids, offset)
    call EchomLog('window-state', 'debug', 'WinStateGetWinRelativeDimensionsList ', a:winids, ' ', a:offset)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinStateGetWinRelativeDimensions(winid, a:offset))
    endfor
    call EchomLog('window-state', 'debug', 'Relative dimensions of windows ', a:winids, 'with offset ', a:offset, ': ', dim)
    return dim
endfunction

" Cursor position preserve/restore
function! WinStateGetCursorWinId()
    call EchomLog('window-state', 'debug', 'WinStateGetCursorWinId')
    let winid = win_getid()
    call EchomLog('window-state', 'debug', 'Winid of current window: ', winid)
    return winid
endfunction!
function! WinStateGetCursorPosition()
    call EchomLog('window-state', 'debug', 'WinStateGetCursorPosition')
    let winview = winsaveview()
    call EchomLog('window-state', 'debug', 'Saved cursor position: ', winview)
    return winview
endfunction
function! WinStateRestoreCursorPosition(pos)
    call EchomLog('window-state', 'debug', 'WinStateRestoreCursorPosition ', a:pos)
    call winrestview(a:pos)
    call s:MaybeRedraw()
endfunction

" Dimension freezing
function! WinStateFreezeWindowSize(winid)
    call EchomLog('window-state', 'info', 'WinStateFreezeWindowSize ', a:winid)
    let curwinid = win_getid()
    call WinStateMoveCursorToWinidSilently(a:winid)
    try
        let prefreeze = {
       \    'w': &winfixwidth,
       \    'h': &winfixheight,
       \    'top': winsaveview().topline
       \}
        call EchomLog('window-state', 'verbose', 'Pre-freeze fixedness for window ', a:winid, ': ', prefreeze)
        call setwinvar(a:winid, '&winfixwidth', 1)
        call setwinvar(a:winid, '&winfixheight', 1)
    finally
        call WinStateMoveCursorToWinidSilently(curwinid)
    endtry
    return prefreeze
endfunction

function! WinStateThawWindowSize(winid, prefreeze)
    let curwinid = win_getid()
    call WinStateMoveCursorToWinidSilently(a:winid)
    call EchomLog('window-state', 'info', 'WinStateThawWindowSize ', a:winid, ' ', a:prefreeze)
    try
        call setwinvar(a:winid, '&winfixwidth', a:prefreeze.w)
        call setwinvar(a:winid, '&winfixheight', a:prefreeze.h)
        let view = winsaveview()
        let view.topline = a:prefreeze.top
        call winrestview(view)
    finally
        call WinStateMoveCursorToWinidSilently(curwinid)
    endtry
endfunction

" Generic Ctrl-W commands
function! WinStateWincmd(count, cmd)
    call EchomLog('window-state', 'info', 'WinStateWincmd ', a:count, ' ', a:cmd)
    execute a:count . 'wincmd ' . a:cmd
    call s:MaybeRedraw()
endfunction
function! WinStateSilentWincmd(count, cmd)
    call EchomLog('window-state', 'info', 'WinStateSilentWincmd ', a:count, ' ', a:cmd)
    noautocmd execute a:count . 'wincmd ' . a:cmd
    call s:MaybeRedraw()
endfunction

" Navigation
function! WinStateMoveCursorToWinid(winid)
    call EchomLog('window-state', 'debug', 'WinStateMoveCursorToWinid ', a:winid)
    call WinStateAssertWinExists(a:winid)
    call win_gotoid(a:winid)
    call s:MaybeRedraw()
endfunction

function! WinStateMoveCursorToWinidSilently(winid)
    call EchomLog('window-state', 'debug', 'WinStateMoveCursorToWinidSilently ', a:winid)
    call WinStateAssertWinExists(a:winid)
    noautocmd call win_gotoid(a:winid)
    call s:MaybeRedraw()
endfunction

" Open windows using the toOpen function from a group type and return the
" resulting window IDs. Don't allow any of the new windows to have location
" lists.
function! WinStateOpenUberwinsByGroupType(grouptype)
    call EchomLog('window-state', 'info', 'WinStateOpenUberwinsByGroupType ', a:grouptype.name)
    if !has_key(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let ToOpen = a:grouptype.toOpen
    if type(ToOpen) != v:t_func
        throw 'Given group type has nonfunc toOpen member'
    endif

    let winids = ToOpen()
    call EchomLog('window-state', 'info', 'Opened uberwin group ', a:grouptype.name, ' with winids ', winids)

    for idx in range(0, len(winids) - 1)
        if a:grouptype.widths[idx] >= 0
            call EchomLog('window-state', 'verbose', 'Fixed width for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixwidth', 1)
        else
            call EchomLog('window-state', 'verbose', 'Free width for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixwidth', 0)
        endif

        if a:grouptype.heights[idx] >= 0
            call EchomLog('window-state', 'verbose', 'Fixed height for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixheight', 1)
        else
            call EchomLog('window-state', 'verbose', 'Free height for uberwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixheight', 0)
        endif

        call EchomLog('window-state', 'verbose', 'Set statusline for uberwin ', a:grouptype.name, ':', a:grouptype.typenames[idx], ' to ', a:grouptype.statuslines[idx])
        call setwinvar(winids[idx], '&statusline', a:grouptype.statuslines[idx])

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists
        call setloclist(winids[idx], [])
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" Close uberwins using the toClose function from a group type
function! WinStateCloseUberwinsByGroupType(grouptype)
    call EchomLog('window-state', 'info', 'WinStateCloseUberwinsByGroupType ', a:grouptype.name)
    if !has_key(a:grouptype, 'toClose')
        throw 'Given group type has no toClose member'
    endif
    
    let ToClose = a:grouptype.toClose
    if type(ToClose) != v:t_func
        throw 'Given group type has nonfunc toClose member'
    endif

    call call(ToClose, [])
    call s:MaybeRedraw()
endfunction

" From a given window, open windows using the toOpen function from a group type and
" return the resulting window IDs. Don't allow any of the new windows to have
" location lists.
function! WinStateOpenSubwinsByGroupType(supwinid, grouptype)
    call EchomLog('window-state', 'info', 'WinStateOpenSubwinsByGroupType ', a:supwinid, ':', a:grouptype.name)
    if !has_key(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let ToOpen = a:grouptype.toOpen
    if type(ToOpen) != v:t_func
        throw 'Given group type has nonfunc toOpen member'
    endif

    if !win_id2win(a:supwinid)
        throw 'Given supwinid ' . a:supwinid . ' does not exist'
    endif

    call win_gotoid(a:supwinid)

    let winids = ToOpen()
    call EchomLog('window-state', 'info', 'Opened subwin group ', a:supwinid, ':', a:grouptype.name, ' with winids ', winids)

    for idx in range(0, len(winids) - 1)
        if a:grouptype.widths[idx] >= 0
            call EchomLog('window-state', 'verbose', 'Fixed width for subwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixwidth', 1)
        else
            call EchomLog('window-state', 'verbose', 'Free width for subwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixwidth', 0)
        endif
        if a:grouptype.heights[idx] >= 0
            call EchomLog('window-state', 'verbose', 'Fixed height for subwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixheight', 1)
        else
            call EchomLog('window-state', 'verbose', 'Free height for subwin ', a:grouptype.typenames[idx])
            call setwinvar(winids[idx], '&winfixheight', 0)
        endif

        call EchomLog('window-state', 'verbose', 'Set statusline for subwin ', a:supwinid, ':', a:grouptype.name, ':', a:grouptype.typenames[idx], ' to ', a:grouptype.statuslines[idx])
        call setwinvar(winids[idx], '&statusline', a:grouptype.statuslines[idx])

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists... Unless the window is itself a location window, in which
        " case of course it should keep its location list
        if !getwininfo(winids[idx])[0]['loclist']
            call setloclist(winids[idx], [])
        endif
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" Close subwins of a give supwin using the toClose function from a group type
function! WinStateCloseSubwinsByGroupType(supwinid, grouptype)
    call EchomLog('window-state', 'info', 'WinStateCloseSubwinsByGroupType ', a:supwinid, ':', a:grouptype.name)
    if !has_key(a:grouptype, 'toClose')
        throw 'Given group type has no toClose member'
    endif
    
    let ToClose = a:grouptype.toClose
    if type(ToClose) != v:t_func
        throw 'Given group type has nonfunc toClose member'
    endif

    if !win_id2win(a:supwinid)
        throw 'Given supwinid ' . a:supwinid . ' does not exist'
    endif

    call win_gotoid(a:supwinid)
    call call(ToClose, [])
    call s:MaybeRedraw()
endfunction

" TODO: Move this to the vim-sign-utils plugin
function! s:PreserveSigns(winid)
    call EchomLog('window-state', 'verbose', 'PreserveSigns ', a:winid)
    let preserved = execute('sign place buffer=' . winbufnr(a:winid))
    call EchomLog('window-state', 'debug', 'Preserved signs: ', preserved)
    return preserved
endfunction

" TODO: Move this to the vim-sign-utils plugin
function! s:RestoreSigns(winid, signs)
    call EchomLog('window-state', 'verbose', 'RestoreSigns ', a:winid, ' ...')
    call EchomLog('window-state', 'verbose', 'Preserved signs: ', a:signs)
    for signstr in split(a:signs, '\n')
        if signstr =~# '^\s*line=\d*\s*id=\d*\s*name=.*$'
            let signid = substitute( signstr, '^.*id=\(\d*\).*$', '\1', '')
            let signname = substitute( signstr, '^.*name=\(.*\).*$', '\1', '')
            let signline = substitute( signstr, '^.*line=\(\d*\).*$', '\1', '')
            let cmd =  'sign place ' . signid .
           \           ' line=' . signline .
           \           ' name=' . signname .
           \           ' buffer=' . winbufnr(a:winid)
            call EchomLog('window-state', 'debug', cmd)
            execute cmd
        endif
    endfor
endfunction

" TODO: Put these folding functions in their own plugin
function! s:PreserveManualFolds()
    call EchomLog('window-state', 'verbose', 'PreserveManualFolds')
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
        call EchomLog('window-state', 'verbose', 'Line ', linenr, ' has foldlevel ', foldlevel)

        if foldlevel <# 0
            throw 'Negative foldlevel'
        endif

        " If the foldlevel has increased since the previous line, start new
        " folds at the current line - one for each +1 on the foldlevel
        if foldlevel ># prevfl
            for newfl in range(prevfl + 1, foldlevel, 1)
                call EchomLog('window-state', 'verbose', 'Start fold at foldlevel ', newfl)
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
                call EchomLog('window-state', 'verbose', 'End fold at foldlevel ', biggerfl)
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
        call EchomLog('window-state', 'verbose', 'Examine folds with foldlevel ', foldlevel)
        for afold in folds[foldlevel]
            " If a fold contains any line where foldclosed and foldclosedend
            " don't match with the start and end of the fold, then that fold
            " is open
            let afold.closed = 1
            for linenr in range(afold.start, afold.end, 1)
                if foldclosed(linenr) !=# afold.start ||
               \   foldclosedend(linenr) !=# afold.end
                    call EchomLog('window-state', 'verbose', 'Fold ', afold, ' is closed')
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
    call EchomLog('window-state', 'verbose', 'Deleting all folds')
    normal! zE

    let retdict = {'explen': line('$'), 'folds': folds}
    call EchomLog('window-state', 'verbose', 'Preserved manual folds: ', retdict)
    return retdict
endfunction

" TODO: Put these folding functions in their own plugin
function! s:PreserveFolds()
    call EchomLog('window-state', 'verbose', 'PreserveFolds')
    if &foldmethod ==# 'manual'
        call EchomLog('window-state', 'verbose', 'Foldmethod is manual')
        return {'method':'manual','data':s:PreserveManualFolds()}
    elseif &foldmethod ==# 'indent'
        call EchomLog('window-state', 'verbose', 'Foldmethod is indent')
        return {'method':'indent','data':''}
    elseif &foldmethod ==# 'expr'
        call EchomLog('window-state', 'verbose', 'Foldmethod is expr with foldexpr: ', &foldexpr)
        return {'method':'expr','data':&foldexpr}
    elseif &foldmethod ==# 'marker'
        call EchomLog('window-state', 'verbose', 'Foldmethod is marker')
        return {'method':'marker','data':''}
    elseif &foldmethod ==# 'syntax'
        call EchomLog('window-state', 'verbose', 'Foldmethod is syntax')
        return {'method':'syntax','data':''}
    elseif &foldmethos ==# 'diff'
        call EchomLog('window-state', 'verbose', 'Foldmethod is diff')
        return {'method':'diff','data':''}
    else
        throw 'Unknown foldmethod ' . &foldmethod
    endif
endfunction

" TODO: Put these folding functions in their own plugin
function! s:RestoreManualFolds(explen, folds)
    call EchomLog('window-state', 'verbose', 'RestoreManualFolds ', a:explen, ' ', a:folds)
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
            call EchomLog('window-state', 'verbose', 'Applying fold ', afold)
            execute afold.start . ',' . afold.end . 'fold'
            if !afold.closed
                execute afold.start . 'foldopen'
            endif
        endfor
    endfor
endfunction

" TODO: Put these folding functions in their own plugin
function! s:RestoreFolds(method, data)
    call EchomLog('window-state', 'info', 'RestoreFolds ', a:method, ' ', a:data)
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

function! WinStateAfterimageWindow(winid)
    call EchomLog('window-state', 'debug', 'WinStateAfterimageWindow ', a:winid)
    " Silent movement (noautocmd) is used here because we want to preserve the
    " state of the window exactly as it was when the function was first
    " called, and autocmds may fire on win_gotoid that change the state
    call WinStateMoveCursorToWinidSilently(a:winid)

    " Preserve cursor and scroll position
    let view = winsaveview()

    " Preserve some window options
    let bufft = &ft
    let bufwrap = &wrap
    let statusline = &statusline

    " Preserve colorcolumn
    let colorcol = &colorcolumn
    
    " Foldcolumn is not preserved because it is window-local (not
    " buffer-local) and will survive the afterimaging process

    call EchomLog('window-state', 'verbose', 'ft: ', bufft, ' wrap: ', bufwrap, ' statusline: ', statusline, ' colorcolumn: ', colorcol)

    " Preserve folds
    try
        let folds = s:PreserveFolds()
    catch /.*/
        call EchomLog('window-state', 'warning', 'Failed to preserve folds for window ', a:winid, ':'))
        call EchomLog('window-state', 'warning', v:throwpoint)
        call EchomLog('window-state', 'warning', v:exception)
        let folds = {'method':'manual','data':{}}
    endtry
    call s:MaybeRedraw()

    " Preserve signs, but also unplace them so that they don't show up if the
    " real buffer is reused for another supwin
    let signs = s:PreserveSigns(a:winid)
    for signstr in split(signs, '\n')
        if signstr =~# '^\s*line=\d*\s*id=\d*\s*name=.*$'
            let signid = substitute( signstr, '^.*id=\(\d*\).*$', '\1', '')
            call EchomLog('window-state', 'verbose', 'Unplace sign ', signid)
            execute 'sign unplace ' . signid
        endif
    endfor
    call s:MaybeRedraw()

    " Preserve buffer contents
    let bufcontents = getline(0, '$')
    call EchomLog('window-state', 'verbose', 'Buffer contents: ', bufcontents)

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
        call EchomLog('window-state', 'warning', 'Failed to restore folds for window ', a:winid, ':')
        call EchomLog('window-state', 'warning', v:throwpoint)
        call EchomLog('window-state', 'warning', v:exception)
    endtry
    call s:MaybeRedraw()

    " Restore colorcolumn
    let &colorcolumn = colorcol
    call s:MaybeRedraw()

    " Restore buffer options
    let &ft = bufft
    let &wrap = bufwrap
    let &l:statusline = statusline
    call s:MaybeRedraw()

    " Restore cursor and scroll position
    call winrestview(view)
    call s:MaybeRedraw()

    " Return afterimage buffer ID
    let aibuf = winbufnr('')
    call EchomLog('window-state', 'info', 'Afterimaged window ', a:winid, ' with buffer ', aibuf)
    return aibuf
endfunction

function! WinStateCloseWindow(winid)
    call EchomLog('window-state', 'info', 'WinStateCloseWindow ', a:winid)
    call WinStateAssertWinExists(a:winid)

    " :close fails if called on the last window. Explicitly exit Vim if
    " there's only one window left.
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        call EchomLog('window-state', 'info', 'Window ', a:winid, ' is the last window. Exiting Vim.')
        quit
    endif
    
    let winnr = win_id2win(a:winid)
    execute winnr . 'close'
    call s:MaybeRedraw()
endfunction

" Preserve/Restore for individual windows
function! WinStatePreCloseAndReopen(winid)
    call EchomLog('window-state', 'info', 'WinStatePreCloseAndReopen ', a:winid)
    call WinStateMoveCursorToWinidSilently(a:winid)

    " Preserve cursor position
    let view = winsaveview()

    " Preserve colorcolumn
    let colorcol = &colorcolumn

    " Preserve foldcolumn
    let foldcol = &foldcolumn

    call EchomLog('window-state', 'verbose', 'colorcolumn: ', colorcol, ' foldcolumn: ', foldcol, ' view: ', view)

    " Preserve folds
    try
        let fold = s:PreserveFolds()
    catch /.*/
        call EchomLog('window-state', 'warning', 'Failed to preserve folds for window ', a:winid, ':')
        call EchomLog('window-state', 'warning', v:throwpoint)
        call EchomLog('window-state', 'warning', v:exception)
        let fold = {'method':'manual','data':{}}
    endtry
    call s:MaybeRedraw()

    " Preserve signs
    let sign = s:PreserveSigns(a:winid)
    call s:MaybeRedraw()

    return {
   \    'view': view,
   \    'sign': sign,
   \    'fold': fold,
   \    'foldcol': foldcol,
   \    'colorcol': colorcol
   \}
endfunction

function! WinStatePostCloseAndReopen(winid, preserved)
    call EchomLog('window-state', 'info', 'WinStatePostCloseAndReopen ', a:winid, '...')
    call EchomLog('window-state', 'verbose', ' colorcolumn: ', a:preserved.colorcol, ' foldcolumn: ', a:preserved.foldcol, ' view: ', a:preserved.view)
    call WinStateMoveCursorToWinidSilently(a:winid)

    " Restore signs
    call s:RestoreSigns(a:winid, a:preserved.sign)
    call s:MaybeRedraw()

    " Restore folds
    try
        call s:RestoreFolds(a:preserved.fold.method, a:preserved.fold.data)
    catch /.*/
        call EchomLog('window-state', 'warning', 'Failed to restore folds for window ', a:winid, ':')
        call EchomLog('window-state', 'warning', v:throwpoint)
        call EchomLog('window-state', 'warning', v:exception)
    endtry
    call s:MaybeRedraw()

    " Restore foldcolumn
    let &foldcolumn = a:preserved.foldcol
    call s:MaybeRedraw()

    " Restore colorcolumn
    let &colorcolumn = a:preserved.colorcol
    call s:MaybeRedraw()
  
    " Restore cursor and scroll position
    call winrestview(a:preserved.view)
    call s:MaybeRedraw()
endfunction

function! WinStateResizeHorizontal(winid, width, preferleftdivider)
    call EchomLog('window-state', 'info', 'WinStateResizeHorizontal ', a:winid, ' ', a:width, ' ', a:preferleftdivider)
    call WinStateMoveCursorToWinidSilently(a:winid)
    let wasfixed = &winfixwidth
    let &winfixwidth = 0
    if !a:preferleftdivider
        call WinStateSilentWincmd(a:width, '|')
        let &winfixwidth = wasfixed
        return
    endif
    call WinStateSilentWincmd('','h')
    if win_getid() ==# a:winid
        call WinStateResizeHorizontal(a:winid, a:width, 0)
        let &winfixwidth = wasfixed
        return
    endif
    if &winfixwidth
        call WinStateResizeHorizontal(a:winid, a:width, 0)
        return
    endif
    let otherwidth = getwininfo(win_getid())[0].width
    let oldwidth = getwininfo(a:winid)[0].width
    let newwidth = otherwidth + oldwidth - a:width
    call WinStateSilentWincmd(newwidth, '|')
endfunction

function! WinStateResizeVertical(winid, height, prefertopdivider)
    call EchomLog('window-state', 'info', 'WinStateResizeVertical ', a:winid, ' ', a:height, ' ', a:prefertopdivider)
    call WinStateMoveCursorToWinidSilently(a:winid)
    let wasfixed = &winfixheight
    let &winfixheight = 0
    if !a:prefertopdivider
        call WinStateSilentWincmd(a:height, '_')
        let &winfixheight = wasfixed
        return
    endif
    call WinStateSilentWincmd('','k')
    if win_getid() ==# a:winid
        call WinStateResizeVertical(a:winid, a:height, 0)
        let &winfixheight = wasfixed
        return
    endif
    if &winfixheight
        call WinStateResizeVertical(a:winid, a:height, 0)
        return
    endif
    let otherheight = getwininfo(win_getid())[0].height
    let oldheight = getwininfo(a:winid)[0].height
    let newheight = otherheight + oldheight - a:height
    call WinStateSilentWincmd(newheight, '_')
endfunction
