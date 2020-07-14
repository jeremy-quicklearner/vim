" Quickfix list and quickfix window manipulation
call SetLogLevel('quickfix-uberwin', 'info', 'warning')

" Callback that opens the quickfix window
function! ToOpenQuickfix()
    call EchomLog('quickfix-uberwin', 'info', 'ToOpenQuickfix')
    " Fail if the quickfix window is already open
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if qfwinid
        throw 'Quickfix window already exists with ID ' . qfwinid
    endif

    " Open the quickfix window
    noautocmd botright copen
    let &syntax = 'qf'

    " copen also moves the cursor to the quickfix window, so return the
    " current window ID
    return [win_getid()]
endfunction

" Callback that closes the quickfix window
function! ToCloseQuickfix()
    call EchomLog('quickfix-uberwin', 'info', 'ToCloseQuickfix')
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
    call EchomLog('quickfix-uberwin', 'debug', 'ToIdentifyQuickfix ', a:winid)
    let qfwinid = get(getqflist({'winid':0}), 'winid', -1)
    if a:winid == qfwinid
        return 'quickfix'
    endif
    return ''
endfunction

" Returns the statusline of the quickfix window
function! QuickfixStatusLine()
    call EchomLog('quickfix-uberwin', 'debug', 'QuickfixStatusLine')
    let qfdict = getqflist({
   \    'title': 1,
   \    'nr': 0
   \})

    let qfdict = map(qfdict, function('SanitizeForStatusLine'))

    let statusline = ''

    " 'Quickfix' string
    let statusline .= '%2*[Quickfix]'

    " Start truncating
    let statusline .= '%<'

    " Quickfix list number
    let statusline .= '%1*[' . qfdict.nr . ']'

    " Quickfix list title (from the command that generated the list)
    let statusline .= '%1*[' . qfdict.title . ']'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Column][Current line/Total lines][% of buffer]
    let statusline .= '%2*[%c][%l/%L][%p%%]'

    return statusline
endfunction

" The quickfix window is an uberwin
call WinAddUberwinGroupType('quickfix', ['quickfix'],
                           \['%!QuickfixStatusLine()'],
                           \'Q', 'q', 2,
                           \50,
                           \[-1], [10],
                           \function('ToOpenQuickfix'),
                           \function('ToCloseQuickfix'),
                           \function('ToIdentifyQuickfix'))

" Make sure the quickfix uberwin exists if and only if there is a quickfix
" list
function! UpdateQuickfixUberwin(hide)
    call EchomLog('quickfix-uberwin', 'debug', 'UpdateQuickfixUberwin ', a:hide)
    let qfwinexists = WinModelUberwinGroupExists('quickfix')
    let qflistexists = len(getqflist())
    
    if qfwinexists && !qflistexists
        call EchomLog('quickfix-uberwin', 'info', 'Remove quickfix uberwin because there is no quickfix list')
        call WinRemoveUberwinGroup('quickfix')
        return
    endif

    if !qfwinexists && qflistexists
        call EchomLog('quickfix-uberwin', 'info', 'Add quickfix uberwin because there is a quickfix list')
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

" Peek at entries in quickfix and location lists
nnoremap <expr> <space> &buftype ==# 'quickfix' ? "zz\<cr>zz\<c-w>\<c-p>" : "\<space>"
