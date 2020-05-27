" Window state manipulation functions
" See window.vim

" Just for fun - lots of extra redrawing
if !exists('g:windraw')
    let g:windraw = 0
endif
function! s:MaybeRedraw()
    if g:windraw
        redraw
    endif
endfunction

" General Getters
function! WinStateGetWinidsByCurrentTab()
    let winids = []
    for winnr in range(1, winnr('$'))
        call add(winids, win_getid(winnr))
    endfor
    return winids
endfunction

function! WinStateWinExists(winid)
    return win_id2win(a:winid) != 0
endfunction
function! WinStateAssertWinExists(winid)
    if !WinStateWinExists(a:winid)
        throw 'no window with winid ' . a:winid
    endif
endfunction

function! WinStateGetWinnrByWinid(winid)
    call WinStateAssertWinExists(a:winid)
    return win_id2win(a:winid)
endfunction

function! WinStateGetWinidByWinnr(winnr)
    let winid = win_getid(a:winnr)
    call WinStateAssertWinExists(winid)
    return winid
endfunction

function! WinStateGetBufnrByWinid(winid)
    call WinStateAssertWinExists(a:winid)
    return winbufnr(a:winid)
endfunction

function! WinStateWinIsTerminal(winid)
    return WinStateWinExists(a:winid) && getwinvar(a:winid, '&buftype') ==# 'terminal'
endfunction

function! WinStateGetWinDimensions(winid)
    call WinStateAssertWinExists(a:winid)
    return {
   \    'nr': win_id2win(a:winid),
   \    'w': winwidth(a:winid),
   \    'h': winheight(a:winid)
   \}
endfunction

function! WinStateGetWinDimensionsList(winids)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinStateGetWinDimensions(winid))
    endfor
    return dim
endfunction

function! WinStateGetWinRelativeDimensions(winid, offset)
    call WinStateAssertWinExists(a:winid)
    if type(a:offset) != v:t_number
        throw 'offset is not a number'
    endif
    return {
   \    'relnr': win_id2win(a:winid) - a:offset,
   \    'w': winwidth(a:winid),
   \    'h': winheight(a:winid)
   \}
endfunction

function! WinStateGetWinRelativeDimensionsList(winids, offset)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinStateGetWinRelativeDimensions(winid, a:offset))
    endfor
    return dim
endfunction

" Cursor position preserve/restore
function! WinStateGetCursorWinId()
    return win_getid()
endfunction!
function! WinStateGetCursorPosition()
    return winsaveview()
endfunction
function! WinStateRestoreCursorPosition(pos)
    call winrestview(a:pos)
    call s:MaybeRedraw()
endfunction

" Dimension freezing
function! WinStateFreezeWindowSize(winid)
    let prefreeze = {
   \    'w': getwinvar(a:winid, '&winfixwidth'),
   \    'h': getwinvar(a:winid, '&winfixheight')
   \}
    call setwinvar(a:winid, '&winfixwidth', 1)
    call setwinvar(a:winid, '&winfixheight', 1)
    return prefreeze
endfunction

function! WinStateThawWindowSize(winid, prefreeze)
    call setwinvar(a:winid, '&winfixwidth', a:prefreeze.w)
    call setwinvar(a:winid, '&winfixheight', a:prefreeze.h)
endfunction

" Generic Ctrl-W commands
function! WinStateWincmd(count, cmd)
    execute a:count . 'wincmd ' . a:cmd
    call s:MaybeRedraw()
endfunction
function! WinStateSilentWincmd(count, cmd)
    noautocmd execute a:count . 'wincmd ' . a:cmd
    call s:MaybeRedraw()
endfunction

" Navigation
function! WinStateMoveCursorToWinid(winid)
    call WinStateAssertWinExists(a:winid)
    call win_gotoid(a:winid)
    call s:MaybeRedraw()
endfunction

