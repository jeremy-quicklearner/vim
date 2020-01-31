" Window Model
" See window.vim

" g:uberwingrouptype = {
"     <grouptypename>: {
"         typenames: [ <typename>, ... ]
"         flag: <flag>
"         hidflag: <flag>
"         flagcol: <1-9>
"         priority: <num>
"         widths: <num>
"         heights: <num>
"         toOpen: <funcref>
"         toClose: <funcref>
"     }
"     ...
" }
" g:subwingrouptype = {
"     <grouptypename>: {
"         typenames: [ <typename>, ... ]
"         flag: <flag>
"         hidflag: <flag>
"         flagcol: <1-9>
"         priority: <num>
"         afterimaging: <0|1>
"         widths: <num>
"         heights: <num>
"         toOpen: <funcref>
"         toClose: <funcref>
"     }
"     ...
" }
" t:uberwin = {
"     <grouptypename>: {
"         hidden: <0|1>
"         uberwin: {
"             <typename>: {
"                 id: <uberwinid>
"             }
"             ...
"         }
"     }
"     ...
" }
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
" t:subwin = {
"     <subwinid>: {
"         supwin: <supwinid>
"         grouptypename: <grouptypename>
"         typename: <typename>
"         aibuf: <burnr>
"     }
"     ...
" }

" Group types are global
let g:uberwingrouptype = {}
let g:subwingrouptype = {}

" The rest of the model is tab-specific

function! WinModelExists()
    return exists('t:uberwin')
endfunction
function! s:AssertWinModelExists()
    if !WinModelExists()
        throw "tab-specific model doesn't exist"
    endif
endfunction

" Initialize the tab-specific portion of the model
function! WinModelInit()
    if WinModelExists()
        throw 'tab-specific model already exists'
    endif
    let t:uberwin = {}
    let t:supwin = {}
    let t:subwin = {}
endfunction

" Uberwin group type manipulation
function! s:UberwinGroupTypeExists(grouptypename)
    call s:AssertWinModelExists()
    return has_key(g:uberwingrouptype, a:grouptypename )
endfunction
function! WinModelAssertUberwinGroupTypeExists(grouptypename)
    if !s:UberwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent uberwin group type ' . a:grouptypename
    endif
endfunction
function! WinModelAddUberwinGroupType(name, typenames, flag, hidflag, flagcol,
                                    \priority, widths, heights, toOpen, toClose)
    " The model needs to exist
    call s:AssertWinModelExists()

    " The group type must not already exist
    if s:UberwinGroupTypeExists(a:name)
        throw 'uberwin group type ' . a:name . ' already exists'
    endif

    " All parameters must be of the correct type
    if type(a:name) != v:t_string
        throw 'name must be a string'
    endif
    if type(a:typenames) != v:t_list
        throw 'typenames must be a list'
    endif
    for elem in a:typenames
        if type(elem) != v:t_string
            throw 'typenames must be a list of strings'
        endif
    endfor
    if type(a:flag) != v:t_string
        throw 'flag must be a string'
    endif
    if type(a:hidflag) != v:t_string
        throw 'hidflag must be a string'
    endif
    if type(a:flagcol) != v:t_number ||  a:flagcol > 9 || a:flagcol < 1
       throw 'flagcol must be a number between 1-9 inclusive'
    endif
    if type(a:priority) != v:t_number
        throw 'priority must be a number'
    endif
    if type(a:widths) != v:t_list
        throw 'widths must be a list'
    endif
    for elem in a:widths
        if type(elem) != v:t_number || elem < -1
            throw 'widths must be a list of numbers greater than -2'
        endif
    endfor
    if type(a:heights) != v:t_list
        throw 'heights must be a list'
    endif
    for elem in a:heights
        if type(elem) != v:t_number || elem < -1
            throw 'heights must be a list of numbers greater than -2'
        endif
    endfor
    if type(a:toOpen) != v:t_func
        throw 'toOpen must be a function'
    endif
    if type(a:toClose) != v:t_func
        throw 'toClose must be a function'
    endif

    " All the lists must be the same length
    let numtypes = len(a:typenames)
    if len(a:widths) != numtypes
        throw len(a:widths) . ' widths provided for ' . numtypes . ' uberwin types'
    endif
    if len(a:heights) != numtypes
        throw len(a:heights) . ' heights provided for ' . numtypes . ' uberwin types'
    endif

    " Add the uberwin type group
    let g:uberwingrouptype[a:name] = {
    \    'name': a:name,
    \    'typenames': a:typenames,
    \    'flag': a:flag,
    \    'hidflag': a:hidflag,
    \    'flagcol': a:flagcol,
    \    'priority': a:priority,
    \    'widths': a:widths,
    \    'heights': a:heights,
    \    'toOpen': a:toOpen,
    \    'toClose': a:toClose
    \}
endfunction

" Subwin group type manipulation
function! s:SubwinGroupTypeExists(grouptypename)
    call s:AssertWinModelExists()
    return has_key(g:subwingrouptype, a:grouptypename )
