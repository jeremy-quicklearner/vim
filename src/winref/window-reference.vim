" Window manipulation

" Subwindow infratructure

" Subwindow types are stored here
let s:subwintypes = {}

" Add a subwindow type
" name:     The name of the subwindow type
" flag:     Flag to insert into the statusline of the superwindow of a
"           subwindow of this type when the subwindow is shown
" flagCol:  A number between 1 and 9 representing which User highlight group
"           to use for the statusline flag
" priority: Subwindows for a superwindow will be opened in order of ascending
"           priority
" afterimg: If true, afterimage all subwindows of this type
" width:    Width of subwindows of this type. -1 means variable width.
" height:   Height of subwindows of this type. -1 means variable height.
" toOpen:   Function that, when called from the superwindow, opens a subwindow
"           of this type and leaves the cursor inside it. This function is
"           always called with autocmd
" toClose:  Function that, when called from a subwindow of this type, closes
"           the subwindow
function! AddSubwinType(name, flag, hidflag, priority, afterimg, width, height, toOpen, toClose)
    s:subwintypes[name] = {
   \    'name': a:name,
   \    'flag': a:flag,
   \    'hidflag': a:hidflag,
   \    'priority': a:priority,
   \    'afterimg': a:afterimg,
   \    'width': a:width,
   \    'height': a:height,
   \    'toOpen': a:toOpen,
   \    'toClose': a:toClose
   \}
endfunction

" Setup window-local variables for subwindow tracking
function! InitWindow(winid, wintype)
    let winnr = win_id2win(winid)
    if getwinvar(winnr, 'wintype', 'null') != 'null'
        echoerr 'Cannot initialize window ' . a:winid . ' as ' . a:wintype .
               \' since it already has type ' . getwinvar(winnr, 'wintype')
        return
    call setwinvar(winnr, 'wintype', a:wintype)

    " Superwindows have subwindows
    if a:wintype == 'sup'
        call setwinvar(winnr, 'subwinsCfg', {})

    " Subwindows have superwindows
    elseif has_key(s:subwintypes, a:wintype)
        call setwinvar(winnr, 'supwin', -1)
    endif
endfunction

" Add a subwindow to a window
function! AddSubwin(type, supwinid)
    if getwinvar(win_id2win(supwinid), 'wintype') != 'sup'
        echoerr 'Cannot add subwindow to non-sup window ' . a:supwinid
        return
    endif

    " Save the current window ID
    let curwinid = win_getid()

    " Go to the superwindow
    noautocmd call win_gotoid(supwinid)

    " Setup the subwindow
    if !has_key(w:subwinsCfg, a:type)
        let w:subwinsCfg[a:type] = {
       \    'type': a:type,
       \    'hidden': 0,
       \}
    endif

    " Return to the current window
    noautocmd call win_gotoid(curwinid)
endfunction

" Remove a subwindow from a window
function! RemoveSubwin(type, supwinid)
    if getwinvar(win_id2win(supwinid), 'wintype') != 'sup'
        echoerr 'Cannot remove subwindow from non-sup window ' . a:supwinid
        return
    endif

    " Save the current window ID
    let curwinid = win_getid()

    " Go to the superwindow
    noautocmd call win_gotoid(supwinid)

    " Remove the subwindow
    if has_key(w:subwinsCfg, a:type)
        call remove(w:subwinsCfg, a:type)
    endif

    " Return to the current window
    noautocmd call win_gotoid(curwinid)
endfunction

" Hide a subwindow for a window
function! HideSubwin(type, supwinid)
    if getwinvar(win_id2win(supwinid), 'wintype') != 'sup'
        echoerr 'Cannot hide subwindow of non-sup window ' . a:supwinid
        return
    endif

    " Save the current window ID
    let curwinid = win_getid()

    " Go to the superwindow
    noautocmd call win_gotoid(supwinid)

    " Hide the subwindow
    if has_key(w:subwinsCfg, a:type)
        let w:subwinsCfg[a:type]['hidden'] = 1
    endif

    " Return to the current window
    noautocmd call win_gotoid(curwinid)
endfunction

" Show a subwindow for a window
function! ShowSubwin(type, supwinid)
    if getwinvar(win_id2win(supwinid), 'wintype') != 'sup'
        echoerr 'Cannot hide subwindow of non-sup window ' . a:supwinid
        return
    endif

    " Save the current window ID
    let curwinid = win_getid()

    " Go to the superwindow
    noautocmd call win_gotoid(supwinid)

    " Show the subwindow
    if has_key(w:subwinsCfg, a:type)
        let w:subwinsCfg[a:type].hidden = 0
    endif

    " Return to the current window
    noautocmd call win_gotoid(curwinid)
endfunction

