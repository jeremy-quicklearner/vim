" Location list and location window manipulation
"
let s:refLocIsRunning = 0
" Make sure terminal windows' location windows are hidden.
" Close all location windows that aren't in focus. Open the location window
" for the current window if it isn't hidden.
function! RefreshLocationLists(command)
    " This function will be called from a nested autocmd. Guard against
    " recursion.
    if s:refLocIsRunning
        return
    endif
    let s:refLocIsRunning = 1

    " If a terminal window has a non-hidden location window, hide the location
    " window. Use the value 2 to indicate that the location window is hidden
    " because is it the location window for a terminal window, not because of
    " the user's choice
    for winnum in range(1, winnr('$'))
        if getwinvar(winnum, '&buftype', '$N$U$L$L$') ==# 'terminal' &&
          \getwinvar(winnum, 'locwinHidden', '$N$U$L$L$') == 0
            call setwinvar(winnum, 'locwinHidden', 2)
        endif
    endfor
    
    " If a non-terminal window has a location list that is hidden because it
    " was previously the location window for a terminal window, unhide that
    " location window
    for winnum in range(1, winnr('$'))
        if getwinvar(winnum, 'locwinHidden', '$N$U$L$L$') ==# 2 &&
          \getwinvar(winnum, '&buftype', '$N$U$L$L$') !=# 'terminal'
            call setwinvar(winnum, 'locwinHidden', 0)
        endif
    endfor

    " By default, no window is immune
    let immuneWinid = -1

    " If the current window is a location window with a parent window open
    " it's immune
    if getwininfo(win_getid())[0]['loclist']
        let currentWinid = win_getid()
        for winnum in range(1, winnr('$'))
            if winnum != winnr() &&
              \get(getloclist(winnum, {'winid':0}), 'winid', 0) == currentWinid
                let immuneWinid = currentWinid
            endif
        endfor
    endif

    " If the current window isn't a location window but has a location window open,
    " and that location window is non-hidden, that location window is immune
    if !getwininfo(win_getid())[0]['loclist'] &&
       \get(getloclist(0, {'winid':0}), 'winid', 0) &&
       \!w:locwinHidden
        let immuneWinid = getloclist(0, {'winid':0})['winid']
    endif

    " Get a list of all location windows' winids, except the immune one
    let locWinids = []
    for winnum in range(1, winnr('$'))
        let winid = win_getid(winnum)
        if getwininfo(winid)[0]['loclist'] && winid != immuneWinid
            call add(locWinids, winid)
        endif
    endfor

    " Close all those location windows
    for locWinid in locWinids
        execute win_id2win(locWinid) . 'wincmd q'
    endfor

    " If the current window isn't a location window but has a location list
    " and its location window is non-hidden, open its location window and
    " then jump back
    if len(getloclist(0)) && &ft !=# 'qf' && !w:locwinHidden
        lopen
        wincmd p
    endif
    
    let s:refLocIsRunning = 0
endfunction

" Register the above function to be called on the next CursorHold event
function! RegisterRefLoc()
    " RefreshLocationLists should never register itself with autocommands
    if s:refLocIsRunning
        return
    endif
    call RegisterCursorHoldCallback(function('RefreshLocationLists'), "", 1, -20, 0)
endfunction

augroup Loclist
    autocmd!
    " Make sure all new windows have their location window non-hidden by
    " default
    autocmd VimEnter,WinNew * call WinDoMaybeLet('locwinHidden', 0)

    " Refresh location windows after populating the location list
    autocmd QuickFixCmdPost [Ll]* call RegisterRefLoc()
    
    " Refresh the location lists whenever the user switches windows or a
    " window's buffer changes
    autocmd WinLeave,BufWinEnter * call RegisterRefLoc()
augroup END

" Mappings
" Hide the current window's location window
nnoremap <silent> <leader>lh :let w:locwinHidden = 1<cr>:call RegisterRefLoc()<cr>
" Show the current window's location window
nnoremap <silent> <leader>ls :let w:locwinHidden = 0<cr>:call RegisterRefLoc()<cr>

" Clear the current window's location list
nnoremap <silent> <leader>lc :lexpr []<cr>:lclose<cr>:call RegisterRefLoc()<cr>

