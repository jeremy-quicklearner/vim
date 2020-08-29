" Undotree plugin manipulation
call SetLogLevel('undotree-subwin', 'info', 'warning')

if !exists('g:undotree_subwin_statusline')
    let g:undotree_subwin_statusline = '%!UndotreeStatusLine()'
endif

if !exists('g:undodiff_subwin_statusline')
    let g:undodiff_subwin_statusline = '%!UndodiffStatusLine()'
endif


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

    let jtarget = Win_getid_cur()

    
    " Open the undotree window on the left side
    let oldsr = &splitright
    let &splitright = 0

    UndotreeShow

    " Restore splitright
    let &splitright = oldsr
    
    " UndotreeShow does not directly cause the undotree to be drawn. Instead,
    " it registers an autocmd that draws the tree when one of a set of events
    " fires. The direct call to undotree#UndotreeUpdate() here makes sure that
    " the undotree is drawn before ToOpenUndotree returns, which is required
    " for signs and folds to be properly restored when the undotree window is
    " closed and reopened.
    noautocmd call Win_gotoid(jtarget)
    call undotree#UndotreeUpdate()

    let treeid = -1
    let diffid = -1
    for winnr in range(1,winnr('$'))
        if treeid >=# 0 && diffid >=# 0
            break
        endif

        if t:undotree.bufname ==# bufname(winbufnr(winnr))
            let treeid = Win_getid(winnr)
            continue
        endif
        
        if t:diffpanel.bufname ==# bufname(winbufnr(winnr))
            let diffid = Win_getid(winnr)
            continue
        endif
    endfor

    call setwinvar(Win_id2win(treeid), '&number', 1)
    call setwinvar(Win_id2win(diffid), '&number', 1)

    call setwinvar(Win_id2win(treeid), 'j_undotree_target', jtarget)
    call setwinvar(Win_id2win(diffid), 'j_undotree_target', jtarget)

    return [treeid, diffid]
endfunction

" Callback that closes the undotree windows for the current window
function! ToCloseUndotree()
    call EchomLog('undotree-subwin', 'info', 'ToCloseUndotree')
    if (!exists('t:undotree') || !t:undotree.IsVisible())
        throw 'Undotree window is not open'
    endif

    " When closing the undotree, we want the supwin to its right to fill the
    " space left. If there is also a supwin to the left, Vim may choose to fill
    " the space with that one instead of the one to the right. Setting splitright 
    " to 0 causes Vim to always pick the supwin to the right via some undocumented
    " behaviour.
    let oldsr = &splitright
    let &splitright = 0

    UndotreeHide

    " Restore splitright
    let &splitright = oldsr
endfunction

" Callback that returns {'typename':'tree','supwin':<id>} or
" {'typename':'diff','supwin':<id>} if the supplied winid is for an undotree
" window
function! ToIdentifyUndotree(winid)
    call EchomLog('undotree-subwin', 'debug', 'ToIdentifyUndotree ', a:winid)
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

    let jtarget = getwinvar(Win_id2win(a:winid), 'j_undotree_target', 0)
    if jtarget
        let supwinid = jtarget
    else
        let supwinid = -1
        for winnr in range(1, winnr('$'))
            if getwinvar(winnr, 'undotree_id') == t:undotree.targetid
                let supwinid = Win_getid(winnr)
                call setwinvar(Win_id2win(a:winid), 'j_undotree_target', supwinid)
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
    call EchomLog('undotree-subwin', 'debug', 'UndodiffStatusLine')
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
                          \    g:undotree_subwin_statusline,
                          \    g:undodiff_subwin_statusline
                          \],
                          \'U', 'u', 5,
                          \40, [1, 1],
                          \[25, 25], [-1, 10],
                          \function('ToOpenUndotree'),
                          \function('ToCloseUndotree'),
                          \function('ToIdentifyUndotree'))

