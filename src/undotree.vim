" Undotree plugin manipulation
call SetLogLevel('undotree-subwin', 'info', 'warning')

" Cause UndotreeShow to open the undotree windows relative to the current
" window, instead of relative to the whole tab
let g:undotree_CustomUndotreeCmd = 'vertical 25 new'
let g:undotree_CustomDiffpanelCmd = 'belowright 10 new'

" Use short timestamp format
let g:undotree_ShortIndicators = 1

" Don't show the Help string
let g:undotree_HelpLine = 0

" Use O for each node
" Remember to change src/after/syntax.undotree.vim if you change this
let g:undotree_TreeNodeShape = 'O'

" Don't highlight anything in the target windows
let g:undotree_HighlightChangedText = 0

" Don't put signs in target windows to indicate which lines have changes
let g:undotree_HighlightChangedWithSign = 0

" Callback that opens the undotree windows for the current window
function! ToOpenUndotree()
    call EchomLog('undotree-subwin', 'info', 'ToOpenUndotree')
    if (exists('t:undotree') && t:undotree.IsVisible())
        throw 'Undotree window is already open'
    endif

    " Before opening the tree window, make sure there's enough room.
    " We need at least 27 columns - 25 for the tree content, one for the
    " vertical divider, and one for the supwin.
    " We also need enough room to then open the diff window. We need
    " at least 12 rows - one for the diff content, one for the tree
    " statusline, and at least one for the tree
    if winwidth(0) <# 27 || winheight(0) <# 12
        throw 'Not enough room'
    endif

    let jtarget = win_getid()

    UndotreeShow
    
    " UndotreeShow does not directly cause the undotree to be drawn. Instead,
    " it registers an autocmd that draws the tree when one of a set of events
    " fires. The direct call to undotree#UndotreeUpdate() here makes sure that
    " the undotree is drawn before ToOpenUndotree returns, which is required
    " for signs and folds to be properly restored when the undotree window is
    " closed and reopened.
    noautocmd call win_gotoid(jtarget)
    call undotree#UndotreeUpdate()

    let treeid = -1
    let diffid = -1
    for winnr in range(1,winnr('$'))
        if treeid >=# 0 && diffid >=# 0
            break
        endif

        if t:undotree.bufname ==# bufname(winbufnr(winnr))
            let treeid = win_getid(winnr)
            continue
        endif
        
        if t:diffpanel.bufname ==# bufname(winbufnr(winnr))
            let diffid = win_getid(winnr)
            continue
        endif
    endfor

    call setwinvar(treeid, '&number', 1)
    call setwinvar(diffid, '&number', 1)

    call setwinvar(treeid, 'j_undotree_target', jtarget)
    call setwinvar(diffid, 'j_undotree_target', jtarget)

    return [treeid, diffid]
endfunction

" Callback that closes the undotree windows for the current window
function! ToCloseUndotree()
    call EchomLog('undotree-subwin', 'info', 'ToCloseUndotree')
    if (!exists('t:undotree') || !t:undotree.IsVisible())
        throw 'Undotree window is not open'
    endif

    UndotreeHide
endfunction

" Callback that returns {'typename':'tree','supwin':<id>} or
" {'typename':'diff','supwin':<id>} if the supplied winid is for an undotree
" window
function! ToIdentifyUndotree(winid)
    call EchomLog('undotree-subwin', 'debug', 'ToIdentifyUndotree ' . a:winid)
    if (!exists('t:undotree') || !t:undotree.IsVisible())
        return {}
    endif

    if t:undotree.bufname ==# bufname(winbufnr(a:winid))
        let typename = 'tree'
    elseif t:diffpanel.bufname ==# bufname(winbufnr(a:winid))
        let typename = 'diff'
    else
        return {}
    endif

    let jtarget = getwinvar(a:winid, 'j_undotree_target', 0)
    if jtarget
        let supwinid = jtarget
    else
        let supwinid = -1
        for winnr in range(1, winnr('$'))
            if getwinvar(winnr, 'undotree_id') == t:undotree.targetid
                let supwinid = win_getid(winnr)
                call setwinvar(a:winid, 'j_undotree_target', supwinid)
                break
            endif
        endfor
    endif
    return {'typename':typename,'supwin':supwinid}
