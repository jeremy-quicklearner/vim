" Window user operations
" See window.vim

" The User Operations
" Add an uberwin group type. One uberwin group type represents one or more uberwins
" which are opened together
" one window
" name:      The name of the uberwin group type
" typenames: The names of the uberwin types in the group
" flag:      Flag to insert into the tabline when the uberwins are shown
" hidflag:   Flag to insert into the tabline when the uberwins are hidden
" flagcol:   Number between 1 and 9 representing which User highlight group
"            to use for the tabline flag
" priority:  uberwins will be opened in order of ascending priority
" widths:    Widths of uberwins. -1 means variable width.
" heights:   Heights of uberwins. -1 means variable height.
" toOpen:    Function that opens uberwins of these types and returns their window
"            IDs. This function is always called with noautocmd
" toClose:   Function that, closes the the uberwins of this group type. This
"            function is always called with noautocmd
function! WinAddUberwinGroupType(name, typenames, flag, hidflag, flagcol,
                                \priority, widths, heights, toOpen, toClose)
    call WinModelAddUberwinGroupType(a:name, a:typenames, a:flag, a:hidflag,
                                    \a:flagcol, a:priority, a:widths, a:heights,
                                    \a:toOpen, a:toClose)
endfunction

function! WinAddUberwinGroup(grouptypename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    let grouptype = g:uberwingrouptype[a:grouptypename]
    call WinStateOpenWindowsByGroupType
    call WinModelAddUberwinGroup(a:grouptypename)
endfunction

function! WinRemoveUberwinGroup(grouptypename)
    " TODO: stub
endfunction

function! WinHideUberwinGroup(grouptypename)
    " TODO: stub
endfunction

function! WinShowUberwinGroup(grouptypename)
    " TODO: stub
endfunction

" Add a subwin group type. One subwin group type represents the types of one or more
" subwins which are opened together
" one window
" name:         The name of the subwin group type
" typenames:    The names of the subwin types in the group
" flag:         Flag to insert into the statusline of the supwin of subwins of
"               types in this group type when the subwins are shown
" hidflag:      Flag to insert into the statusline of the supwin of subwins of
"               types in this group type when the subwins are hidden
" flagcol:      Number between 1 and 9 representing which User highlight group
"               to use for the statusline flag
" priority:     Subwins for a supwin will be opened in order of ascending
"               priority
" afterimaging: If true, afterimage all subwins of types in this group type when
"               they and their supwin lose focus
" widths:       Widths of subwins. -1 means variable width.
" heights:      Heights of subwins. -1 means variable height.
" toOpen:       Function that, when called from the supwin, opens subwins of these
"               types and returns their window IDs. This function is always called
"               with noautocmd
" toClose:      Function that, when called from a supwin, closes the the subwins of
"               this group type for the supwin.
"               This function is always called with noautocmd
function! WinAddSubwinGroupType(name, typenames, flag, hidflag, flagcol,
                                    \priority, afterimaging, widths, heights,
                                    \toOpen, toClose)
    call WinModelAddSubwinGroupType(a:name, a:typenames, a:flag, a:hidflag,
                                   \a:flagcol, a:priority, a:afterimaging,
                                   \a:widths, a:heights, a:toOpen, a:toClose)
endfunction

function! WinAddSubwinGroup(supwinid, grouptype)
    " TODO: stub
endfunction

function! WinRemoveSubwinGroup(supwinid, grouptype)
    " TODO: stub
endfunction

function! WinHideSubwinGroup(supwinid, grouptype)
    " TODO: stub
endfunction

function! WinShowSubwinGroup(supwinid, grouptype)
    " TODO: stub
endfunction

function! WinHideAllSubwins()
    " TODO: stub
endfunction
