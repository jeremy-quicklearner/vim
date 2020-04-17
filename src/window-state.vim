" Window state manipulation functions
" See window.vim

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
function! s:AssertWinExists(winid)
    if !WinStateWinExists(a:winid)
        throw 'no window with winid ' . a:winid
    endif
endfunction

function! WinStateGetWinnrByWinid(winid)
    call s:AssertWinExists(a:winid)
    return win_id2win(a:winid)
endfunction

function! WinStateWinIsTerminal(winid)
    return WinStateWinExists(a:winid) && getwinvar(a:winid, '&buftype') ==# 'terminal'
endfunction

function! WinStateGetCursorWinId()
    return win_getid()
endfunction!

function! WinStateGetWinDimensions(winid)
    call s:AssertWinExists(a:winid)
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
    call s:AssertWinExists(a:winid)
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

" TODO: Add a wrapper in window-common that afterimages subwins
function! WinStateMoveCursorToWinid(winid)
    call s:AssertWinExists(a:winid)
    call win_gotoid(a:winid)
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

        call setloclist(winids[idx], [])
    endfor

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

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists
        if !getwininfo(winids[idx])[0]['loclist']
            call setloclist(winids[idx], [])
        endif
    endfor

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
endfunction

function! WinStateAfterimageWindow(winid)
   " noautocmd is used here because undotree has autocmds that fire on
   " WinLeave and close the diff window
    noautocmd call WinStateMoveCursorToWinid(a:winid)

    " Preserve buffer contents
    let bufcontents = getline(0, '$')

    " Preserve some window options
    let bufft = &ft
    let bufwrap = &wrap
    let bufpos = getpos('.')

    " Switch to a new hidden scratch buffer. This will be the afterimage buffer
    " noautocmd is used here because undotree has autocmds that fire when you
    " enew from the tree window and close the diff window
    noautocmd enew!
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted

    " Restore buffer contents
    call append(0, bufcontents)
    normal Gdd

    " Restore buffer options
    let &ft = bufft
    let &wrap = bufwrap
    call cursor(bufpos[1], bufpos[2], bufpos[3])

    " Return afterimage buffer ID
    return winbufnr('')
endfunction

function! WinStateCloseWindow(winid)
    call s:AssertWinExists(a:winid)

    " :close fails if called on the last window. Explicitly exit Vim if
    " there's only one window left.
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
    endif
    
    let winnr = win_id2win(a:winid)
    execute winnr . 'close'
endfunction