" For each supwin, make sure the undotree subwin group exists if and only if
" that supwin has undo history
function! UpdateUndotreeSubwins()
    call EchomLog('undotree-subwin', 'debug', 'UpdateUndotreeSubwins')
    if !WinModelExists()
        return
    endif

    " Make sure scrollbind and cursorbind are off. For reasons I don't
    " understand, moving from window to window when there are
    " scrollbound/cursorbound windows can change those windows' cursor
    " positions
    let opts = {'s':&l:scrollbind,'c':&l:cursorbind}
    let &l:scrollbind = 0
    let &l:cursorbind = 0

    let info = WinCommonGetCursorPosition()
    try
        for supwinid in WinModelSupwinIds()
            let undotreewinsexist = WinModelSubwinGroupExists(supwinid, 'undotree')

            " Special case: Terminal windows never have undotrees
            if undotreewinsexist && WinStateWinIsTerminal(supwinid)
                call EchomLog('undotree-subwin', 'info', 'Removing undotree subwin group from terminal supwin ', supwinid)
                call WinRemoveSubwinGroup(supwinid, 'undotree')
                continue
            endif

            noautocmd silent call WinStateMoveCursorToWinid(supwinid)
            let undotreeexists = len(undotree().entries)

            if undotreewinsexist && !undotreeexists
                call EchomLog('undotree-subwin', 'info', 'Removing undotree subwin group from supwin ', supwinid, ' because its buffer has no undotree')
                call WinRemoveSubwinGroup(supwinid, 'undotree')
                continue
            endif

            if !undotreewinsexist && undotreeexists
                call EchomLog('undotree-subwin', 'info', 'Adding undotree subwin group to supwin ', supwinid, ' because its buffer has an undotree')
                call WinAddSubwinGroup(supwinid, 'undotree', 1)
                continue
            endif
        endfor
    finally
        call WinCommonRestoreCursorPosition(info)
        let &l:scrollbind = opts.s
        let &l:cursorbind = opts.c
    endtry
endfunction

" Update the undotree subwins after each resolver run, when the state and
" model are certain to be consistent
if !exists('g:j_undotree_chc')
    let g:j_undotree_chc = 1
    call RegisterCursorHoldCallback(function('UpdateUndotreeSubwins'), [], 0, 10, 1, 0, 1)
    call WinAddPostUserOperationCallback(function('UpdateUndotreeSubwins'))
endif

function! CloseDanglingUndotreeWindows()
    for winid in WinStateGetWinidsByCurrentTab()
        let statusline = getwinvar(Win_id2win(winid), '&statusline', '')
        if statusline ==# g:undotree_subwin_statusline || statusline ==# g:undodiff_subwin_statusline
            call EchomLog('undotree-subwin', 'info', 'Closing dangling window ', winid)
            call WinStateCloseWindow(winid)
        endif
    endfor
endfunction

augroup UndotreeSubwin
    autocmd!

    " If there are undotree subwins open when mksession is invoked, their
    " contents do not persist. When the session is reloaded, the undotree
    " windows are opened without content or window-local variables and are
    " therefore not compliant with toIdentify. The first resolver run will
    " notice this and relist the windows as supwins - so now there are a bunch
    " of extra supwins with the undotree filetype and no content. I see no
    " reason why the user would ever want to keep these windows around, so
    " they are removed here
    autocmd SessionLoadPost * Tabdo call RegisterCursorHoldCallback(function('CloseDanglingUndotreeWindows'), [], 1, -100, 0, 0, 0)
augroup END

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateUndotreeSubwins.
call WinMappingMapUserOp('<leader>us', 'call WinShowSubwinGroup(Win_getid_cur(), "undotree")')
call WinMappingMapUserOp('<leader>uh', 'call WinHideSubwinGroup(Win_getid_cur(), "undotree")')
call WinMappingMapUserOp('<leader>uu', 'call WinGotoSubwin(Win_getid_cur(), "undotree", "tree")')
call WinMappingMapUserOp('<leader>ud', 'call WinGotoSubwin(Win_getid_cur(), "undotree", "diff")')
