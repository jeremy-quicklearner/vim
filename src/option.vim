" Option window manipulation
" TODO? Close and reopen the option window whenever the current window
"       changes, so as to update its record of window-local options
"       - Probably not worth doing
" TODO: Check if this uberwin group plays well with session reloading

call SetLogLevel('option-uberwin', 'info', 'warning')

" Helper that silently jumps to t:prevwin and back
function! OptGoPrev()
    let prev = WinModelPreviousWinInfo()
    let previd = WinModelIdByInfo(prev)
    call WinStateMoveCursorToWinid(previd)
    noautocmd silent wincmd p
endfunction

" Callback that opens the option window
function! ToOpenOption()
    call EchomLog('option-uberwin', 'info', 'ToOpenOption')
    for winid in WinStateGetWinidsByCurrentTab()
        if bufwinnr('option-window') >=# 0
            throw 'Option window already open'
        endif
    endfor

    let prevwinid = Win_getid_cur()

    " The option window always splits using the 'new' command with no
    " modifiers, so 'vertical options' won't work. Instead, create an
    " ephemeral window and open the option window from there. Use the buflog
    " buffer for the ephemeral window to avoid creating a new buffer
    noautocmd silent vertical topleft sbuffer j_buflog
    let &l:scrollbind = 0
    let &l:cursorbind = 0
    noautocmd vertical resize 85
    options
    noautocmd wincmd j
    quit
    options

    " After creating the option window, optwin.vim uses noremap with <SID> to
    " map <cr> and <space>:
    "     noremap <silent> <buffer> <CR> <C-\><C-N>:call <SID>CR()<CR>
    "     inoremap <silent> <buffer> <CR> <Esc>:call <SID>CR()<CR>
    "     noremap <silent> <buffer> <Space> :call <SID>Space()<CR>
    " These mappings then internally use 'wincmd p' to determine which window to
    " set local options for. This is undesirable because the resolver and user
    " operations are always moving the cursor all over the place, and the
    " previous window Vim stores for wincmd p isn't meaningful to the user.
    " Wince stores a more meanunful previous window in the model under
    " t:prevwin, but optwin.vim is part of Vim's runtime and therefore cannot
    " be changed to use t:prevwin instead of wincmd p.
    " My workaround is to replace the mappings created in optwin.vim with new
    " mappings that silently move the cursor to t:prevwin and back, thus setting
    " the previous window for wincmd p, right before doing what the original
    " mappings do.
    " Since <SID> evaluates to a script-unique value, that value must be
    " retrieved from the mapping.
    " The noremap commands in optwin.vim run every time the 'options' command is
    " invoked, so the new mappings need to be created on every ToOpenOption
    " call.
    let spacemap = mapcheck("<cr>")
    let sid = substitute(spacemap, '<C-\\><C-N>:call <SNR>\(\d\+\)_CR()<CR>', '\1', '')

    execute 'noremap <silent> <buffer> <CR> <C-\><C-N>:call OptGoPrev()<CR>:call <SNR>' . sid . '_CR()<CR>'
    execute 'inoremap <silent> <buffer> <CR> <Esc>:call OptGoPrev()<CR>:call <SNR>' . sid . '_CR()<CR>'
    execute 'noremap <silent> <buffer> <Space> :call OptGoPrev()<CR>:call <SNR>' . sid . '_Space()<CR>'

    let winid = Win_getid_cur()

    noautocmd call Win_gotoid(prevwinid)

    return [winid]
endfunction

" Callback that closes the option window
function! ToCloseOption()
    call EchomLog('option-uberwin', 'info', 'ToCloseOption')
    let optionwinid = 0
    for winid in WinStateGetWinidsByCurrentTab()
        if WinStateGetBufnrByWinid(winid) ==# bufnr('option-window')
            let optionwinid = winid
        endif
    endfor

    if !optionwinid
        throw 'Option window is not open'
    endif

    call WinStateMoveCursorToWinidSilently(optionwinid)
    quit
endfunction

" Callback that returns 'option' if the supplied winid is for the option
" window
function! ToIdentifyOption(winid)
    call EchomLog('option-uberwin', 'debug', 'ToIdentifyOption ', a:winid)
    if WinStateGetBufnrByWinid(a:winid) ==# bufnr('option-window')
        return 'option'
    endif
    return ''
endfunction

function! OptionStatusLine()
    call EchomLog('option-uberwin', 'debug', 'OptionStatusLine')
    let statusline = ''

    " 'Option' string
    let statusline .= '%6*[Option]'

    " Start truncating
    let statusline .= '%<'

    " Buffer number
    let statusline .= '%1*[%n]'

    " Targetted window
    let target = WinModelCurrentWinInfo()
    if target.category ==# 'uberwin' && target.grouptype ==# 'option'
        let target = WinModelPreviousWinInfo()
    endif
    
    let targetstr = ''
    if target.category ==# 'uberwin'
        let targetstr = target.grouptype . ':' . target.typename
    elseif target.category ==# 'supwin'
        let targetstr = target.id
    elseif target.category == 'subwin'
        let targetstr = target.supwin . ':' . target.grouptype . ':' . target.typename
    else
        let targetstr = 'NULL'
    endif
    let statusline .= '[For window ' . targetstr . ']'

    " Right-justify from now on
    let statusline .= '%=%<'
   
    " [Column][Current line/Total lines][% of buffer]
    let statusline .= '%6*[%c][%l/%L][%p%%]'

    return statusline
endfunction

" The option window is an uberwin
call WinAddUberwinGroupType('option', ['option'],
                           \['%!OptionStatusLine()'],
                           \'O', 'o', 6,
                           \60,
                           \[85], [-1],
                           \function('ToOpenOption'),
                           \function('ToCloseOption'),
                           \function('ToIdentifyOption'))

" Mappings
nnoremap <silent> <leader>oc :call WinRemoveUberwinGroup('option')<cr>
nnoremap <silent> <leader>oo :call WinAddOrGotoUberwin('option','option')<cr>
nnoremap <silent> <leader>os :call WinAddOrShowUberwinGroup('option')<cr>
nnoremap <silent> <leader>oh :call WinRemoveUberwinGroup('option')<cr>