endfunction
function! s:AssertSubwinGroupTypeExists(grouptypename)
    if !s:SubwinGroupTypeExists()
        throw 'nonexistent subwin group type ' . a:grouptypename
    endif
endfunction
function! WinModelAddSubwinGroupType(name, typenames, flag, hidflag, flagcol,
                                    \priority, afterimaging, widths, heights,
                                    \toOpen, toClose)
    " The model needs to exist
    call s:AssertWinModelExists()

    " The group type must not already exist
    if s:SubwinGroupTypeExists(a:name)
        throw 'subwin group type ' . a:name . ' already exists'
    endif

    " All parameters must be of the correct type
    if type(a:name) != v:t_string
        throw 'name must be a string'
    endif
    if type(a:typenames) != v:t_list
        throw 'typenames must be a list'
    endif
    for elem in a:typenames
        if type(elem) != v:t_string
            throw 'typenames must be a list of strings'
        endif
    endfor
    if type(a:flag) != v:t_string
        throw 'flag must be a string'
    endif
    if type(a:hidflag) != v:t_string
        throw 'hidflag must be a string'
    endif
    if type(a:flagcol) != v:t_number ||  a:flagcol > 9 || a:flagcol < 1
       throw 'flagcol must be a number between 1-9 inclusive'
    endif
    if type(a:priority) != v:t_number
        throw 'priority must be a number'
    endif
    if type(a:afterimaging) != v:t_number || a:afterimaging < 0 || a:afterimaging > 1
        throw 'afterimaging must be 1 or 0'
    endif
    if type(a:widths) != v:t_list
        throw 'widths must be a list'
    endif
    for elem in a:widths
        if type(elem) != v:t_number || elem < -1
            throw 'widths must be a list of numbers greater than -2'
        endif
    endfor
    if type(a:heights) != v:t_list
        throw 'heights must be a list'
    endif
    for elem in a:heights
        if type(elem) != v:t_number || elem < -1
            throw 'heights must be a list of numbers greater than -2'
        endif
    endfor
    if type(a:toOpen) != v:t_func
        throw 'toOpen must be a function'
    endif
    if type(a:toClose) != v:t_func
        throw 'toClose must be a function'
    endif

    " All the lists must be the same length
    let numtypes = len(a:typenames)
    if len(a:widths) != numtypes
        throw len(a:widths) . ' widths provided for ' . numtypes . ' subwin types'
    endif
    if len(a:heights) != numtypes
        throw len(a:heights) . ' heights provided for ' . numtypes . ' subwin types'
    endif

    " Add the subwin type group
    let g:subwingrouptype[a:name] = {
    \    'name': a:name,
    \    'typenames': a:typenames,
    \    'flag': a:flag,
    \    'hidflag': a:hidflag,
    \    'flagcol': a:flagcol,
    \    'priority': a:priority,
    \    'afterimaging': a:afterimaging,
    \    'widths': a:widths,
    \    'heights': a:heights,
    \    'toOpen': a:toOpen,
    \    'toClose': a:toClose
    \}
endfunction

" General Getters
"
" Returns a list containing all uberwin IDs
function! WinModelUberwinIds()
    call s:AssertWinModelExists()
    let uberwinids = []
    for grouptype in keys(t:uberwin)
        if t:uberwin[grouptype].hidden
            continue
        endif
        for typename in keys(t:uberwin[grouptype].uberwin)
            call add(uberwinids, t:uberwin[grouptype].uberwin[typename].id)
        endfor
    endfor
    return uberwinids
endfunction

" Returns a list containing all supwin IDs
function! WinModelSupwinIds()
    call s:AssertWinModelExists()
    return map(keys(t:supwin), 'str2nr(v:val)')
endfunction

" Returns a list containing all subwin IDs
function! WinModelSubwinIds()
    call s:AssertWinModelExists()
    return map(keys(t:subwin), 'str2nr(v:val)')
endfunction

" Returns 1 if a winid is represented in the model. 0 otherwise.
function! WinModelWinExists(winid)
    call s:AssertWinModelExists()
    if index(WinModelUberwinIds(), a:winid) > -1
        return 1
    endif
    if index(WinModelSupwinIds(), a:winid) > -1
        return 1
    endif
    if index(WinModelSubwinIds(), a:winid) > -1
        return 1
    endif
    return 0
endfunction
function! s:AssertWinExists(winid)
    if !WinModelWinExists(a:winid)
        throw 'nonexistent window ' . a:winid
    endif
endfunction

" Return the group type name for a window
function! WinModelGroupTypeNameById(winid)
    call s:AssertWinModelExists()
    if index(WinModelSupwinIds(), a:winid) != -1
        return 'supwin'
    endif

    if index(WinModelSubwinIds(), a:winid) != -1
        return t:subwin[a:winid].grouptypename
    endif

    if index(WinModelUberwinIds(), a:winid) != -1
        for grouptypename in keys(t:uberwin)
            for typename in keys(t:uberwin[grouptypename].uberwin)
                if t:uberwin[grouptypename].uberwin[typename].id == a:winid
                    return grouptypename
                endif
            endfor
        endfor
    endif

    return ''
