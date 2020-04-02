" Quickfix list and quickfix window manipulation

" Callback that opens the quickfix window
function! ToOpenQuickfix()
    " Fail if the quickfix window is already open
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if qfwinid
        throw 'Quickfix window already exists with ID ' . qfwinid
    endif

    " Open the quickfix window
    copen

    " copen also moves the cursor to the quickfix window, so return the
    " current window ID
    return [win_getid()]
endfunction

" Callback that closes the quickfix window
function! ToCloseQuickfix()
    " cclose fails if the quickfix window is the last window, so use :quit
    " instead
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
        return
    endif

    cclose
endfunction

" Make sure the quickfix uberwin exists if and only if there is a quickfix
" list
function! UpdateQuickfixUberwin()
    let qfwinexists = WinModelUberwinGroupExists('quickfix')
    let qflistexists = len(getqflist())
    
    if qfwinexists && !qflistexists
        call WinRemoveUberwinGroup('quickfix')
        return
    endif

    if !qfwinexists && qflistexists
        call WinAddUberwinGroup('quickfix', 0)
        return
    endif
endfunction

" The quickfix window is an uberwin
call WinAddUberwinGroupType('quickfix', ['quickfix'],
                           \'Qfx', 'Hid', 2, 0, [-1], [10],
                           \function('ToOpenQuickfix'),
                           \function('ToCloseQuickfix'))

" Update the Quickfix uberwin when the quickfix list changes
augroup Quickfix
    autocmd!
    autocmd QuickFixCmdPost [^Ll]* call UpdateQuickfixUberwin()
augroup END

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateQfUberwin.
nnoremap <silent> <leader>qc :cexpr []<cr>
nnoremap <silent> <leader>qs :call WinShowUberwinGroup('quickfix')<cr>
nnoremap <silent> <leader>qh :call WinHideUberwinGroup('quickfix')<cr>
nnoremap <silent> <leader>qq :call WinGotoUberwin('quickfix', 'quickfix')<cr>

"=================================================================================
augroup QuickfixNew
augroup END
