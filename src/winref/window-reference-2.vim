" Window manipulation

" Subwindow type groups are stored here
let s:subwintypegroups = {}

" To be called on every new tab page
function! s:InitTab()
    " Each tab has supwin dicts and subwin dicts
    let t:supwin = {}
    let t:subwin = {}
endfunction

" To be called on every supwin when it's created
function! s:InitSupwin()
    " If InitTab hasn't been called yet, call it
    if !exists('t:supwin')
        call s:InitTab()
    endif

    " Supwin dict
    let supwin = {}

    " A subwin cannot be made into a supwin
    let winid = win_getid()
    if has_key(t:subwin, winid)
        echoerr 'Cannot make subwin ' . winid . ' into supwin'
        return
    endif

    " Each supwin knows its own ID
    let supwin.id = winid

    " Each supwin initially has no subwins
    let supwin.subwin = {}

    " Add supwin dict to tab
    let t:supwin[winid] = supwin
endfunction

" To be called on every subwin when it's created
function! s:InitSubwin(supwin, typegroup, type)
    if !win_id2win(a:supwin)
        echoerr 'Cannot add subwin to nonexistent supwin ' . a:supwin
        return
    endif

    let winid = win_getid()
    if winid == a:supwin
        echoerr 'Cannot make window ' . winid . ' into a subwin of itself'
        return
    endif

    if has_key(t:subwin, winid)
        echoerr 'Window ' . winid . ' is already a subwin'
        return
    endif

    " If a supwin is becoming a subwin, remove it from the supwin dict
    if has_key(t:supwin, winid)
        call remove(t:supwin, winid)
    endif

    " Subwin dict
    let subwin = {}

    " Each subwin knows its own ID
    let subwin.id = winid

    " Afterimage buffer number. 0 Means the subwindow isn't afterimaged
    let subwin.aibuf = 0

    " Each subwin knows its supwin's ID
    let subwin.supwin = a:supwin

    " Each supwin knows its subwin's ID
    let t:supwin[a:supwin].subwin[a:typegroup][a:type] = winid

    " Add subwin dict to tab
    let t:subwin[winid] = subwin
endfunction

" Replace the buffer shown in a subwin with a new buffer that has identical
" contents
function! s:Afterimage()
    " Only allow afterimaging of subwindows
    let winid = win_getid()
    if !has_key(t:subwin, winid)
        echoerr 'Cannot afterimage non-subwin window ' . winid
        return
    endif

    " Preserve buffer contents
    let bufcontents = getline(0, '$')

    " Preserve some window options
    let bufft = &ft
    let bufwrap = &wrap
    let bufpos = getpos('.')

    " Switch to a new buffer
    noswapfile enew!

    " Restore buffer contents
    call append(0, bufcontents)
    normal Gdd

    " Restore buffer options
    let &ft=bufft
    let &wrap = bufwrap
    call cursor(bufpos[1], bufpos[2], bufpos[3])

    " Don't show the afterimage buffer in the buffer list
    setlocal nobuflisted

    " Update the subwin dict to reflect that the subwin is afterimaged
    let t:subwin[winid].aibuf = winbufnr('')

endfunction

function! s:MoveBetweenSupwins(movecmd)
    let srcwinid = win_getid()
    let curwinid = srcwinid
    let prvwinid = 0
    let dstwinid = 0
    while 1
        let prvwinid = curwinid
        noautocmd execute 'wincmd ' . a:movecmd
        let curwinid = win_getid()

        if has_key(t:supwin, curwinid)
            let dstwinid = curwinid
            break
        endif
        if curwinid == prvwinid
            break
        endif
    endwhile

    noautocmd call win_gotoid(srcwinid)
    if dstwinid
        " Prepare to leave supwin here
        call win_gotoid(dstwinid)
    endif
endfunction