endfunction        

" Validate a list of winids to be added to the model someplace
function! s:ValidateNewWinids(winids, explen)
    " Validate the number of winids
    if a:explen > -1
        if len(a:winids) != a:explen
            throw 'expected ' . a:explen . ' winids but ' len(a:winids) . ' provided'
        endif
    endif

    " All winids must be numbers that aren't already in the model
    " somewhere
    let existingwinids = WinModelUberwinIds() +
                        \WinModelSupwinIds() +
                        \WinModelSubwinIds()
    for winid in a:winids
        if type(winid) != v:t_number
            throw 'winid ' . winid . ' is not a number'
        endif
        if index(existingwinids, winid) != -1
            throw 'winid ' . winid . ' is already in the model'
        endif
    endfor

    " No duplicate winids are allowed
    let l = len(a:winids)
    for i in range(l - 1)
        for j in range(i + 1, l - 1)
            if a:winids[i] == a:winids[j]
                throw 'duplicate winid ' . a:winids[i]
            endif
        endfor
    endfor
endfunction

" Uberwin group manipulation
function! s:UberwinGroupExists(grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    return has_key(t:uberwin, a:grouptypename )
endfunction
function! s:AssertUberwinGroupExists(grouptypename)
    if !s:UberwinGroupExists(a:grouptypename)
        throw 'nonexistent uberwin group ' . a:grouptypename
    endif
endfunction
function! WinModelAddUberwins(winids, grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    if s:UberwinGroupExists(a:grouptypename)
        throw 'uberwin group ' . a:grouptypename . ' already exists'
    endif
    
    " If no winids are supplied, the uberwin is initially hidden
    if !len(a:winids)
        let hidden = 1
        let uberwindict = {}

    " If winids are supplied, the uberwin is initially visible
    else
        call s:ValidateNewWinids(a:winids, len(g:uberwingrouptype[a:grouptypename].typenames))
        
        let hidden = 0

        " Build the model for this uberwin group
        let uberwindict = {}
        for i in range(len(a:winids))
            let uberwindict[g:uberwingrouptype[a:grouptypename].typenames[i]] = {'id': a:winids[i]}
        endfor
    endif

    " Record the model
    let t:uberwin[a:grouptypename] = {
   \    'hidden': hidden,
   \    'uberwin': uberwindict
   \}
endfunction

function! WinModelRemoveUberwins(grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call s:AssertUberwinGroupExists(a:grouptypename)
    call remove(t:uberwin, a:grouptypename)
endfunction

function! WinModelHideUberwins(grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call s:AssertUberwinGroupExists(a:grouptypename)
    if t:uberwin[a:grouptypename].hidden
        throw 'uberwin group ' . a:grouptypename . ' is already hidden'
    endif

    let t:uberwin[a:grouptypename].hidden = 1
    let t:uberwin[a:grouptypename].uberwin = {}
endfunction

function! WinModelShowUberwins(grouptypename, winids)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call s:AssertUberwinGroupExists(a:grouptypename)
    call s:ValidateNewWinids(a:winids, len(g:uberwingrouptype[a:grouptypename].typenames))
    if !t:uberwin[a:grouptypename].hidden
        throw 'uberwin group ' . a:grouptypename . ' is already shown'
    endif

    let t:uberwin[a:grouptypename].hidden = 0
    let uberwindict = {}
    for i in range(len(a:winids))
        let uberwindict[g:uberwingrouptype[a:grouptypename].typenames[i]] = {'id': a:winids[i]}
    endfor
    let t:uberwin[a:grouptypename].uberwin = uberwindict
endfunction

function! WinModelAddSupwin(winid)
    call s:AssertWinModelExists()
    if has_key(t:supwin, a:winid)
        throw 'window ' . a:winid . ' is already a supwin'
    endif
    let t:supwin[a:winid] = {}
endfunction

function! WinModelRemoveSupwin(winid)
    call s:AssertWinModelExists()
    if !has_key(t:supwin, a:winid)
        throw 'no supwin with id ' . a:winid
    endif
    call remove(t:supwin, a:winid)
    " TODO: Also remove all subwins of this supwin
endfunction

function! WinModelAddSubwins(winids, grouptypename, supwinid)
    call s:AssertWinModelExists()
    " TODO: stub
endfunction

function! WinModelRemoveSubwins(grouptypename, supwinid)
    call s:AssertWinModelExists()
    " TODO: stub
endfunction

function! WinModelHideSubwins(grouptypename, supwinid)
   call s:AssertWinModelExists()
   " TODO: stub
endfunction

function! WinModelShowSubwins(grouptypename, supwinid)
   call s:AssertWinModelExists()
   " TODO: stub
endfunction
