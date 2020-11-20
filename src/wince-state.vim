" Wince State
" See wince.vim
" Essentially, this file's contents act as a wrapper over the Vim's native
" window commands. The rest of the Wince core can only run those commands via
" this wrapper. Any algorithms that make frequent use of the native window
" commands are implemented at this level.
let s:Log = jer_log#LogFunctions('wince-state')
let s:Win = jer_win#WinFunctions()

" Just for fun - lots of extra redrawing
if !exists('g:wince_extra_redraw')
    call s:Log.CFG('wince_extra_redraw initially false')
    let g:wince_extra_redraw = 0
endif
function! s:MaybeRedraw()
    call s:Log.DBG('MaybeRedraw')
    if g:wince_extra_redraw
        call s:Log.DBG('Redraw')
        redraw
    endif
endfunction

" General Getters
function! WinceStateGetTabCount()
    call s:Log.DBG('WinceStateGetTabCount')
    return tabpagenr('$')
endfunction
function! WinceStateGetTabnr()
    call s:Log.DBG('WinceStateGetTabnr')
    return tabpagenr()
endfunction

function! WinceStateGetWinidsByCurrentTab()
    call s:Log.DBG('WinceStateGetWinidsByCurrentTab')
    let winids = map(range(1, winnr('$')), 's:Win.getid(v:val)')
    call s:Log.DBG('Winids: ', winids)
    return winids
endfunction

function! WinceStateWinExists(winid)
    call s:Log.DBG('WinceStateWinExists ', a:winid)
    let winexists = s:Win.id2win(a:winid) != 0
    if winexists
        call s:Log.DBG('Window exists with winid ', a:winid)
    else
        call s:Log.DBG('No window with winid ', a:winid)
    endif
    return winexists
endfunction
function! WinceStateAssertWinExists(winid)
    call s:Log.DBG('WinceStateAssertWinExists ', a:winid)
    if !s:Win.id2win(a:winid)
        throw 'no window with winid ' . a:winid
    endif
endfunction

function! WinceStateGetWinnrByWinid(winid)
    call s:Log.DBG('WinceStateGetWinnrByWinid ', a:winid)
    let winnr = s:Win.id2win(a:winid)
    if winnr ==# 0
        throw 'no window with winid ' . a:winid
    endif
    call s:Log.DBG('Winnr is ', winnr, ' for winid ', a:winid)
    return winnr
endfunction

function! WinceStateGetWinidByWinnr(winnr)
    call s:Log.DBG('WinceStateGetWinidByWinnr ', a:winnr)
    let winid = s:Win.getid(a:winnr)
    call s:Log.DBG('Winid is ', winid, ' for winnr ', a:winnr)
    return winid
endfunction

function! WinceStateGetBufnrByWinidOrWinnr(winid)
    call s:Log.DBG('WinceStateGetBufnrByWinidOrWinnr ', a:winid)
    let bufnr = s:Win.bufnr(a:winid)
    call s:Log.DBG('Bufnr is ', bufnr, ' for winid ', a:winid)
    return bufnr
endfunction

function! WinceStateWinIsTerminal(winid)
    call s:Log.DBG('WinceStateWinIsTerminal ', a:winid)
    let winnr = s:Win.id2win(a:winid)
    let isterm = winnr && s:Win.getwinvar(winnr, '&buftype') ==# 'terminal'
    if isterm
        call s:Log.DBG('Window ', a:winid, ' is a terminal window')
    else
        call s:Log.DBG('Window ', a:winid, ' is not a terminal window')
    endif
    return isterm
endfunction

function! WinceStateGetWinDimensions(winid)
    call s:Log.DBG('WinceStateGetWinDimensions ', a:winid)
    let nr = s:Win.id2win(a:winid)
    if nr ==# 0
        throw 'no window with winid ' . a:winid
    endif
    let dims = {
   \    'nr': nr,
   \    'w': s:Win.width(nr),
   \    'h': s:Win.height(nr)
   \}
    call s:Log.DBG('Dimensions of window ', a:winid, ': ', dims)
    return dims
endfunction

function! WinceStateGetWinDimensionsList(winids)
    call s:Log.DBG('WinceStateGetWinDimensionsList ', a:winids)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinceStateGetWinDimensions(winid))
    endfor
    call s:Log.DBG('Dimensions of windows ', a:winids, ': ', dim)
    return dim