endfunction

" Returns the statusline of the undotree window
function! UndotreeStatusLine()
    call EchomLog('undotree-subwin', 'debug', 'UndotreeStatusLine')
    let statusline = ''

    " 'Undotree' string
    let statusline .= '%5*[Undotree]'

    " Start truncating
    let statusline .= '%1*%<'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Current line/Total lines][% of buffer]
    let statusline .= '%5*[%l/%L][%p%%]'

    return statusline
endfunction

" Returns the statusline of the undodiff window
function! UndodiffStatusLine()
    call EchomLog('undotree-subwin', 'info', 'UndodiffStatusLine')
    let statusline = ''

    " 'Undodiff' string
    let statusline .= '%5*[Undodiff]'

    " Start truncating
    let statusline .= '%1*%<'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Current line/Total lines][% of buffer]
    let statusline .= '%5*[%l/%L][%p%%]'

    return statusline
endfunction

" The undotree and diffpanel are a subwin group
call WinAddSubwinGroupType('undotree', ['tree', 'diff'],
                          \[
                          \    '%!UndotreeStatusLine()',
                          \    '%!UndodiffStatusLine()'
                          \],
                          \'U', 'u', 5,
                          \40, [1, 1],
                          \[25, 25], [-1, 10],
                          \function('ToOpenUndotree'),
                          \function('ToCloseUndotree'),
                          \function('ToIdentifyUndotree'))

" For each supwin, make sure the undotree subwin group exists if and only if
" that supwin has undo history
function! UpdateUndotreeSubwins(arg)
    call EchomLog('undotree-subwin', 'debug', 'UpdateUndotreeSubwins')
    if !WinModelExists()
        return
    endif
    let info = WinCommonGetCursorPosition()
        for supwinid in WinModelSupwinIds()
            let undotreewinsexist = WinModelSubwinGroupExists(supwinid, 'undotree')

            " Special case: Terminal windows never have undotrees
            if undotreewinsexist && WinStateWinIsTerminal(supwinid)
                call EchomLog('undotree-subwin', 'info', 'Removing undotree subwin group from terminal supwin ' . supwinid)
                call WinRemoveSubwinGroup(supwinid, 'undotree')
                continue
            endif

            call WinStateMoveCursorToWinid(supwinid)
            let undotreeexists = len(undotree().entries)

            if undotreewinsexist && !undotreeexists
                call EchomLog('undotree-subwin', 'info', 'Removing undotree subwin group from supwin ' . supwinid . ' because its buffer has no undotree')
                call WinRemoveSubwinGroup(supwinid, 'undotree')
                continue
            endif

            if !undotreewinsexist && undotreeexists
                call EchomLog('undotree-subwin', 'info', 'Adding undotree subwin group to supwin ' . supwinid . ' because its buffer has an undotree')
                call WinAddSubwinGroup(supwinid, 'undotree', 1)
                continue
            endif
        endfor
    call WinCommonRestoreCursorPosition(info)
endfunction

" Update the undotree subwins after each resolver run, when the state and
" model are certain to be consistent
if !exists('g:j_undotree_chc')
    let g:j_undotree_chc = 1
    call RegisterCursorHoldCallback(function('UpdateUndotreeSubwins'), [], 0, 10, 1, 1)
endif

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateUndotreeSubwins.
nnoremap <silent> <leader>us :call WinShowSubwinGroup(win_getid(), 'undotree')<cr>
nnoremap <silent> <leader>uh :call WinHideSubwinGroup(win_getid(), 'undotree')<cr>
nnoremap <silent> <leader>uu :call WinGotoSubwin(win_getid(), 'undotree', 'tree')<cr>
