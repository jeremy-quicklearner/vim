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

    " If the quickfix list is populated, open the quickfix window and make
    " sure it's at the bottom of the screen
    if len(getqflist())
        copen
        wincmd J
        wincmd p
        
    " If the quickfix list is not popuated, close the quickfix window
    else
        cclose
    endif
    let s:refQfIsRunning = 0
endfunction

" Register the above function to be called on the next CursorHold event
function! RegisterRefQf()
    " RefreshQuickfixList should never register itself with autocommands
    if s:refQfIsRunning
        return
    endif
    call RegisterCursorHoldCallback(function('RefreshQuickfixList'), "", 1, -10)
 endfunction

augroup QuickFix
    autocmd!
    " Refresh the quickfix window after populating the quickfix list
    autocmd QuickFixCmdPost [^Ll]* call RegisterRefQf()
augroup END

" Mappings
" Hide the quickfix window
nnoremap <silent> <leader>qh :let g:qfwinHidden = 1<cr>:call RegisterRefQf()<cr>
" Show the quickfix window
nnoremap <silent> <leader>qs :let g:qfwinHidden = 0<cr>:call RegisterRefQf()<cr>

" Clear the quickfix list
nnoremap <silent> <leader>qc :cexpr []<cr>:cclose<cr>:call RegisterRefQf()<cr>
