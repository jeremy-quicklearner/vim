" Quickfix list and quickfix window manipulation

" Callback that opens the quickfix window
function! ToOpenQuickfix()
    " Fail if the quickfix window is already open
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if qfwinid
        throw 'Quickfix window already exists with ID ' . qfwinid
    endif

    " Open the quickfix window
    botright copen

    " copen also moves the cursor to the quickfix window, so return the
    " current window ID
    return [win_getid()]
endfunction

" Callback that closes the quickfix window
function! ToCloseQuickfix()
    " Fail if the quickfix window is already closed
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if !qfwinid
        throw 'Cannot close quickfix window that is not open'
    endif

    " cclose fails if the quickfix window is the last window, so use :quit
    " instead
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
        return
    endif

    cclose
endfunction

" Callback that returns 'quickfix' if the supplied winid is for the quickfix
" window
function! ToIdentifyQuickfix(winid)
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if a:winid == qfwinid
        return 'quickfix'
    endif
    return ''
endfunction

" The quickfix window is an uberwin
call WinAddUberwinGroupType('quickfix', ['quickfix'],
                           \'Qfx', 'Hid', 2, 0,
                           \[-1], [10],
                           \function('ToOpenQuickfix'),
                           \function('ToCloseQuickfix'),
                           \function('ToIdentifyQuickfix'))

" Make sure the quickfix uberwin exists if and only if there is a quickfix
" list
function! UpdateQuickfixUberwin(hide)
    let qfwinexists = WinModelUberwinGroupExists('quickfix')
    let qflistexists = len(getqflist())
    
    if qfwinexists && !qflistexists
        call WinRemoveUberwinGroup('quickfix')
        return
    endif

    if !qfwinexists && qflistexists
        call WinAddUberwinGroup('quickfix', a:hide)
        return
    endif
endfunction
function! UpdateQuickfixUberwinShow()
    call UpdateQuickfixUberwin(0)
endfunction
function! UpdateQuickfixUberwinHide()
    call UpdateQuickfixUberwin(1)
endfunction

" Update the quickfix uberwin after entering a tab
" If the uberwin needs to be added, make it hidden
call WinAddTabEnterPreResolveCallback(function('UpdateQuickfixUberwinHide'))

" Update the quickfix uberwin whenever the quickfix list is changed
" If the uberwin needs to be added don't hide it
augroup Quickfix
    autocmd!
    autocmd QuickFixCmdPost * call UpdateQuickfixUberwinShow()
augroup END

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateQuickfixUberwin.
nnoremap <silent> <leader>qc :cexpr []<cr>
nnoremap <silent> <leader>qs :call WinShowUberwinGroup('quickfix')<cr>
nnoremap <silent> <leader>qh :call WinHideUberwinGroup('quickfix')<cr>
nnoremap <silent> <leader>qq :call WinGotoUberwin('quickfix', 'quickfix')<cr>