" Add a subwin type group. One subwin type group represents one or more
" subwin which are opened together
" one window
" name:      The name of the subwin type group
" typenames: The names of the subwin types in the group
" flags:     Flags to insert into the statusline of the supwin of subwins of
"            types in this type group when the subwins are shown
" hidflags:  Flags to insert into the statusline of the supwin of subwins of
"            types in this type group when the subwins are hidden
" flagcols:  Numbers between 1 and 9 representing which User highlight group
"            to use for the statusline flags
" priority:  Subwins for a supwin will be opened in order of ascending
"            priority
" afterimg:  If true, afterimage all subwins of types in this type group when
"            they and their supwin lose focus
" widths:    Widths of subwins. -1 means variable width.
" heights:   Heights of subwins. -1 means variable height.
" toOpen:    Function that, when called from the supwin, opens subwins of these
"            types and returns their window IDs. This function is always called
"            with noautocmd
" toClose:   Function that, when called from a supwin, closes the the subwins of
"            this type group for the supwin.
"            This function is always called with noautocmd
function! AddSubwinTypeGroup(name, typenames, flags, hidflags, flagcols, priority,
                            \afterimg, widths, heights, toOpen, toClose)
   let s:subwintypegroups[a:name] = {
   \    'name': a:name,
   \    'typenames': a:typenames,
   \    'flags': a:flags,
   \    'hidflags': a:hidflags,
   \    'flagcols': a:flagcols,
   \    'priority': a:priority,
   \    'afterimg': a:afterimg,
   \    'widths': a:widths,
   \    'heights': a:heights,
   \    'toOpen': a:toOpen,
   \    'toClose': a:toClose
   \}
endfunction

" Add subwins of a group type to a supwin
function! AddSubwins(typegroupname, supwinid, hidden)
    " Check for nonexistent subwin type group
    if !has_key(s:subwintypegroups, a:typegroupname)
        echoerr('Cannot add subwins of nonexistent type group ' . a:typegroupname .
               \ ' to supwin ' . a:supwinid)
        return
    endif
    let typegroup = s:subwintypegroups[a:typegroupname]

    " Check for nonexistent supwin
    if !has_key(t:supwin, a:supwinid)
        echoerr('Cannot add subwins of type group ' . typegroup.name .
               \ ' to nonexistent supwin ' . a:supwinid)
        return
    endif

    " If the supwin already has subwins of this type group, remove them first
    if has_key(t:supwin[a:supwinid].subwin, a:typegroupname)
        call RemoveSubwins(a:typegroupname, a:supwinid)
    endif
    
    " Make sure the supwin has a dict for this type group
    let t:supwin[a:supwinid].subwin[a:typegroupname] = {}

    let t:supwin[a:supwinid].subwin[a:typegroupname].hidden = a:hidden

    " If the subwin is hidden, give a subwin id of 0 for each subwin
    if a:hidden
        for typename in typegroup.typenames
            let t:supwin[a:supwinid].subwin[a:typegroupname][typename] = 0
        endfor
        return
    endif

    " Save the call-time window ID and jump to the supwin
    let curwinid = win_getid()
    noautocmd call win_gotoid(a:supwinid)

    " If the type group takes priority over any subwins that are already open,
    " close them while opening this subwin
    let higherPriorityTypeGroups = []
    for othertypegroupname in keys(t:supwin[a:supwinid].subwin)
        let othertypegroup = s:subwintypegroups[othertypegroupname]

        " Only proceed if these are different subwins
        if othertypegroupname == a:typegroupname
           continue
        endif

        " Only proceed if the subwins aren't hidden
        let othersubwins = t:supwin[a:supwinid].subwin[othertypegroupname]
        if index(othersubwins.values(), 0) != -1
           continue
        endif

        "Only proceed if the subwins don't take precedence
        if othertypegroup.priority > typegroup.priority
           continue
        endif

        " Remove
        call add(higherPriorityTypeGroups, othertypegroupname)
        call call(othertypegroup.toClose, [])
        for othersubwinid in t:supwin[a:supwinid].subwin[othertypegroupname].values()
           call remove(t:subwin, othersubwinid)
        endfor
    endfor

    " Call toOpen and validate the return value
    noautocmd let subwinids = call(typegroup.toOpen, [])
    if len(subwinids) != len(typegroup.typenames)
        echoerr('toOpen() for type group ' . typegroup.name .
               \ ' returned ' . len(subwinids) .
               \ ' winids but ' . len(typegroup.typenames) .
               \ ' expected')
        return
    endif

    " Initialize the newly opened subwins
    for i in range(len(subwinids))
        noautocmd call win_gotoid(subwinids[i])
        call s:InitSubwin(a:supwinid, typegroup.name, typegroup.typenames[i])
    endfor

    " Reopen higher-priority subwins that were closed
    for othertypegroupname in higherPriorityTypeGroups
        
    endfor

    " Restore the call-time window ID
    call win_gotoid(curwinid)

endfunction

