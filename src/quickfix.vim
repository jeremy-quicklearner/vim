" Quickfix list and quickfix window manipulation

" The quickfix window is non-hidden by default
let g:qfwinHidden = 0

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

    " If the quickfix window is hidden, make sure it's closed
    if g:qfwinHidden
        cclose
        let s:refQfIsRunning = 0
        return
    endif

    " If the quickfix window is open and the cursor is in it, move it to the
    " bottom of the screen
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if win_getid() == qfwinid
        wincmd J
        let s:refQfIsRunning = 0
        return
    endif

    " If the quickfix window is open and the cursor is not in it, move it to
    " the bottom of the screen
    if qfwinid
        copen
        wincmd J
        wincmd p
        let s:refQfIsRunning = 0
        return
    endif

    " At this point, the quickfix window is not open

    " If the quickfix list is populated, open the quickfix window and make
    " sure it's at the bottom of the screen
    if len(getqflist())
        copen
        wincmd J
    endif
        
    let s:refQfIsRunning = 0
endfunction

" Refresh the quickfix window on every CursorHold event. I would have
" liked to use a callback for this but since Vim doesn't have a WinMoved
" event, the only way to call it every time any window moves is... to also
" call it many times when a window doesn't move.
" I don't do this for location lists because RefreshLocationLists is
" linear in the number of windows. RefreshQuickfixList takes constant
" time.
call RegisterCursorHoldCallback(function('RefreshQuickfixList'), "", 1, -10, 1)

" Mappings
" Hide the quickfix window
nnoremap <silent> <leader>qh :let g:qfwinHidden = 1<cr>
" Show the quickfix window
nnoremap <silent> <leader>qs :let g:qfwinHidden = 0<cr>

" Clear the quickfix list
nnoremap <silent> <leader>qc :cexpr []<cr>:cclose<cr>
