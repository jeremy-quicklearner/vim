" Window manipulation

" Subwindow type groups are stored here
let s:subwingrouptype = {}

" To be called on every new tab page
function! s:InitTab()
    " t:supwin = {
    "     <supwinid>: {
    "         <grouptypename>: {
    "             hidden: <0|1>
    "             afterimaged: <0|1>
    "             subwin: {
    "                 <typename>: {
    "                     id: <subwinid>
    "                 }
    "                 ...
    "             }
    "         }
    "         ...
    "     }
    "     ...
    " }
    let t:supwin = {}

    " t:subwin = {
    "     <subwinid>: {
    "         supwin: <supwinid>
    "         grouptypename: <grouptypename>
    "         typename: <typename>
    "         aibuf: <burnr>
    "     }
    "     ...
    " }
    let t:subwin = {}
endfunction

" Read model

" Function
function! s:
endfunction

" Modify model

" Function
function! s:
endfunction

" Replace the buffer shown in a subwin with a new buffer that has identical
" contents
function! s:Afterimage()
endfunction

function! s:MoveBetweenSupwins(movecmd)
endfunction

" Add a subwin group type. One subwin group type represents one or more
" subwin which are opened together
" one window
" name:      The name of the subwin group type
" typenames: The names of the subwin types in the group
" flags:     Flags to insert into the statusline of the supwin of subwins of
"            types in this group type when the subwins are shown
" hidflags:  Flags to insert into the statusline of the supwin of subwins of
"            types in this group type when the subwins are hidden
" flagcols:  Numbers between 1 and 9 representing which User highlight group
"            to use for the statusline flags
" priority:  Subwins for a supwin will be opened in order of ascending
"            priority
" afterimg:  If true, afterimage all subwins of types in this group type when
"            they and their supwin lose focus
" widths:    Widths of subwins. -1 means variable width.
" heights:   Heights of subwins. -1 means variable height.
" toOpen:    Function that, when called from the supwin, opens subwins of these
"            types and returns their window IDs. This function is always called
"            with noautocmd
" toClose:   Function that, when called from a supwin, closes the the subwins of
"            this group type for the supwin.
"            This function is always called with noautocmd
function! AddSubwinGroupType(name, typenames, flags, hidflags, flagcols, priority,
                            \afterimaging, widths, heights, toOpen, toClose)
   let s:subwingrouptype[a:name] = {
   \    'name': a:name,
   \    'typenames': a:typenames,
   \    'flags': a:flags,
   \    'hidflags': a:hidflags,
   \    'flagcols': a:flagcols,
   \    'priority': a:priority,
   \    'afterimaging': a:afterimaging,
   \    'widths': a:widths,
   \    'heights': a:heights,
   \    'toOpen': a:toOpen,
   \    'toClose': a:toClose
   \}
endfunction

" Add subwins of a group type to a supwin
function! AddSubwins(grouptypename, supwinid, hidden)
endfunction

" Remove subwins of a group type from a supwin
function! RemoveSubwins(grouptypename, supwinid)
endfunction

" Hide subwins of a group type for a supwin
function! HideSubwins(grouptypename, supwinid)
endfunction

" Show subwins of a group type for a supwin
function! ShowSubwins(grouptypename, supwinid)
endfunction

" Move from one subwin to another
function! s:MoveBetweenSupwins(movecmd)
    " TODO: unstub
    execute a:movecmd . 'wincmd w'
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

call AddSubwinGroupType('testSingle',
                       \['testS'],
                       \['[TST]'], ['[HID]'], [1],
                       \0, 1, [-1], [5],
                       \function('TestToOpenSingle'),
                       \function('TestToCloseSingle')) 

call AddSubwinGroupType('testDouble',
                       \['testD1', 'testD2'],
                       \['[TD1]', '[TD2]'], ['[HID]', '[HID]'], [1, 1],
                       \1, 1, [-1, -1], [5, 5],
                       \function('TestToOpenDouble'),
                       \function('TestToCloseDouble')) 