" Remove subwins of a group type from a supwin
function! RemoveSubwins(typegroupname, supwinid)
    " Check for nonexistent supwin
    if !has_key(t:supwin, a:supwinid)
        echoerr('Cannot add subwins of type group ' . typegroup.name .
               \ ' to nonexistent supwin ' . a:supwinid)
        return
    endif

    " Check for missing subwin
    if !has_key(t:supwin[a:supwinid].subwin, a:typegroupname)
        echoerr('supwin ' . a:supwinid .
               \ ' has no subwins of type group ' . a:typegroupname)
        return
    endif

    " Save subwin IDs
    let subwinids = values(t:supwin[a:supwinid].subwin[a:typegroupname])

    " Save the call-time window ID
    let curwinid = win_getid()

    " Call toClose
    noautocmd call win_gotoid(a:supwinid)
    noautocmd call call(s:subwintypegroups[a:typegroupname].toClose, [])

    " Remove the closed subwins from t:subwin
    for subwinid in subwinids
        if subwinid
            call remove(t:subwin, subwinid)
        endif
    endfor

    " Remove the type group from t:supwin
    call remove(t:supwin[a:supwinid].subwin, a:typegroupname)

    " Restore the call-time window ID
    call win_gotoid(curwinid)

endfunction

" Hide subwins of a group type for a supwin
function! HideSubwins(typegroupname, supwinid)

endfunction

" Show subwins of a group type for a supwin
function! ShowSubwins(typegroupname, supwinid)

endfunction

augroup Subwindow
    autocmd!
    " Initially, all windows are supwins. InitSubwin overwrites everything
    " that InitSupwin writes
    autocmd VimEnter,WinNew * call s:InitSupwin()
augroup END

" Window navigation with Ctrl
command! -nargs=0 -complete=command GoLeft call s:MoveBetweenSupwins('h')
command! -nargs=0 -complete=command GoDown call s:MoveBetweenSupwins('j')
command! -nargs=0 -complete=command GoUp call s:MoveBetweenSupwins('k')
command! -nargs=0 -complete=command GoRight call s:MoveBetweenSupwins('l')

nnoremap <silent> <c-h> :GoLeft<cr>
nnoremap <silent> <c-j> :GoDown<cr>
nnoremap <silent> <c-k> :GoUp<cr>
nnoremap <silent> <c-l> :GoRight<cr>
tnoremap <silent> <c-h> :GoLeft<cr>
tnoremap <silent> <c-j> :GoDown<cr>
tnoremap <silent> <c-k> :GoUp<cr>
tnoremap <silent> <c-l> :GoRight<cr>

"==========================================================

function! InitTab()
    call s:InitTab()
endfunction
function! Afterimage()
    call s:Afterimage()
endfunction

function! TestToOpenSingle()
    let supwinid = win_getid()
    noautocmd split
    let subwinid = win_getid()
    noautocmd wincmd p
    return [subwinid]
endfunction

function! TestToCloseSingle()
    let supwinid = win_getid()
    let subwinid = t:supwin[supwinid].subwin.testSingle.testS
    noautocmd call win_gotoid(subwinid)
    noautocmd q!
    noautocmd call win_gotoid(supwinid)
endfunction

function! TestToOpenDouble()
    let supwinid = win_getid()
    noautocmd split
    let subwin1id = win_getid()
    noautocmd vsplit
    let subwin2id = win_getid()
    noautocmd call win_gotoid(supwinid)
    return [subwin1id, subwin2id]
endfunction

function! TestToCloseDouble()
    let supwinid = win_getid()
    let subwin1id = t:supwin[supwinid].subwin.testDouble.testD1
    noautocmd call win_gotoid(subwin1id)
    noautocmd q!
    let subwin2id = t:supwin[supwinid].subwin.testDouble.testD2
    noautocmd call win_gotoid(subwin2id)
    noautocmd q!
    noautocmd call win_gotoid(supwinid)
endfunction

call AddSubwinTypeGroup('testSingle',
                       \['testS'],
                       \['[TST]'], ['[HID]'], [1],
                       \0, 1, [-1], [5],
                       \function('TestToOpenSingle'),
                       \function('TestToCloseSingle')) 

call AddSubwinTypeGroup('testDouble',
                       \['testD1', 'testD2'],
                       \['[TD1]', '[TD2]'], ['[HID]', '[HID]'], [1, 1],
                       \1, 1, [-1, -1], [5, 5],
                       \function('TestToOpenDouble'),
                       \function('TestToCloseDouble')) 
