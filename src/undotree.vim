" Undotree plugin manipulation

" Cause UndotreeShow to open the undotree windows relative to the current
" window, instead of relative to the whole tab
let g:undotree_CustomUndotreeCmd = 'vertical 25 new'
let g:undotree_CustomDiffpanelCmd = 'belowright 10 new'

" Use short timestamp format
let g:undotree_ShortIndicators = 1

" Don't show the Help string
let g:undotree_HelpLine = 0

" Use O for each node
let g:undotree_TreeNodeShape = 'O'

" Don't highlight anything in the target windows
let g:undotree_HighlightChangedText = 0

" Callback that opens the undotree windows for the current window
function! ToOpenUndotree()
    if (exists('t:undotree') && t:undotree.IsVisible())
        throw 'Undotree window is already open'
    endif

    let jtarget = win_getid()

    UndotreeShow

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
    if (!exists('t:undotree') || !t:undotree.IsVisible())
        throw 'Undotree window is not open'
    endif

    UndotreeHide
endfunction

" Callback that returns {'typename':'tree','supwin':<id>} or
" {'typename':'diff','supwin':<id>} if the supplied winid is for an undotree
" window
function! ToIdentifyUndotree(winid)
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

" The undotree and diffpanel are a subwin group
call WinAddSubwinGroupType('undotree', ['tree', 'diff'],
                          \'Und', 'Hid', 2, 40, [1, 1],
                          \[25, 25], [-1, 10],
                          \function('ToOpenUndotree'),
                          \function('ToCloseUndotree'),
                          \function('ToIdentifyUndotree'))

" For each supwin, make sure the undotree subwin group exists if and only if
" that supwin has undo history
function! UpdateUndotreeSubwins()
    let info = WinCommonGetCursorPosition()
        for supwinid in WinModelSupwinIds()
            " Special case: When a supwin is closed while it has a live undotree, the
            " cursor jumps to the left - to the undotree windows. The undotree
            " plugin's autocmds fire and update the text in those windows, and
            " TextChanged fires and calls this function, before the resolver runs.
            " Since the resolver hasn't run yet, the model and state are inconsistent.
            " The supwin is returned by WinModelSupwinIds() but it isn't in the state
            " when we call WinStateMoveCursorToWinid(). The code below breaks.
            " So check if the window exists before trying to jump to it
            if !WinStateWinExists(supwinid)
                continue
            endif

            call WinStateMoveCursorToWinid(supwinid)
            let undotreewinsexist = WinModelSubwinGroupExists(supwinid, 'undotree')
            let undotreeexists = len(undotree().entries)

            if undotreewinsexist && !undotreeexists
                call WinRemoveSubwinGroup(supwinid, 'undotree')
                continue
            endif

            if !undotreewinsexist && undotreeexists
                call WinAddSubwinGroup(supwinid, 'undotree', 1)
            endif
        endfor
    call WinCommonRestoreCursorPosition(info)
endfunction

" Update the undotree subwins when new supwins are added
call WinModelAddSupwinsAddedResolveCallback(function('UpdateUndotreeSubwins'))

" Update the undotree subwins after any changes
augroup UndotreeWin
    autocmd!
    autocmd TextChanged * call UpdateUndotreeSubwins()
augroup END

" Mappings
" No explicit mappings to add or remove. Those operations are done by
" UpdateUndotreeSubwins.
nnoremap <silent> <leader>us :call WinShowSubwinGroup(win_getid(), 'undotree')<cr>
nnoremap <silent> <leader>uh :call WinHideSubwinGroup(win_getid(), 'undotree')<cr>
nnoremap <silent> <leader>uu :call WinGotoSubwin(win_getid(), 'undotree', 'tree')<cr>