" PermanentCursorhold Callback that does subwindow manipulation
let s:refSubIsRunning = 0
function! RefreshSubwindows(arg)
    " This function will be called from a nested autocmd. Guard against
    " recursion.
    if s:refSubIsRunning
        return
    endif
    let s:refSubIsRunning = 1

    " If a big change happenes since the last call, setup for a big refresh by
    " closing all subwindows first

    " First non-destructive pass over all superwindows to make sure status is
    " consistent
    let curwinid = win_getid()
    for winnr in range(1, winnr('$'))
        if getwinvar(winnr, 'wintype', '$N$U$L$L$') != 'sup'
            continue
        endif
        noautocmd execute winnr . 'wincmd w'

        " Make sure the superwindow has a status
        if !exists(w:subwinsSts')
            let w:subwinsSts = {}
        endif

        " Non-destructive pass over all subwindows of the superwindow
        for subwin in w:subwinsCfg
            " Make sure all subwindows are in the status
            if !has_key(w:subwinsSts, subwin.type)
                let w:subwinsSts[subwin.type] = {
               \    'type': subwin.type,
               \    'id': -1,
               \    'hidden': -1,
               \    'afterimg': -1
               \}
            endif

            " Compute the superwindow's hidden status
            " Hidden if hidden
            if subwin.hidden == 1
                let w:subwinsSts[subwin.type].hidden = 1

            " Terminal-hidden if non-hidden in a terminal superwindow
            elseif &buftype ==# 'terminal'
                let w:subwinsSts[subwin.type].hidden = 2
            
            " Non-hidden otherwise
            else
                let w:subwinsSts[subwin.type].hidden = 0
            endif

            " Make sure id doesn't refer to a nonexistent window
            if w:subwinSts[subwin.type].id != -1 &&
              \win_id2win(w:subwinSts[subwin.type].id) == 0
                let w:subwinSts[subwin.type].id = -1
            endif
        endfor

        " Make sure every window in the subwindow status is supposed to be
        " there
        for subwinSts in w:subwinsSts
            if !has_key(subwinCfg, subwinSts.type)
                call remove(w:subwinsSts, subwinSts.type)
            endif
        endfor
    endfor
    noautocmd call win_gotoid(curwinid)
    
    " Destructive pass over all previously existing subwindows
    let subwinids = []
    for winnr in range(1, winnr('$'))
        if has_key(s:subwintypes, getwinvar(winnr, 'wintype'))
            call add(subwinids, win_getid(winnr))
        endif
    endfor
    for subwinid in subwinids
        " A subwindow is not orphaned only if its superwindow exists and lists
        " it as a subwindow
        let orphaned = 1
        let supwinnr = !win_id2win(getwinvar(win_id2win(subwinid), 'supwin', -1))
        if supwinnr
            noautocmd execute supwinnr . 'wincmd w'
            for supwinsubwin in w:subwinsSts
                if supwinsubwin.id == subwinid
                    orphaned = 0
                    break
                endif
            endfor
        endif

        " Close the subwindow if it is orphaned
        if orphaned
            noautocmd call win_gotoid(subwinid)
            noautocmd call(s:subwintypes[w:wintype].toClose)
        endif
    endfor

    " Destructive pass over all superwindows
    let supwinids = []
    for winnr in range(1, winnr('$'))
        if getwinvar(winnr, 'wintype', '$N$U$L$L$') == 'sup'
            call add(supwinids, win_getid(winnr))
        endif
    endfor
    for supwinid in supwinids
        noautocmd call win_gotoid(subwinid)

        " Pass over all the superwindow's subwindows
        for subwin in w:subwinsSts
            if subwin.id
                let subwinIsOpen = win_id2win(subwin.id)
                
                " Make sure all hidden/terminal-hidden subwindows are closed
                if subwinIsOpen && subwin.hidden
                    noautocmd call win_gotoid(subwin.id)
                    noautocmd call(s:subwintypes[w:wintype].toClose)
                    noautocmd call win_gotoid(supwinid)
                    let subwin.id = -1

                " Make sure there are no dangling IDs
                elseif !subwinIsOpen
                    let subwin.id = -1
                endif

            " Make sure all non-hidden subwindows are open
            elseif !subwin.hidden
                noautocmd call(s:subwintypes[subwin.type].toOpen)
                let subwinid = win_getid()
                noautocmd call win_gotoid(supwinid)
                let subwin.id = subwinid
            endif
        endfor
    endfor

    " Need to rethink how afterimaging will work
    " Make sure that all non-current superwindows' afterimaged subwindows have
    " afterimages applied
    " Make sure none of the current window's (or current window's superwindow's)
    " subwindows are afterimaged

    let s:refSubIsRunning = 0
endfunction

augroup Subwindow
    autocmd!

    " Refresh the subwindows on every CursorHold event
    autocmd VimEnter,TabNew * call RegisterCursorHoldCallback(function('RefreshSubwindows'), "", 1, -20, 1)

    " All new windows are superwindows by default. Uberwindows and Subwindows
    " are always created with noautocmd-wrapped
    autocmd VimEnter, WinNew * call InitWindow(win_getid(), 'sup')

augroup END

" Disallow splitting subwindows
" Disallow zooming into subwindows
" There'll just be a bunch of mappings in here


" Uberwindow infrastructure

" Add an uberwindow type
function! AddUberwinType(name)
endfunction
" Add an uberwindow
function! AddUberwin(type)
endfunction
" Remove an uberwindow
function! RemoveUberwin(type)
endfunction
" Check if an uberwindow exists
function! UberwinExists(type)
endfunction

" Hide an uberwindow
function! HideUberwin(type)
endfunction
" Show an uberwindow
function! ShowUberwin(type)
endfunction

" Disallow splitting uberwindows
" Disallow zooming into uberwindows
" There'll just be a bunch of mappings in here
