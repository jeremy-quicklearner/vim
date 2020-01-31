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

function! WinStateCloseWindowsByGroupType()
    if !has(a:grouptype, 'toClose')
        throw 'Given group type has no toClose member'
    endif
    
    let toClose = a:grouptype.toClose
    if type(toClose) != v:t_func
        throw 'Give group type has nonfunc toClose member'
    endif

    noautocmd let winids = call(toClose)
    return winids
endfunction

function! WinStateOpenWindowsByGroupType(grouptype)
    if !has(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let toOpen = a:grouptype.toOpen
    if type(toOpen) != v:t_func
        throw 'Give group type has nonfunc toOpen member'
    endif

    noautocmd call call(toOpen)
endfunction