endfunction

function! WinceStateGetWinRelativeDimensions(winid, offset)
    call s:Log.DBG('WinceStateGetWinRelativeDimensions ', a:winid, ' ', a:offset)
    let nr = s:Win.id2win(a:winid)
    if nr ==# 0
        throw 'no window with winid ' . a:winid
    endif
    if type(a:offset) != v:t_number
        throw 'offset is not a number'
    endif
    let dims = {
   \    'relnr': nr - a:offset,
   \    'w': s:Win.width(nr),
   \    'h': s:Win.height(nr)
   \}
    call s:Log.DBG('Relative dimensions of window ', a:winid, 'with offset ', a:offset, ': ', dims)
    return dims
endfunction

function! WinceStateGetWinRelativeDimensionsList(winids, offset)
    call s:Log.DBG('WinceStateGetWinRelativeDimensionsList ', a:winids, ' ', a:offset)
    if type(a:winids) != v:t_list
        throw 'given winids are not a list'
    endif
    let dim = []
    for winid in a:winids
        call add(dim, WinceStateGetWinRelativeDimensions(winid, a:offset))
    endfor
    call s:Log.DBG('Relative dimensions of windows ', a:winids, 'with offset ', a:offset, ': ', dim)
    return dim
endfunction

" Tab movement
function! WinceStateGotoTab(tabnr)
    call s:Log.INF('WinceStateGotoTab ', a:tabnr)
    execute a:tabnr . 'tabnext'
    call s:MaybeRedraw()
endfunction

" Cursor position preserve/restore
function! WinceStateGetCursorWinId()
    call s:Log.DBG('WinceStateGetCursorWinId')
    let winid = s:Win.getid()
    call s:Log.DBG('Winid of current window: ', winid)
    return winid
endfunction!
function! WinceStateGetCursorPosition()
    call s:Log.DBG('WinceStateGetCursorPosition')
    let winview = winsaveview()
    call s:Log.DBG('Saved cursor position: ', winview)
    return winview
endfunction
function! WinceStateRestoreCursorPosition(pos)
    call s:Log.DBG('WinceStateRestoreCursorPosition ', a:pos)
    call winrestview(a:pos)
endfunction

" Window shielding
function! WinceStateShieldWindow(winid)
     call s:Log.INF('WinceStateShieldWindow ', a:winid)
     noautocmd silent call s:Win.gotoid(a:winid)
     let saved = winsaveview()
     return saved
endfunction

function! WinceStateUnshieldWindow(winid, preshield)
     call s:Log.INF('WinceStateUnshieldWindow ', a:winid, ' ', a:preshield)
     noautocmd silent call s:Win.gotoid(a:winid)
     call winrestview(a:preshield)
endfunction

" Generic Ctrl-W commands
function! WinceStateWincmd(count, cmd, usemode)
    call s:Log.INF('WinceStateWincmd ', a:count, ' ', a:cmd, ' ', a:usemode)
    if type(a:usemode) ==# v:t_dict && !empty(a:usemode)
        noautocmd call jer_mode#ForcePreserve(a:usemode)
        noautocmd call jer_mode#Restore()
    endif
    
    execute a:count . 'wincmd ' . a:cmd
    noautocmd execute "normal \<plug>JerDetectMode"

    call s:MaybeRedraw()

    return jer_mode#Retrieve()
endfunction
function! WinceStateSilentWincmd(count, cmd, usemode)
    call s:Log.INF('WinceStateSilentWincmd ', a:count, ' ', a:cmd, ' ', a:usemode)
    if type(a:usemode) ==# v:t_dict && empty(a:usemode)
        noautocmd call jer_mode#ForcePreserve(a:usemode)
        noautocmd call jer_mode#Restore()
    endif
    
    noautocmd execute a:count . 'wincmd ' . a:cmd
    noautocmd "normal \<plug>JerDetectMode"
    
    call s:MaybeRedraw()

    return jer_mode#Retrieve()
endfunction

" Navigation
function! WinceStateMoveCursorToWinid(winid)
    call s:Log.DBG('WinceStateMoveCursorToWinid ', a:winid)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif
    execute winnr . 'wincmd w'
