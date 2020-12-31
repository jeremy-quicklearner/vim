" Wince Reference Definition for Option uberwin
let s:Log = jer_log#LogFunctions('wince-option-uberwin')
let s:Win = jer_win#WinFunctions()

if !exists('g:wince_enable_option') || !g:wince_enable_option
    call s:Log.CFG('Option uberwin disabled')
    finish
endif

" TODO? Close and reopen the option window whenever the current window
"       changes, so as to update its record of window-local options
"       - Probably not worth doing. The options and their possible values
"         all stay the same anway - only the positions of the possible values
"         would change

if !exists('g:wince_option_right')
    let g:wince_option_right = 0
endif

if !exists('g:wince_option_width')
    let g:wince_option_width = 85
endif

if !exists('g:wince_option_statusline')
    let g:wince_option_statusline = '%!WinceOptionStatusLine()'
endif

" Helper that silently jumps to t:prevwin and back
function! WinceOptionGoPrev()
    let prev = WinceModelPreviousWinInfo()
    let previd = WinceModelIdByInfo(prev)
    call WinceStateMoveCursorToWinidSilently(previd)
    noautocmd silent wincmd p
endfunction

let s:sid = -1

" Callback that opens the option window
function! WinceToOpenOption()
    call s:Log.INF('WinceToOpenOption')
    if bufwinnr('option-window') >=# 0
        throw 'Option window already open'
    endif

    let prevwinid = s:Win.getid()

    " The option window always splits using the 'new' command with no
    " modifiers, so 'vertical options' won't work. Instead, create an
    " ephemeral window and open the option window from there. Use the buflog
    " buffer for the ephemeral window to avoid creating a new buffer
    if g:wince_option_right
        noautocmd silent vertical botright sbuffer jersuite_buflog
    else
        noautocmd silent vertical topleft sbuffer jersuite_buflog
    endif
    let &l:scrollbind = 0
    let &l:cursorbind = 0
    execute 'noautocmd vertical resize ' . g:wince_option_width
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
    " Wince stores a more meaningful previous window in the model under
    " t:prevwin, but optwin.vim is part of Vim's runtime and therefore cannot
    " be changed to use t:prevwin instead of wincmd p.
    " A workaround is used - replace the mappings created in optwin.vim with new
    " mappings that silently move the cursor to t:prevwin and back, thus setting
    " wincmd p's 'previous window', right before doing what the original
    " mappings do.
    " Since <SID> evaluates to a script-unique value, that value must be
    " extracted from optwin.vim's mappings (which we can read using mapcheck())
    " and re-injected into the replacement mappings
    " The noremap commands in optwin.vim run every time the 'options' command is
    " invoked, so the new mappings need to be created on every WinceToOpenOption
    " call.
    if s:sid <# 0
        let crmap = mapcheck("<cr>")
        let snr = substitute(crmap, '<C-\\><C-N>:call <SNR>\(\d\+\)_CR()<CR>', '\1', '')
        let s:sid = '<SNR>_' . snr
    endif

    execute 'noremap <silent> <buffer> <CR> <C-\><C-N>:call WinceOptionGoPrev()<CR>:call ' . s:sid . 'CR()<CR>'
    execute 'inoremap <silent> <buffer> <CR> <Esc>:call WinceOptionGoPrev()<CR>:call ' . s:sid . 'CR()<CR>'
    execute 'noremap <silent> <buffer> <Space> :call WinceOptionGoPrev()<CR>:call ' . s:sid . 'Space()<CR>'

    let winid = s:Win.getid()

    noautocmd call s:Win.gotoid(prevwinid)

    return [winid]
endfunction

" Callback that closes the option window
function! WinceToCloseOption()
    call s:Log.INF('WinceToCloseOption')
    let optionwinid = 0
    for winnr in range(1, winnr('$'))
        if WinceStateGetBufnrByWinidOrWinnr(winnr) ==# bufnr('option-window')
            let optionwinid = s:Win.getid(winnr)
        endif
    endfor

    if !optionwinid
        throw 'Option window is not open'
    endif

    call WinceStateMoveCursorToWinidSilently(optionwinid)
    quit
endfunction

" Callback that returns 'option' if the supplied winid is for the option
" window
function! WinceToIdentifyOption(winid)
    call s:Log.DBG('WinceToIdentifyOption ', a:winid)
    if WinceStateGetBufnrByWinidOrWinnr(a:winid) ==# bufnr('option-window')
        return 'option'
    endif
    return ''
endfunction

function! WinceOptionStatusLine()
    call s:Log.DBG('OptionStatusLine')
    let statusline = ''

    " 'Option' string
    let statusline .= '%6*[Option]'

    " Start truncating
    let statusline .= '%<'

    " Buffer number
    let statusline .= '%1*[%n]'

    " Targetted window
    let target = WinceModelCurrentWinInfo()
    if target.category ==# 'uberwin' && target.grouptype ==# 'option'
        let target = WinceModelPreviousWinInfo()
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
call WinceAddUberwinGroupType('option', ['option'],
                           \[g:wince_option_statusline],
                           \'O', 'o', 6,
                           \60, [0],
                           \[g:wince_option_width], [-1],
                           \function('WinceToOpenOption'),
                           \function('WinceToCloseOption'),
                           \function('WinceToIdentifyOption'))

" Mappings
if exists('g:wince_disable_option_mappings') && g:wince_disable_option_mappings
    call s:Log.CFG('Option uberwin mappings disabled')
else
    call WinceMappingMapUserOp('<leader>os', 'call WinceAddOrShowUberwinGroup("option")')
    call WinceMappingMapUserOp('<leader>oo', 'let g:wince_map_mode = WinceAddOrGotoUberwin("option","option",g:wince_map_mode)')
    call WinceMappingMapUserOp('<leader>oh', 'call WinceRemoveUberwinGroup("option")')
    call WinceMappingMapUserOp('<leader>oc', 'call WinceRemoveUberwinGroup("option")')
endif
