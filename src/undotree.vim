" Undotree plugin manipulation
call jer_log#SetLevel('wince-undotree-subwin', 'WRN', 'WRN')
let s:Log = jer_log#LogFunctions('wince-undotree-subwin')
let s:Win = jer_win#WinFunctions()


if !exists('g:wince_undotree_width')
    let g:wince_undotree_width = 25
endif

if !exists('g:wince_undotree_right')
    let g:wince_undotree_right = 0
endif

if !exists('g:wince_undodiff_top')
    let g:wince_undodiff_top = 0
endif

if !exists('g:wince_undodiff_height')
    let g:wince_undodiff_height = 10
endif

if !exists('g:wince_undotree_subwin_statusline')
    let g:wince_undotree_subwin_statusline = '%!WinceUndotreeStatusLine()'
endif

if !exists('g:wince_undodiff_subwin_statusline')
    let g:wince_undodiff_subwin_statusline = '%!WinceUndodiffStatusLine()'
endif


" Cause UndotreeShow to open the undotree windows relative to the current
" window, instead of relative to the whole tab
if g:wince_undotree_right
    let g:undotree_CustomUndotreeCmd = 'belowright vertical ' . g:wince_undotree_width . ' new'
else
    let g:undotree_CustomUndotreeCmd = 'aboveleft vertical ' . g:wince_undotree_width . ' new'
endif
if g:wince_undodiff_top
    let g:undotree_CustomDiffpanelCmd = 'aboveleft ' . g:wince_undodiff_height . ' new'
else
    let g:undotree_CustomDiffpanelCmd = 'belowright ' . g:wince_undodiff_height . ' new'
endif

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
function! WinceToOpenUndotree()
    call s:Log.INF('WinceToOpenUndotree')
    if (exists('t:undotree') && t:undotree.IsVisible())
        throw 'Undotree window is already open'
    endif

    " Before opening the tree window, make sure there's enough room.
    " We need at least <undotree_width + 2> columns - <undotree_width> for the tree
    " content, one for the vertical divider, and one for the supwin.
    " We also need enough room to then open the diff window. We need
    " at least <undodiff_height + 2> rows - <undodiff_height> for the diff content,
    " one for the tree statusline, and at least one for the tree content
    if winwidth(0) <# g:wince_undotree_width + 2 || winheight(0) <# g:wince_undodiff_height + 2
        throw 'Not enough room'
    endif

    let jtarget = s:Win.getid()

    UndotreeShow

    " UndotreeShow does not directly cause the undotree to be drawn. Instead,
    " it registers an autocmd that draws the tree when one of a set of events
    " fires. The direct call to undotree#UndotreeUpdate() here makes sure that
    " the undotree is drawn before WinceToOpenUndotree returns, which is required
    " for signs and folds to be properly restored when the undotree window is
    " closed and reopened.
    noautocmd call s:Win.gotoid(jtarget)
    call undotree#UndotreeUpdate()

    let treeid = -1
    let diffid = -1

    " The Undotree plugin has a troublesome feature - you can switch the
    " diffpanel window on and off. I deal with this by defining the Undotree subwin
    " group as having either one subwin or two subwins, so WinceToOpenUndotree may
    " return either one winid or two winids
    let diffon = (exists('g:undotree_DiffAutoOpen') && g:undotree_DiffAutoOpen == 0)

    for winnr in range(1,winnr('$'))
        if treeid >=# 0 && (diffon || diffid >=# 0)
            break
        endif

        if t:undotree.bufname ==# bufname(winbufnr(winnr))
            let treeid = s:Win.getid(winnr)
            continue
        endif
        
        if t:diffpanel.bufname ==# bufname(winbufnr(winnr))
            let diffid = s:Win.getid(winnr)
            continue
        endif
    endfor

    call setwinvar(s:Win.id2win(treeid), '&number', 1)
    call setwinvar(s:Win.id2win(treeid), 'j_undotree_target', jtarget)

    if !diffon
        call setwinvar(s:Win.id2win(diffid), '&number', 1)
        call setwinvar(s:Win.id2win(diffid), 'j_undotree_target', jtarget)
    endif

    if !diffon
        return [treeid, diffid]
    else
        return [treeid]
    endif
endfunction

" Callback that closes the undotree windows for the current window
function! WinceToCloseUndotree()
    call s:Log.INF('WinceToCloseUndotree')
    if (!exists('t:undotree') || !t:undotree.IsVisible())
        throw 'Undotree window is not open'
    endif

    " When closing the undotree, we want its supwin to fill the
    " space left. If there is also a supwin on the other side of the undotree
    " window, Vim may choose to fill the space with that one instead. Setting
    " splitright causes Vim to always pick the supwin to the left via some undocumented
    " behaviour. Conversely, resetting splitbelow causes Vim to always pick
    " the supwin to the right.
    let oldsr = &splitright
    if g:wince_undotree_right
        let &splitright = 1
    else
        let &splitright = 0
    endif

    UndotreeHide

    " Restore splitright
    let &splitright = oldsr
endfunction

" Callback that returns {'typename':'tree','supwin':<id>} or
" {'typename':'diff','supwin':<id>} if the supplied winid is for an undotree
" window
function! WinceToIdentifyUndotree(winid)
    call s:Log.DBG('WinceToIdentifyUndotree ', a:winid)
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

    let jtarget = getwinvar(s:Win.id2win(a:winid), 'j_undotree_target', 0)
    if jtarget
        let supwinid = jtarget
    else
        let supwinid = -1
        for winnr in range(1, winnr('$'))
            if getwinvar(winnr, 'undotree_id') == t:undotree.targetid
                let supwinid = s:Win.getid(winnr)
                call setwinvar(s:Win.id2win(a:winid), 'j_undotree_target', supwinid)
                break
            endif
        endfor
    endif
    return {'typename':typename,'supwin':supwinid}
