" Quickfix and Location list manipulation

let s:refLocIsRunning = 0
" Close all location windows that aren't in focus. Open the location window
" for the current window
function! RefreshLocationLists(command)
    " This function will be called from a nested autocmd. Guard against
    " recursion.
    if s:refLocIsRunning
        return
    endif
    let s:refLocIsRunning = 1
    " By default, no window is immune
    let immuneWinid = -1

    " If the current window isn't a location window but has a location window open,
    " that location window is immune
    if !getwininfo(win_getid())[0]['loclist'] &&
       \get(getloclist(0, {'winid':0}), 'winid', 0)
        let immuneWinid = getloclist(0, {'winid':0})['winid']
    endif

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

    " If the current window isn't a location window but has a location list,
    " open its location window and then jump back
    if len(getloclist(0)) && &ft !=# 'qf'
        lopen
        wincmd p
    endif
    
    let s:refLocIsRunning = 0

endfunction
command! -nargs=0 -complete=command Refloc call RefreshLocationLists("")

" Mappings
" Peek at entries in quickfix lists
nnoremap <expr> <space> &buftype ==# 'quickfix' ? "\<cr>\<c-w>\<c-p>" : "\<cr>"

" Clear the quickfix list
nnoremap <silent> <leader>cc :cexpr []<cr>

" Clear location lists
nnoremap <silent> <leader>lc :lexpr []<cr>

" Refresh the location lists if we need to
function! MaybeRefloc()
    if t:refloc
        let t:refloc = 0
        Refloc
    endif
endfunction

augroup QuickFix
    autocmd!
    " Automatically open the quickfix window after populating the quickfix list
    autocmd QuickFixCmdPost [^Ll]* nested cwindow
    " Automatically open the location window after populating the location list
    autocmd QuickFixCmdPost [Ll]* nested lwindow

    " Refresh the location lists after leaving a window
    autocmd VimEnter * let t:refloc = 1
    autocmd TabNew * let t:refloc = 1
    autocmd WinLeave * let t:refloc = 1
    autocmd CursorHold * nested call MaybeRefloc()

    " Always open the quickfix window across the whole width of the screen
    autocmd FileType qf
                \  if !getwininfo(win_getid())[0]['loclist']
                \|     wincmd J
                \| endif
augroup END