endfunction

function! WinceStateMoveCursorToWinidSilently(winid)
    call s:Log.DBG('WinceStateMoveCursorToWinidSilently ', a:winid)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif
    noautocmd silent execute winnr . 'wincmd w'
endfunction

function! WinceStateMoveCursorToWinidAndUpdateMode(winid, startmode)
    call s:Log.DBG('WinceStateMoveCursorToWinidAndUpdateMode ', a:winid, ' ', a:startmode)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        return
    endif
    return WinceStateWincmd(winnr, 'w', a:startmode)
endfunction

" Open windows using the toOpen function from a group type and return the
" resulting window IDs. Don't allow any of the new windows to have location
" lists.
function! WinceStateOpenUberwinsByGroupType(grouptype)
    call s:Log.INF('WinceStateOpenUberwinsByGroupType ', a:grouptype.name)
    if !has_key(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let ToOpen = a:grouptype.toOpen
    if type(ToOpen) != v:t_func
        throw 'Given group type has nonfunc toOpen member'
    endif

    let winids = ToOpen()
    call s:Log.INF('Opened uberwin group ', a:grouptype.name, ' with winids ', winids)

    let name = a:grouptype.name
    let widths = a:grouptype.widths
    let heights = a:grouptype.heights
    let typenames = a:grouptype.typenames
    let canhaveloc = a:grouptype.canHaveLoclist
    let statuslines = a:grouptype.statuslines
    for idx in range(0, len(winids) - 1)
        let winnr = s:Win.id2win(winids[idx])
        let typename = typenames[idx]
        let statusline = statuslines[idx]

        if widths[idx] >= 0
            call s:Log.VRB('Fixed width for uberwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixwidth', 1)
        else
            call s:Log.VRB('Free width for uberwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixwidth', 0)
        endif

        if heights[idx] >= 0
            call s:Log.VRB('Fixed height for uberwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixheight', 1)
        else
            call s:Log.VRB('Free height for uberwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixheight', 0)
        endif

        call s:Log.VRB('Set statusline for uberwin ', name, ':', typename, ' to ', statusline)
        call s:Win.setwinvar(winnr, '&statusline', statusline)

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists... Unless the window is itself a location window, in which
        " case of course it should keep its location list. Unfortunately this
        " constitutes special support for the lochelp subwin group.
        if !canhaveloc[idx]
            call s:Win.setloclist(winnr, [])
        endif
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" Close uberwins using the toClose function from a group type
function! WinceStateCloseUberwinsByGroupType(grouptype)
    call s:Log.INF('WinceStateCloseUberwinsByGroupType ', a:grouptype.name)
    if !has_key(a:grouptype, 'toClose')
        throw 'Given group type has no toClose member'
    endif
    
    let ToClose = a:grouptype.toClose
    if type(ToClose) != v:t_func
        throw 'Given group type has nonfunc toClose member'
    endif

    call ToClose()

    call s:MaybeRedraw()
endfunction

" From a given window, open windows using the toOpen function from a group type and
" return the resulting window IDs. Don't allow any of the new windows to have
" location lists.
function! WinceStateOpenSubwinsByGroupType(supwinid, grouptype)
    call s:Log.INF('WinceStateOpenSubwinsByGroupType ', a:supwinid, ':', a:grouptype.name)
    if !has_key(a:grouptype, 'toOpen')
        throw 'Given group type has no toOpen member'
    endif
    
    let ToOpen = a:grouptype.toOpen
    if type(ToOpen) != v:t_func
        throw 'Given group type has nonfunc toOpen member'
    endif

    let supwinnr = s:Win.id2win(a:supwinid)
    if !supwinnr
        throw 'Given supwinid ' . a:supwinid . ' does not exist'
    endif

    execute supwinnr . 'wincmd w'

    let view = winsaveview()
    let winids = ToOpen()
    call winrestview(view)

    call s:Log.INF('Opened subwin group ', a:supwinid, ':', a:grouptype.name, ' with winids ', winids)

    let name = a:grouptype.name
    let widths = a:grouptype.widths
    let heights = a:grouptype.heights
    let typenames = a:grouptype.typenames
    let canhaveloc = a:grouptype.canHaveLoclist
    let statuslines = a:grouptype.statuslines
    for idx in range(0, len(winids) - 1)
        let winnr = s:Win.id2win(winids[idx])
        let typename = typenames[idx]
        let statusline = statuslines[idx]

        if widths[idx] >= 0
            call s:Log.VRB('Fixed width for subwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixwidth', 1)
        else
            call s:Log.VRB('Free width for subwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixwidth', 0)
        endif
        if heights[idx] >= 0
            call s:Log.VRB('Fixed height for subwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixheight', 1)
        else
            call s:Log.VRB('Free height for subwin ', typename)
            call s:Win.setwinvar(winnr, '&winfixheight', 0)
        endif

        call s:Log.VRB('Set statusline for subwin ', a:supwinid, ':', name, ':', typename, ' to ', statusline)
        call s:Win.setwinvar(winnr, '&statusline', statusline)

        " When a window with a loclist splits, Vim gives the new window a
        " loclist. Remove it here so that toOpen doesn't need to worry about
        " loclists... Unless the window is itself a location window, in which
        " case of course it should keep its location list. Unfortunately this
        " constitutes special support for the loclist subwin group.
        if !canhaveloc[idx]
            call setloclist(winnr, [])
        endif
    endfor

    call s:MaybeRedraw()
    return winids
endfunction

" Close subwins of a give supwin using the toClose function from a group type
function! WinceStateCloseSubwinsByGroupType(supwinid, grouptype)
    call s:Log.INF('WinceStateCloseSubwinsByGroupType ', a:supwinid, ':', a:grouptype.name)
    if !has_key(a:grouptype, 'toClose')
        throw 'Given group type has no toClose member'
    endif
    
    let ToClose = a:grouptype.toClose
    if type(ToClose) != v:t_func
        throw 'Given group type has nonfunc toClose member'
    endif

    let supwinnr = s:Win.id2win(a:supwinid)
    if !supwinnr
        throw 'Given supwinid ' . a:supwinid . ' does not exist'
    endif
    execute supwinnr . 'wincmd w'

    let view = winsaveview()
    call ToClose()
    call winrestview(view)

    call s:MaybeRedraw()
endfunction

function! s:PreserveSigns(winid)
    call s:Log.VRB('PreserveSigns ', a:winid)
    let preserved = split(execute('sign place buffer=' . s:Win.bufnr(a:winid)), '\n')
    let re = '^\s*line=\d*\s*id=\d*\s*name=.*$'
    call filter(preserved, 'v:val =~# re')
    call map(preserved, 'split(v:val, "\\s\\+")')
    call s:Log.DBG('Preserved signs: ', preserved)
    return preserved
endfunction

function! s:RestoreSigns(winid, signs)
    call s:Log.VRB('RestoreSigns ', a:winid, ' ...')
    call s:Log.VRB('Preserved signs: ', a:signs)
    let bufnr = s:Win.bufnr(a:winid)
    for [linestr, idstr, namestr] in a:signs
        let signid = substitute(idstr, '^.*id=\(\d*\).*$', '\1', '')
        let signname = substitute(namestr, '^.*name=\(.*\).*$', '\1', '')
        let signline = substitute(linestr, '^.*line=\(\d*\).*$', '\1', '')
        let cmd =  'sign place ' . signid .
       \           ' line=' . signline .
       \           ' name=' . signname .
       \           ' buffer=' . bufnr
        call s:Log.DBG(cmd)
        execute cmd
    endfor
endfunction

function! s:FoldsExist()
    let startline = line('.')

    " If going to the next fold moves the cursor, folds exist
    noautocmd silent normal! zj
    if startline !=# line('.')
        return 1
    endif

    " If going to the previous fold moves the cursor, folds exist
    noautocmd silent normal! zk
    if startline !=# line('.')
        return 1
    endif

    " If the current line is folded, folds exist
    if foldlevel(startline) ># 0
        return 1
    endif

    return 0
endfunction
function! s:PreserveManualFolds()
    call s:Log.VRB('PreserveManualFolds')
    " Output
    let folds = {}

    " Step 0: Make sure folds are enabled so that they can be found
    let &foldenable = 1

    " Step 1: If there are no folds, skip the rest of the computation
    let bell = &belloff
    let &belloff = 'error'
    let foldsexist = s:FoldsExist()
    let &belloff = bell
    if !foldsexist
        return {'explen': line('$'), 'folds': folds}
    endif

    " Step 2: Find folds
    " Stack contains the starting lines of folds whose ending lines have not
    " yet been reached, indexed by their foldlevels. Element 0 has a dummy 0
    " in it because a foldlevel of 0 means the line isn't folded
    let foldstack = [0]

    " Foldlevel of the previous line
    let prevfl = 0
    
    " Traverse every line in the buffer
    for linenr in range(0, line('$') + 1)
        " Pretend there are non-folded lines before and after the real ones
        if linenr <=# 0 || linenr >= line('$') + 1
            let foldlevel = 0
        else
            let foldlevel = foldlevel(linenr)
        endif
        call s:Log.VRB('Line ', linenr, ' has foldlevel ', foldlevel)

        if foldlevel <# 0
            throw 'Negative foldlevel'
        endif

        " If the foldlevel has increased since the previous line, start new
        " folds at the current line - one for each +1 on the foldlevel
        if foldlevel ># prevfl
            for newfl in range(prevfl + 1, foldlevel)
                call s:Log.VRB('Start fold at foldlevel ', newfl)
                call add(foldstack, linenr)
            endfor

        " If the foldlevel has decreased since the previous line, use that
        " line to finish all folds that started since the foldlevel was as
        " small as it is now. Also do this at the end of the buffer, where all
        " folds need to end
        elseif foldlevel <# prevfl
            for biggerfl in range(prevfl, foldlevel + 1, -1)
                if !has_key(folds, biggerfl)
                    let folds[biggerfl] = []
                endif
                call s:Log.VRB('End fold at foldlevel ', biggerfl)
                call add(folds[biggerfl], {
               \    'start': remove(foldstack, biggerfl),
               \    'end': linenr - 1
               \})
            endfor

        " If the foldlevel hasn't changed since the previous line, continue
        " the current fold
        endif

        let prevfl = foldlevel
    endfor

    " Step 3: Determine which folds are closed
    " Vim's fold API cannot see inside closed folds, so we need to open all
    " closed folds after noticing they are closed
    let foldlevels = sort(keys(folds), 'n')
    for foldlevel in foldlevels
        call s:Log.VRB('Examine folds with foldlevel ', foldlevel)
        for afold in folds[foldlevel]
            " If a fold contains any line where foldclosed and foldclosedend
            " don't match with the start and end of the fold, then that fold
            " is open
            let afold.closed = 1
            for linenr in range(afold.start, afold.end, 1)
                if foldclosed(linenr) !=# afold.start ||
               \   foldclosedend(linenr) !=# afold.end
                    call s:Log.VRB('Fold ', afold, ' is open')
                    let afold.closed = 0
                    break
                endif
            endfor

            " If a fold is closed, open it so that later iterations with
            " higher foldlevels can inspect other folds inside
            if afold.closed
                execute afold.start . 'foldopen'
            endif
        endfor
    endfor
    
    " Delete all folds so that if the call to s:RestoreFolds happens in the same
    " window, it'll start with a clean slate
    call s:Log.VRB('Deleting all folds')
    noautocmd silent normal! zE

    let retdict = {'explen': line('$'), 'folds': folds}
    call s:Log.VRB('Preserved manual folds: ', retdict)
    return retdict
endfunction

function! s:PreserveFolds()
    call s:Log.VRB('PreserveFolds')
    if &foldmethod ==# 'manual'
        call s:Log.VRB('Foldmethod is manual')
        return {'method':'manual','data':s:PreserveManualFolds()}
    elseif &foldmethod ==# 'indent'
        call s:Log.VRB('Foldmethod is indent')
        return {'method':'indent','data':''}
    elseif &foldmethod ==# 'expr'
        call s:Log.VRB('Foldmethod is expr with foldexpr: ', &foldexpr)
        return {'method':'expr','data':&foldexpr}
    elseif &foldmethod ==# 'marker'
        call s:Log.VRB('Foldmethod is marker')
        return {'method':'marker','data':''}
    elseif &foldmethod ==# 'syntax'
        call s:Log.VRB('Foldmethod is syntax')
        return {'method':'syntax','data':''}
    elseif &foldmethos ==# 'diff'
        call s:Log.VRB('Foldmethod is diff')
        return {'method':'diff','data':''}
    else
        throw 'Unknown foldmethod ' . &foldmethod
    endif
endfunction

function! s:RestoreManualFolds(explen, folds)
    call s:Log.VRB('RestoreManualFolds ', a:explen, ' ', a:folds)
    if line('$') <# a:explen
        throw 'Buffer contents have shrunk since folds were preserved'
    endif
    for linenr in range(1, line('$'), 1)
        if foldlevel(linenr) !=# 0
            throw 'Folds already exist'
        endif
    endfor

    for foldlevel in reverse(sort(copy(keys(a:folds)), 'n'))
        for afold in a:folds[foldlevel]
            call s:Log.VRB('Applying fold ', afold)
            execute afold.start . ',' . afold.end . 'fold'
            if !afold.closed
                execute afold.start . 'foldopen'
            endif
        endfor
    endfor
endfunction

function! s:RestoreFolds(method, data)
    call s:Log.INF('RestoreFolds ', a:method, ' ', a:data)
    if a:method ==# 'manual'
        let &foldmethod = 'manual'
        call s:RestoreManualFolds(a:data.explen, a:data.folds)
    elseif a:method ==# 'indent'
        let &foldmethod = 'indent'
    elseif a:method ==# 'expr'
        let &foldmethod = 'expr'
        let &foldexpr = a:data
    elseif a:method ==# 'marker'
        let &foldmethod = 'marker'
    elseif a:method ==# 'syntax'
        let &foldmethod = 'syntax'
    elseif a:method ==# 'diff'
        let &foldmethod = 'diff'
    else
        throw 'Unknown foldmethod ' . &foldmethod
    endif
endfunction

function! WinceStateAfterimageWindow(winid)
    call s:Log.DBG('WinceStateAfterimageWindow ', a:winid)
    " Silent movement (noautocmd) is used here because we want to preserve the
    " state of the window exactly as it was when the function was first
    " called, and autocmds may fire on wincmd w that change the state
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif
    noautocmd silent execute winnr . 'wincmd w'

    " Preserve cursor and scroll position
    let view = winsaveview()

    " Preserve some buffer-local options
    let bufsyn = &l:syntax
    let bufsynmc = &l:synmaxcol
    let bufspll = &l:spelllang
    let bufsplc = &l:spellcapcheck
    let bufts = &l:tabstop
    " These options are documented as window-local, but behave in buffer-local
    " ways
    let bufw = &l:wrap
    let bufl = &l:list
    let bufsl = &l:statusline
    let bufcc = &l:colorcolumn
    
    call s:Log.VRB(' syntax: ', bufsyn, ', synmaxcol: ', bufsynmc, ', spelllang: ', bufspll, ', spellcapcheck: ', bufsplc, ', tabstop: ', bufts, ', wrap: ', bufw, ', list: ', bufl, ', statusline: ', bufsl, ', colorcolumn: ', bufcc)

    " Preserve folds
    try
        let folds = s:PreserveFolds()
    catch /.*/
        call s:Log.WRN('Failed to preserve folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        let folds = {'method':'manual','data':{}}
    endtry
    call s:MaybeRedraw()

    " Preserve signs, but also unplace them so that they don't show up if the
    " real buffer is reused for another supwin
    let signs = s:PreserveSigns(a:winid)
    for [linestr, idstr, namestr] in signs
        let signid = substitute(idstr, '^.*id=\(\d*\).*$', '\1', '')
        call s:Log.VRB('Unplace sign ', signid)
        execute 'sign unplace ' . signid
    endfor
    call s:MaybeRedraw()

    " Preserve buffer contents
    let bufcontents = getline(0, '$')
    call s:Log.VRB('Buffer contents: ', bufcontents)

    " Switch to a new hidden scratch buffer. This will be the afterimage buffer
    " noautocmd is used here because undotree has autocmds that fire when you
    " enew from the tree window and close the diff window
    noautocmd enew!
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nobuflisted
    call s:MaybeRedraw()

    " Restore buffer contents
    call setline(1, bufcontents)
    call s:MaybeRedraw()

    " Restore signs
    call s:RestoreSigns(a:winid, signs)
    call s:MaybeRedraw()

    " Restore folds
    try
        call s:RestoreFolds(folds.method, folds.data)
    catch /.*/
        call s:Log.WRN('Failed to restore folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
    endtry
    call s:MaybeRedraw()

    " Restore options
    let &l:syntax = bufsyn   
    let &l:synmaxcol = bufsynmc 
    let &l:spelllang = bufspll  
    let &l:spellcapcheck = bufsplc  
    let &l:tabstop = bufts    
    let &l:wrap = bufw     
    let &l:list = bufl     
    let &l:statusline = bufsl    
    let &l:colorcolumn = bufcc    
    call s:MaybeRedraw()

    " Restore cursor and scroll position
    call winrestview(view)
    call s:MaybeRedraw()

    " Return afterimage buffer ID
    let aibuf = winbufnr('')
    call s:Log.INF('Afterimaged window ', a:winid, ' with buffer ', aibuf)
    return aibuf
endfunction

function! WinceStateCloseWindow(winid, belowright)
    call s:Log.INF('WinceStateCloseWindow ', a:winid, ' ', a:belowright)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif

    " :close fails if called on the last window. Explicitly exit Vim if
    " there's only one window left.
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        call s:Log.INF('Window ', a:winid, ' is the last window. Exiting Vim.')
        quit
    endif
    
    let oldsr = &splitright
    let oldsb = &splitbelow
    let &splitright = a:belowright
    let &splitbelow = a:belowright
    noautocmd execute winnr . 'close'
    let &splitright = oldsr
    let &splitbelow = oldsb

    call s:MaybeRedraw()
endfunction

let s:preservedwinopts = [
\    'scroll',
\    'linebreak',
\    'breakindent',
\    'breakindentopt',
\    'list',
\    'number',
\    'relativenumber',
\    'numberwidth',
\    'conceallevel',
\    'concealcursor',
\    'cursorcolumn',
\    'cursorline',
\    'colorcolumn',
\    'spell',
\    'scrollbind',
\    'cursorbind',
\    'termwinsize',
\    'termwinkey',
\    'termwinscroll',
\    'foldenable',
\    'foldlevel',
\    'foldcolumn',
\    'foldtext',
\    'foldminlines',
\    'foldexpr',
\    'foldignore',
\    'foldmarker',
\    'foldnestmax',
\    'diff',
\    'rightleft',
\    'rightleftcmd',
\    'arabic',
\    'iminsert',
\    'imsearch',
\    'signcolumn'
\]

" Preserve/Restore for individual windows
function! WinceStatePreCloseAndReopen(winid)
    call s:Log.INF('WinceStatePreCloseAndReopen ', a:winid)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif
    noautocmd silent execute winnr . 'wincmd w'
    let retdict = {}

    " Preserve cursor position
    let retdict.view = winsaveview()
    call s:Log.VRB(' view: ', retdict.view)

    " Preserve options
    let retdict.opts = {}
    for optname in s:preservedwinopts
        let optval = eval('&l:' . optname)
        call s:Log.VRB('Preserve ', optname, ': ', optval)
        let retdict.opts[optname] = optval
    endfor

    " Preserve folds
    try
        let fold = s:PreserveFolds()
    catch /.*/
        call s:Log.WRN('Failed to preserve folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        let fold = {'method':'manual','data':{}}
    endtry
    let retdict.fold = fold
    call s:MaybeRedraw()

    " Preserve signs
    let retdict.sign = s:PreserveSigns(a:winid)
    call s:MaybeRedraw()

    return retdict
endfunction

function! WinceStatePostCloseAndReopen(winid, preserved)
    call s:Log.INF('WinceStatePostCloseAndReopen ', a:winid, '...')
    call s:Log.VRB(a:preserved)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif
    noautocmd silent execute winnr . 'wincmd w'

    " Restore signs
    call s:RestoreSigns(a:winid, a:preserved.sign)
    call s:MaybeRedraw()

    " Restore folds
    try
        call s:RestoreFolds(a:preserved.fold.method, a:preserved.fold.data)
    catch /.*/
        call s:Log.WRN('Failed to restore folds for window ', a:winid, ':')
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
    endtry
    call s:MaybeRedraw()

    " Restore options
    for [optname, optval] in items(a:preserved.opts)
        execute 'let &l:' . optname . ' = ' . string(optval)
    endfor
  
    " Restore cursor and scroll position
    call winrestview(a:preserved.view)
    call s:MaybeRedraw()
endfunction

function! WinceStateResizeHorizontal(winid, width, preferleftdivider)
    call s:Log.INF('WinceStateResizeHorizontal ', a:winid, ' ', a:width, ' ', a:preferleftdivider)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif
    noautocmd silent execute winnr . 'wincmd w'
    let wasfixed = &winfixwidth
    let &winfixwidth = 0
    if !a:preferleftdivider
        noautocmd execute a:width . 'wincmd |'
        call s:MaybeRedraw()
        let &winfixwidth = wasfixed
        return
    endif
    noautocmd wincmd h
    if winnr() ==# winnr
        noautocmd execute a:width . 'wincmd |'
        call s:MaybeRedraw()
        let &winfixwidth = wasfixed
        return
    elseif &winfixwidth
        noautocmd wincmd p
        noautocmd execute a:width . 'wincmd |'
        call s:MaybeRedraw()
        let &winfixwidth = wasfixed
        return
    endif
    let otherwidth = s:Win.width(0)
    let oldwidth = s:Win.width(winnr)
    let newwidth = otherwidth + oldwidth - a:width
    noautocmd execute newwidth . 'wincmd |'
    call s:MaybeRedraw()
    noautocmd wincmd p
    let &winfixwidth = wasfixed
endfunction

function! WinceStateResizeVertical(winid, height, prefertopdivider)
    call s:Log.INF('WinceStateResizeVertical ', a:winid, ' ', a:height, ' ', a:prefertopdivider)
    let winnr = s:Win.id2win(a:winid)
    if !winnr
        throw 'no window with winid ' . a:winid
    endif
    noautocmd silent execute winnr . 'wincmd w'
    let wasfixed = &winfixheight
    let &winfixheight = 0
    if !a:prefertopdivider
        noautocmd execute a:height . 'wincmd _'
        call s:MaybeRedraw()
        let &winfixheight = wasfixed
        return
    endif
    noautocmd wincmd k

    if winnr() ==# winnr
        noautocmd execute a:height . 'wincmd _'
        call s:MaybeRedraw()
        let &winfixheight = wasfixed
        return
    elseif &winfixheight
        noautocmd wincmd p
        noautocmd execute a:height . 'wincmd _'
        call s:MaybeRedraw()
        let &winfixheight = wasfixed
        return
    endif

    let otherheight = s:Win.height(0)
    let oldheight = s:Win.height(winnr)
    let newheight = otherheight + oldheight - a:height
    noautocmd execute newheight . 'wincmd _'
    call s:MaybeRedraw()
    noautocmd wincmd p
    let &winfixheight = wasfixed
endfunction

function! WinceStateFixednessByWinid(winid)
    call s:Log.DBG('WinceStateFixednessByWinid ', a:winid)
    let winnr = s:Win.id2win(a:winid)
    let fixedness = {
   \    'w': s:Win.getwinvar(winnr, '&winfixwidth'),
   \    'h': s:Win.getwinvar(winnr, '&winfixheight')
   \}
    call s:Log.VRB(fixedness)
    return fixedness
endfunction

function! WinceStateUnfixDimensions(winid)
    call s:Log.INF('WinceStateUnfixDimensions ', a:winid)
    let winnr = s:Win.id2win(a:winid)
    let preunfix = {
   \    'w': s:Win.getwinvar(winnr, '&winfixwidth'),
   \    'h': s:Win.getwinvar(winnr, '&winfixheight')
   \}
    call s:Win.setwinvar(winnr, '&winfixwidth', 0)
    call s:Win.setwinvar(winnr, '&winfixheight', 0)
    call s:Log.VRB(preunfix)
    return preunfix
endfunction

function! WinceStateRefixDimensions(winid, preunfix)
    call s:Log.INF('WinceStateRefixDimensions ', a:winid, ' ', a:preunfix)
    let winnr = s:Win.id2win(a:winid)
    call s:Win.setwinvar(winnr, '&winfixwidth', a:preunfix.w)
    call s:Win.setwinvar(winnr, '&winfixheight', a:preunfix.h)
endfunction