endfunction

" Returns the statusline of the undotree window
function! WinceUndotreeStatusLine()
    call s:Log.DBG('UndotreeStatusLine')
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
function! WinceUndodiffStatusLine()
    call s:Log.DBG('UndodiffStatusLine')
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

" The undotree and diffpanel are a subwin group. If g:undotree_DiffAutoOpen is
" falsey, don't expect the diffpanel
if !exists('g:undotree_DiffAutoOpen') || g:undotree_DiffAutoOpen == 1
    call WinceAddSubwinGroupType('undotree', ['tree', 'diff'],
                              \[
                              \    g:wince_undotree_subwin_statusline,
                              \    g:wince_undodiff_subwin_statusline
                              \],
                              \'U', 'u', 5,
                              \40, [1, 1], [0, 0], g:wince_undotree_right,
                              \[g:wince_undotree_width, g:wince_undotree_width], [-1, g:wince_undodiff_height],
                              \function('WinceToOpenUndotree'),
                              \function('WinceToCloseUndotree'),
                              \function('WinceToIdentifyUndotree'))
else
    call WinceAddSubwinGroupType('undotree', ['tree'],
                              \[g:wince_undotree_subwin_statusline],
                              \'U', 'u', 5,
                              \40, [1], [0], g:wince_undotree_right,
                              \[g:wince_undotree_width], [-1],
                              \function('WinceToOpenUndotree'),
                              \function('WinceToCloseUndotree'),
                              \function('WinceToIdentifyUndotree'))
endif

" For each supwin, make sure the undotree subwin group exists if and only if
" that supwin has undo history
function! UpdateUndotreeSubwins()
    call s:Log.DBG('UpdateUndotreeSubwins')
    " Make sure scrollbind and cursorbind are off. For reasons I don't
    " understand, moving from window to window when there are
    " scrollbound/cursorbound windows can change those windows' cursor
    " positions
    let opts = {'s':&l:scrollbind,'c':&l:cursorbind}
    let &l:scrollbind = 0
    let &l:cursorbind = 0

    let info = WinceCommonGetCursorPosition()
    try
        for supwinid in WinceModelSupwinIds()
            let undotreewinsexist = WinceModelSubwinGroupExists(supwinid, 'undotree')

            " Special case: Terminal windows never have undotrees
            if undotreewinsexist && WinceStateWinIsTerminal(supwinid)
                call s:Log.INF('Removing undotree subwin group from terminal supwin ', supwinid)
                call WinceRemoveSubwinGroup(supwinid, 'undotree')
                continue
            endif

            noautocmd silent call WinceStateMoveCursorToWinid(supwinid)
            let undotreeexists = len(undotree().entries)

            if undotreewinsexist && !undotreeexists
                call s:Log.INF('Removing undotree subwin group from supwin ', supwinid, ' because its buffer has no undotree')
                call WinceRemoveSubwinGroup(supwinid, 'undotree')
                continue
            endif

            if !undotreewinsexist && undotreeexists
                call s:Log.INF('Adding undotree subwin group to supwin ', supwinid, ' because its buffer has an undotree')
                call WinceAddSubwinGroup(supwinid, 'undotree', 1, 0)
                continue
            endif
        endfor
    finally
        call WinceCommonRestoreCursorPosition(info)
        let &l:scrollbind = opts.s
        let &l:cursorbind = opts.c
    endtry
endfunction

" Update the undotree subwins after each resolver run, when the state and
" model are certain to be consistent
if !exists('g:wince_undotree_chc')
    let g:wince_undotree_chc = 1
    call jer_chc#Register(function('UpdateUndotreeSubwins'), [], 0, 10, 1, 0, 1)
    call WinceAddPostUserOperationCallback(function('UpdateUndotreeSubwins'))
endif

function! CloseDanglingUndotreeWindows()
    for winid in WinceStateGetWinidsByCurrentTab()
        let statusline = getwinvar(s:Win.id2win(winid), '&statusline', '')
        if statusline ==# g:wince_undotree_subwin_statusline || statusline ==# g:wince_undodiff_subwin_statusline
            call s:Log.INF('Closing dangling window ', winid)
            call WinceStateCloseWindow(winid, g:wince_undotree_right)
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
    autocmd SessionLoadPost * call jer_util#TabDo('', 'call jer_chc#Register(function("CloseDanglingUndotreeWindows"), [], 1, -100, 0, 0, 0)')
augroup END

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateUndotreeSubwins.
if exists('g:wince_undotree_disable_mappings') && g:wince_undotree_disable_mappings
    call s:Log.CFG('Undotree uberwin mappings disabled')
else
    call WinceMappingMapUserOp('<leader>us', 'call WinceShowSubwinGroup(0, "undotree", 1)')
    call WinceMappingMapUserOp('<leader>uh', 'call WinceHideSubwinGroup(0, "undotree")')
    call WinceMappingMapUserOp('<leader>uu', 'let g:wince_map_mode = WinceGotoSubwin(0, "undotree", "tree", g:wince_map_mode, 1)')
    if !exists('g:undotree_DiffAutoOpen') || g:undotree_DiffAutoOpen == 1
        call WinceMappingMapUserOp('<leader>ud', 'let g:wince_map_mode = WinceGotoSubwin(0, "undotree", "diff", g:wince_map_mode, 1)')
    endif
endif
