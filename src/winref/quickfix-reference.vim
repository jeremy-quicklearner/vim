" Quickfix list and quickfix window manipulation

" Make sure the quickfix window is only displayed if it is populated and
" non-empty. Always display it at the bottom of the screen.
let s:refQfIsRunning = 0
function! RefreshQuickfixList(arg)
    " This function will be called from a nested autocmd. Guard against
    " recursion.
    if s:refQfIsRunning
        return
    endif
    let s:refQfIsRunning = 1

    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)

    " If the quickfix list is empty or the quickfix window is hidden, make
    " sure it's closed
    if t:qfwinHidden || !len(getqflist())
        " If the quickfix window is open and is the last window, quit the tab
        if qfwinid && winnr('$') == 1
            quit
        " Otherwise we can use cclose
        else
            cclose
        endif
        let s:refQfIsRunning = 0
        return
    endif

    " If the quickfix window is open and the cursor is in it, move it to the
    " bottom of the screen and make sure it's ten rows tall
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if win_getid() == qfwinid
        wincmd J
        resize 10
        let s:refQfIsRunning = 0
        return
    endif

    " If the quickfix window is open and the cursor is not in it, move it to
    " the bottom of the screen and make sure it's ten rows tall
    if qfwinid
        " If the quickfix window is already at the bottom of the screen and
        " has the correct dimensions, do nothing
        let qfwinnr = win_id2win(qfwinid)
        if winwidth(qfwinnr) != &columns ||
          \winheight(qfwinnr) != 10 ||
          \qfwinnr != winnr('$') 
            call CloseAllLocWins()
            call RegisterRefLoc()
            copen
            wincmd J
            resize 10
            wincmd p
        endif
        let s:refQfIsRunning = 0
        return
    endif

    " At this point, the quickfix window is not open

    " If the quickfix list is populated, open the quickfix window and make
    " sure it's at the bottom of the screen
    if len(getqflist())
        call CloseAllLocWins()
        call RegisterRefLoc()
        copen
        wincmd J
    endif

    let s:refQfIsRunning = 0
endfunction

augroup Quickfix
    autocmd!
    " The quickfix window is non-hidden by default
    autocmd VimEnter,TabNew * let t:qfwinHidden = 0

    " Refresh the quickfix window on every CursorHold event. I would have
    " liked to use a callback for this but since Vim doesn't have a WinMoved
    " event, the only way to call it every time any window moves is... to also
    " call it many times when a window doesn't move.
    " I don't do this for location lists because RefreshLocationLists is
    " linear in the number of windows. RefreshQuickfixList takes constant
    " time.
    autocmd VimEnter,TabNew * call RegisterCursorHoldCallback(function('RefreshQuickfixList'), "", 1, -20, 1)
augroup END

" Mappings
" Hide the quickfix window
nnoremap <silent> <leader>qh :let t:qfwinHidden = 1<cr>
" Show the quickfix window
nnoremap <silent> <leader>qs :let t:qfwinHidden = 0<cr>

" Clear the quickfix list
nnoremap <silent> <leader>qc :cexpr []<cr>

"=================================================================================
augroup QuickfixNew
augroup END