function! WinStateMoveCursorToWinidSilently(winid)
    call WinStateAssertWinExists(a:winid)
    noautocmd call win_gotoid(a:winid)
    call s:MaybeRedraw()
endfunction

" Open windows using the toOpen function from a group type and return the
" resulting window IDs. Don't allow any of the new windows to have location
" lists.
function! WinStateOpenUberwinsByGroupType(grouptype)
    if !has_key(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let ToOpen = a:grouptype.toOpen
    if type(ToOpen) != v:t_func
        throw 'Given group type has nonfunc toOpen member'
    endif

    let winids = ToOpen()

    for idx in range(0, len(winids) - 1)
        if a:grouptype.widths[idx] >= 0
            call setwinvar(winids[idx], '&winfixwidth', 1)
        else
            call setwinvar(winids[idx], '&winfixwidth', 0)
        endif

        if a:grouptype.heights[idx] >= 0
            call setwinvar(winids[idx], '&winfixheight', 1)
        else
            call setwinvar(winids[idx], '&winfixheight', 0)
        endif

        call setwinvar(winids[idx], '&statusline', a:grouptype.statuslines[idx])

        call setloclist(winids[idx], [])
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" Close windows using the toClose function from a group type and return the
" resulting window IDs
function! WinStateCloseUberwinsByGroupType(grouptype)
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

    for idx in range(0, len(winids) - 1)
        if a:grouptype.widths[idx] >= 0
            call setwinvar(winids[idx], '&winfixwidth', 1)
        else
            call setwinvar(winids[idx], '&winfixwidth', 0)
        endif
        if a:grouptype.heights[idx] >= 0
            call setwinvar(winids[idx], '&winfixheight', 1)
        else
            call setwinvar(winids[idx], '&winfixheight', 0)
        endif

        call setwinvar(winids[idx], '&statusline', a:grouptype.statuslines[idx])

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists
        if !getwininfo(winids[idx])[0]['loclist']
            call setloclist(winids[idx], [])
        endif
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" From a given window, close windows using the toClose function from a group type
" and return the resulting window IDs
function! WinStateCloseSubwinsByGroupType(supwinid, grouptype)
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
    return execute('sign place buffer=' . winbufnr(a:winid))
endfunction

" TODO: Move this to the vim-sign-utils plugin
function! s:RestoreSigns(winid, signs)
    for signstr in split(a:signs, '\n')
        if signstr =~# '^\s*line=\d*\s*id=\d*\s*name=.*$'
            let signid = substitute( signstr, '^.*id=\(\d*\).*$', '\1', '')
            let signname = substitute( signstr, '^.*name=\(.*\).*$', '\1', '')
            let signline = substitute( signstr, '^.*line=\(\d*\).*$', '\1', '')
            execute 'sign place ' . signid .
           \        ' line=' . signline .
           \        ' name=' . signname .
           \        ' buffer=' . winbufnr(a:winid)
        endif
    endfor
endfunction

" TODO: Put these folding functions in their own plugin
function! s:PreserveManualFolds()
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

        if foldlevel <# 0
            throw 'Negative foldlevel'
        endif

        " If the foldlevel has increased since the previous line, start new
        " folds at the current line - one for each +1 on the foldlevel
        if foldlevel ># prevfl
            for newfl in range(prevfl + 1, foldlevel, 1)
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
        for afold in folds[foldlevel]
            " If a fold contains any line where foldclosed and foldclosedend
            " don't match with the start and end of the fold, then that fold
            " is open
            let afold.closed = 1
            for linenr in range(afold.start, afold.end, 1)
                if foldclosed(linenr) !=# afold.start ||
               \   foldclosedend(linenr) !=# afold.end
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
    
    " Delete all folds so that the call to s:RestoreFolds starts with a clean
    " slate
    normal! zE

    return {'explen': line('$'), 'folds': folds}
endfunction

" TODO: Put these folding functions in their own plugin
function! s:PreserveFolds()
    if &foldmethod ==# 'manual'
        return {'method':'manual','data':s:PreserveManualFolds()}
    elseif &foldmethod ==# 'indent'
        return {'method':'indent','data':''}
    elseif &foldmethod ==# 'expr'
        return {'method':'expr','data':&foldexpr}
    elseif &foldmethod ==# 'marker'
        return {'method':'marker','data':''}
    elseif &foldmethod ==# 'syntax'
        return {'method':'syntax','data':''}
    elseif &foldmethos ==# 'diff'
        return {'method':'diff','data':''}
    else
        throw 'Unknown foldmethod ' . &foldmethod
    endif
endfunction

" TODO: Put these folding functions in their own plugin
function! s:RestoreManualFolds(explen, folds)
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
            execute afold.start . ',' . afold.end . 'fold'
            if !afold.closed
                execute afold.start . 'foldopen'
            endif
        endfor
    endfor
endfunction

" TODO: Put these folding functions in their own plugin
function! s:RestoreFolds(method, data)
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
    " Silent movement (noautocmd) is used here because we want to preserve the
    " state of the window exactly as it was when the function was first
    " called, and autocmds may fire on win_gotoid that change the state
    call WinStateMoveCursorToWinidSilently(a:winid)
    call s:MaybeRedraw()

    " Preserve cursor and scroll position
    let view = winsaveview()

    " Preserve some window options
    let bufft = &ft
    let bufwrap = &wrap
    let statusline = &statusline

    " Preserve colorcolumn
    let colorcol = &colorcolumn

    " Preserve folds
    try
        let folds = s:PreserveFolds()
    catch /.*/
        echom 'Failed to preserve folds for window ' . a:winid . ':'
        echohl ErrorMsg | echo v:exception | echohl None
        let folds = {'method':'manual','data':{}}
    endtry
    call s:MaybeRedraw()

    " Preserve signs, but also unplace them so that they don't show up if the
    " real buffer is reused for another supwin
    let signs = s:PreserveSigns(a:winid)
    for signstr in split(signs, '\n')
        if signstr =~# '^\s*line=\d*\s*id=\d*\s*name=.*$'
            let signid = substitute( signstr, '^.*id=\(\d*\).*$', '\1', '')
            execute 'sign unplace ' . signid
        endif
    endfor
    call s:MaybeRedraw()

    " Preserve buffer contents
    let bufcontents = getline(0, '$')

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
        echom 'Failed to restore folds for window ' . a:winid . ':'
        echohl ErrorMsg | echo v:exception | echohl None
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
    return winbufnr('')
endfunction

function! WinStateCloseWindow(winid)
    call WinStateAssertWinExists(a:winid)

    " :close fails if called on the last window. Explicitly exit Vim if
    " there's only one window left.
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
    endif
    
    let winnr = win_id2win(a:winid)
    execute winnr . 'close'
    call s:MaybeRedraw()
endfunction

" Preserve/Restore for individual windows
function! WinStatePreCloseAndReopen(winid)
    call WinStateMoveCursorToWinidSilently(a:winid)
    call s:MaybeRedraw()

    " Preserve cursor position
    let view = winsaveview()

    " Preserve colorcolumn
    let colorcol = &colorcolumn

    " Preserve foldcolumn
    let foldcol = &foldcolumn

    " Preserve folds
    try
        let fold = s:PreserveFolds()
    catch /.*/
        echom 'Failed to preserve folds for window ' . a:winid . ':'
        echohl ErrorMsg | echo v:exception | echohl None
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
    call WinStateMoveCursorToWinidSilently(a:winid)
    call s:MaybeRedraw()

    " Restore signs
    call s:RestoreSigns(a:winid, a:preserved.sign)
    call s:MaybeRedraw()

    " Restore folds
    try
        call s:RestoreFolds(a:preserved.fold.method, a:preserved.fold.data)
    catch /.*/
        echom 'Failed to restore folds for window ' . a:winid . ':'
        echohl ErrorMsg | echo v:exception | echohl None
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
