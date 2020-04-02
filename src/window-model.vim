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
"         afterimaging: [ <0|1>, ... ]
"         widths: <num>
"         heights: <num>
"         toOpen: <funcref>
"         toClose: <funcref>
"     }
"     ...
" }
" t:uberwin = {
"     <grouptypename>: {
"         hidden: <0|1|2>
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
"             hidden: <0|1|2>
"             subwin: {
"                 <typename>: {
"                     afterimaged: <0|1>
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
        return
    endif
    let t:uberwin = {}
    let t:supwin = {}
    let t:subwin = {}
endfunction

" Uberwin group type manipulation
function! s:UberwinGroupTypeExists(grouptypename)
    return has_key(g:uberwingrouptype, a:grouptypename )
endfunction
function! WinModelAssertUberwinGroupTypeExists(grouptypename)
    if !s:UberwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent uberwin group type ' . a:grouptypename
    endif
endfunction
function! s:AssertUberwinTypeExists(grouptypename, typename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    if index(g:uberwingrouptype[a:grouptypename].typenames, a:typename) < 0
        throw 'uberwin group type ' .
       \      a:grouptypename .
       \      ' has no uberwin type ' .
       \      a:typename
    endif
endfunction
function! WinModelAddUberwinGroupType(name, typenames, flag, hidflag, flagcol,
                                    \priority, widths, heights, toOpen, toClose)
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
function! WinModelAssertSubwinGroupTypeExists(grouptypename)
    if !s:SubwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent subwin group type ' . a:grouptypename
    endif
endfunction
function! s:AssertSubwinTypeExists(grouptypename, typename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    if index(g:subwingrouptype[a:grouptypename].typenames, a:typename) < 0
        throw 'subwin group type ' .
       \      a:grouptypename .
       \      ' has no subwin type ' .
       \      a:typename
    endif
endfunction
function! WinModelAddSubwinGroupType(name, typenames, flag, hidflag, flagcol,
                                    \priority, afterimaging, widths, heights,
                                    \toOpen, toClose)
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
    if type(a:afterimaging) != v:t_list
        throw 'afterimaging must be a list'
    endif
    for elem in a:afterimaging
        if type(elem) != v:t_number || elem < 0 || elem > 1
            throw 'afterimaging must be a list of 1s or 0s'
        endif
    endfor
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
    if len(a:afterimaging) != numtypes
        throw len(a:afterimaging) . ' afterimaging flags provided for ' . numtypes . ' subwin types'
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

" Given a window ID, return a dict that identifies it within the model
function! WinModelInfoById(winid)
    call s:AssertWinModelExists()
    if index(WinModelSupwinIds(), a:winid) != -1
        return {'category': 'supwin', 'id': a:winid}
    endif

    if index(WinModelSubwinIds(), a:winid) != -1
        return {
       \    'category': 'subwin',
       \    'supwin': t:subwin[a:winid].supwin,
       \    'grouptype': t:subwin[a:winid].grouptypename,
       \    'typename': t:subwin[a:winid].typename
       \}
    endif

    if index(WinModelUberwinIds(), a:winid) != -1
        for grouptypename in keys(t:uberwin)
            for typename in keys(t:uberwin[grouptypename].uberwin)
                if t:uberwin[grouptypename].uberwin[typename].id == a:winid
                    return {
                   \    'category': 'uberwin',
                   \    'grouptype': grouptypename,
                   \    'typename': typename
                   \}
                endif
            endfor
        endfor
    endif

    throw 'winid ' . a:winid . ' is neither uberwin nor supwin nor subwin'
endfunction

" Given an info dict from WinModelInfoById, return the window ID
function! WinModelIdByInfo(info)
    call s:AssertWinModelExists()
    if a:info.category ==# 'supwin'
        if s:SupwinExists(a:info.id)
            return a:info.id
        endif
    elseif a:info.category ==# 'uberwin'
        if !WinModelUberwinGroupIsHidden(a:info.grouptype)
            return t:uberwin[a:info.grouptype].uberwin[a:info.typename].id
        endif
    elseif a:info.category ==# 'subwin'
        if !WinModelSubwinGroupIsHidden(a:info.supwin, a:info.grouptype)
            return t:supwin[a:info.supwin][a:info.grouptype].subwin[a:info.typename].id
        endif
    endif
    return 0
endfunction

" Comparator for sorting uberwin group type names by priority
function! s:CompareUberwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    let priority1 = g:uberwingrouptype[grouptypename1].priority
    let priority2 = g:uberwingrouptype[grouptypename2].priority

    return priority1 == priority2 ? 0 : priority1 > priority2 ? 1 : -1
endfunction

" Comparator for sorting subwin group type names by priority
function! s:CompareSubwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    let priority1 = g:subwingrouptype[grouptypename1].priority
    let priority2 = g:subwingrouptype[grouptypename2].priority

    return priority1 == priority2 ? 0 : priority1 > priority2 ? 1 : -1
endfunction

" Return a list of names of group types of all non-hidden uberwin groups with
" priorities higher than a given, sorted in ascending order of priority
function! WinModelUberwinGroupTypeNamesByMinPriority(minpriority)
    call s:AssertWinModelExists()
    if type(a:minpriority) != v:t_number
        throw 'minpriority must be a number'
    endif

    let grouptypenames = []
    for grouptypename in keys(t:uberwin)
        if t:uberwin[grouptypename].hidden
            continue
        endif
        if g:uberwingrouptype[grouptypename].priority <= a:minpriority
            continue
        endif
        call add(grouptypenames, grouptypename)
    endfor

    call sort(grouptypenames, function('s:CompareUberwinGroupTypeNamesByPriority'))
    return grouptypenames
endfunction

" Return a list of names of group types of all non-hidden subwin groups with
" priority higher than a given, for a given supwin, sorted in ascending order
" of priority
function! WinModelSubwinGroupTypeNamesByMinPriority(supwinid, minpriority)
    call s:AssertWinModelExists()
    if type(a:minpriority) != v:t_number
        throw 'minpriority must be a number'
    endif

    let grouptypenames = []
    for grouptypename in keys(t:supwin[a:supwinid])
        if t:supwin[a:supwinid][grouptypename].hidden
            continue
        endif
        if g:subwingrouptype[grouptypename].priority <= a:minpriority
            continue
        endif
        call add(grouptypenames, grouptypename)
    endfor

    call sort(grouptypenames, function('s:CompareSubwinGroupTypeNamesByPriority'))
    return grouptypenames
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
function! WinModelUberwinGroupExists(grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    return has_key(t:uberwin, a:grouptypename )
endfunction
function! WinModelAssertUberwinGroupExists(grouptypename)
    if !WinModelUberwinGroupExists(a:grouptypename)
        throw 'nonexistent uberwin group ' . a:grouptypename
    endif
endfunction
function! WinModelAssertUberwinGroupDoesntExist(grouptypename)
    if WinModelUberwinGroupExists(a:grouptypename)
        throw 'uberwin group ' . a:grouptypename . ' exists'
    endif
endfunction

function! WinModelUberwinGroupIsHidden(grouptypename)
   call s:AssertWinModelExists()
   call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
   return t:uberwin[ a:grouptypename ].hidden
endfunction
function! WinModelAssertUberwinGroupIsHidden(grouptypename)
   if !WinModelUberwinGroupIsHidden(a:grouptypename)
      throw 'uberwin group ' . a:grouptypename . ' is not hidden'
   endif
endfunction
function! WinModelAssertUberwinGroupIsNotHidden(grouptypename)
   if WinModelUberwinGroupIsHidden(a:grouptypename)
      throw 'uberwin group ' . a:grouptypename . ' is hidden'
   endif
endfunction

function! WinModelAddUberwins(grouptypename, winids)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call WinModelAssertUberwinGroupDoesntExist(a:grouptypename)
    
    " If no winids are supplied, the uberwin is initially hidden
    if !len(a:winids)
        let hidden = 1
        let uberwindict = {}

    " If winids are supplied, the uberwin is initially visible
    else
        call s:ValidateNewWinids(
       \    a:winids,
       \    len(g:uberwingrouptype[a:grouptypename].typenames)
       \)
        
        let hidden = 0

        " Build the model for this uberwin group
        let uberwindict = {}
        for i in range(len(a:winids))
            let uberwindict[g:uberwingrouptype[a:grouptypename].typenames[i]] = {
           \    'id': a:winids[i]
           \}
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
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call remove(t:uberwin, a:grouptypename)
endfunction

function! WinModelHideUberwins(grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)

    let t:uberwin[a:grouptypename].hidden = 1
    let t:uberwin[a:grouptypename].uberwin = {}
endfunction

function! WinModelShowUberwins(grouptypename, winids)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call WinModelAssertUberwinGroupIsHidden(a:grouptypename)
    call s:ValidateNewWinids(
   \    a:winids,
   \    len(g:uberwingrouptype[a:grouptypename].typenames)
   \)

    let t:uberwin[a:grouptypename].hidden = 0
    let uberwindict = {}
    for i in range(len(a:winids))
        let uberwindict[g:uberwingrouptype[a:grouptypename].typenames[i]] = {
       \    'id': a:winids[i]
       \}
    endfor
    let t:uberwin[a:grouptypename].uberwin = uberwindict
endfunction

function! WinModelChangeUberwinIds(grouptypename, winids)
   call s:AssertWinModelExists()
   call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
   call WinModelAssertUberwinGroupExists(a:grouptypename)
   call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)
   call s:ValidateNewWinids(
  \    a:winids,
  \    len(g:uberwingrouptype[a:grouptypename].typenames)
  \)

   let uberwindict = {}
   for i in range(len(a:winids))
       let uberwindict[g:uberwingrouptype[a:grouptypename].typenames[i]] = {
      \     'id': a:winids[i]
      \}
   endfor
   let t:uberwin[a:grouptypename].uberwin = uberwindict
endfunction

function! s:SupwinExists(winid)
    call s:AssertWinModelExists()
    return has_key(t:supwin, a:winid)
endfunction
function! WinModelAssertSupwinExists(winid)
    if !s:SupwinExists(a:winid)
        throw 'nonexistent supwin ' . a:winid
    endif
endfunction
function! WinModelAssertSupwinDoesntExist(winid)
    if s:SupwinExists(a:winid)
        throw 'supwin ' . a:winid . ' exists'
    endif
endfunction

function! s:SubwinGroupExists(supwinid, grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSupwinExists(a:supwinid)

    return has_key(t:supwin[a:supwinid], a:grouptypename)
endfunction
function! WinModelAssertSubwinGroupExists(supwinid, grouptypename)
    if !s:SubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has no subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinModelAssertSubwinGroupDoesntExist(supwinid, grouptypename)
    if s:SubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinModelSubwinGroupIsHidden(supwinid, grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    return t:supwin[a:supwinid][a:grouptypename].hidden
endif
endfunction
function! WinModelAssertSubwinGroupIsHidden(supwinid, grouptypename)
    if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        throw 'subwin group ' .
       \      a:grouptypename .
       \      ' not hidden for supwin ' .
       \      a:supwinid
    endif
endfunction
function! WinModelAssertSubwinGroupIsNotHidden(supwinid, grouptypename)
    if WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        throw 'subwin group ' .
       \      a:grouptypename .
       \      ' is hidden for supwin ' .
       \      a:supwinid
    endif
endfunction
function! WinModelSubwinIsAfterimaged(supwinid, grouptypename, typename)
    call s:AssertSubwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    return t:supwin[a:supwinid][a:grouptypename].subwin[a:typename].afterimaged
endfunction
function! WinModelAssertSubwinIsNotAfterimaged(supwinid, grouptypename, typename)
    if WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, a:typename)
        throw 'subwin ' .
       \      a:grouptypename .
       \      ':' .
       \      a:typename .
       \      ' for supwin ' .
       \      a:supwinid .
       \      ' is not afterimaged'
    endif
endfunction
function! s:SubwinidIsInSubwinList(subwinid)
    call s:AssertWinModelExists()
    return has_key(t:subwin, a:subwinid)
endfunction
function! s:AssertSubwinidIsInSubwinList(subwinid)
    if !s:SubwinidIsInSubwinList(a:subwinid)
        throw 'subwin id ' . a:subwinid . ' not in subwin list'
    endif
endfunction
function! s:AssertSubwinidIsNotInSubwinList(subwinid)
    if s:SubwinidIsInSubwinList(a:subwinid)
        throw 'subwin id ' . a:subwinid . ' is in subwin list'
    endif
endfunction
function! s:SubwinIdFromSubwinList(supwinid, grouptypename, typename)
    call s:AssertWinModelExists()
    let foundsubwinid = 0
    for subwinid in keys(t:subwin)
        let subwin = t:subwin[subwinid]
        if subwin.supwin ==# a:supwinid &&
       \   subwin.grouptypename ==# a:grouptypename &&
       \   subwin.typename ==# a:typename
            if foundsubwinid
                throw 'duplicate subwin ids ' . foundsubwinid . ' and ' .
               \      subwinid ' . found in subwin list for subwin ' .
               \      a:grouptypename . ':' . a:typename . ' of supwin ' .
               \      a:supwinid
            endif
            let foundsubwinid = subwinid
        endif
    endfor
    return foundsubwinid
endfunction
function! s:AssertSubwinIsInSubwinList(supwinid, grouptypename, typename)
    if !s:SubwinIdFromSubwinList(a:supwinid, a:grouptypename, a:typename)
        throw 'subwin ' . a:grouptypename . ':' . a:typename . ' for supwin ' .
       \      a:supwinid . ' not in subwin list'
    endif
endfunction
function! s:AssertSubwinIsNotInSubwinList(supwinid, grouptypename, typename)
    let subwinid = s:SubwinIdFromSubwinList(a:supwinid, a:grouptypename, a:typename)
    if subwinid
        throw 'subwin ' . a:grouptypename . ':' . a:typename . ' for supwin ' .
       \      a:supwinid . ' in subwin list with subwin id ' . subwinid
    endif
endfunction
function! s:AssertSubwinListHas(subwinid, supwinid, grouptypename, typename)
    call s:AssertSubwinidIsInSubwinList(a:subwinid)
    let subwin = t:subwin[a:subwinid]
    if subwin.supwin !=# a:supwinid
        throw 'subwin id ' . a:subwinid . ' in subwin list has supwin id ' .
       \      subwin.supwin
    elseif subwin.grouptypename !=# a:grouptypename
        throw 'subwin id ' . a:subwinid . ' in subwin list has group type name ' .
       \      subwin.grouptypename
    elseif subwin.typename !=# a:typename
        throw 'subwin id ' . a:subwinid . ' in subwin list has type name ' .
       \      subwin.typename
    endif
endfunction
function! s:AssertSubwinGroupIsConsistent(supwinid, grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    if !s:SupwinExists(a:supwinid)
        return
    elseif s:SubwinGroupExists(a:supwinid, a:grouptypename) &&
   \       !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for typename in g:subwingrouptype[a:grouptypename].typenames
            let subwinid = t:supwin[a:supwinid][a:grouptypename].subwin[typename].id
            call s:AssertSubwinListHas(
           \    subwinid,
           \    a:supwinid,
           \    a:grouptypename,
           \    typename
           \)
        endfor
        if WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            if t:subwin[subwinid].aibuf == -1
                throw 'subwin ' .
               \      a:grouptypename .
               \      ':' . typename .
               \      ' (id ' .
               \      subwinid .
               \      ') for supwin ' .
               \      a:supwinid .
               \      ' is afterimaged without an afterimage buffer'
            endif
        else
            if t:subwin[subwinid].aibuf != -1
                throw 'subwin ' .
               \      a:grouptypename .
               \      ':' . typename .
               \      ' (id ' .
               \      subwinid .
               \      ') for supwin ' .
               \      a:supwinid .
               \      ' is not afterimaged but has afterimage buffer ' .
               \      t:subwin[subwinid].aibuf
            endif
        endif
    else
        for typename in g:subwingrouptype[a:grouptypename].typenames
            call s:AssertSubwinIsNotInSubwinList(
           \    a:supwinid,
           \    a:grouptypename,
           \    typename
           \)
        endfor
    endif
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
    call WinModelAssertSupwinExists(a:winid)

    for grouptypename in keys(t:supwin[a:winid])
        call WinModelAssertSubwinGroupExists(a:winid, grouptypename)
        for typename in keys(t:supwin[a:winid][grouptypename].subwin)
            call remove(t:subwin, t:supwin[a:winid][grouptypename].subwin[typename].id)
        endfor
    endfor

    call remove(t:supwin, a:winid)
endfunction

function! WinModelAddSubwins(supwinid, grouptypename, subwinids)
    call s:AssertWinModelExists()
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)
    
    " If no winids are supplied, the uberwin is initially hidden
    if !len(a:subwinids)
        let hidden = 1
        let subwindict = {}

    " If winids are supplied, the subwin is initially visible
    else
        call s:ValidateNewWinids(
       \    a:subwinids,
       \    len(g:subwingrouptype[a:grouptypename].typenames)
       \)
        
        let hidden = 0

        " Build the model for this subwin group
        let subwindict = {}
        for i in range(len(a:subwinids))
            let typename = g:subwingrouptype[a:grouptypename].typenames[i]
            let subwindict[typename] = {
           \    'id': a:subwinids[i],
           \    'afterimaged': 0
           \}

            let t:subwin[a:subwinids[i]] = {
           \    'supwin': a:supwinid,
           \    'grouptypename': a:grouptypename,
           \    'typename': typename,
           \    'aibuf': -1
           \}
        endfor
    endif

    " Record the model
    let t:supwin[a:supwinid][a:grouptypename] = {
   \    'hidden': hidden,
   \    'subwin': subwindict
   \}

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelRemoveSubwins(supwinid, grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for subwintypename in keys(t:supwin[a:supwinid][a:grouptypename].subwin)
            call remove(
           \    t:subwin,
           \    t:supwin[a:supwinid][a:grouptypename].subwin[subwintypename].id
           \)
        endfor
    endif
    call remove(t:supwin[a:supwinid], a:grouptypename)

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelHideSubwins(supwinid, grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    for subwintypename in keys(t:supwin[a:supwinid][a:grouptypename].subwin)
        call remove(
       \    t:subwin,
       \    t:supwin[a:supwinid][a:grouptypename].subwin[subwintypename].id
       \)
        let t:supwin[a:supwinid][a:grouptypename].subwin[subwintypename].afterimaged = 0
    endfor

    let t:supwin[a:supwinid][a:grouptypename].hidden = 1
    let t:supwin[a:supwinid][a:grouptypename].subwin = {}

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelShowSubwins(supwinid, grouptypename, subwinids)
    call s:AssertWinModelExists()
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinGroupIsHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewWinids(
   \    a:subwinids,
   \    len(g:subwingrouptype[a:grouptypename].typenames)
   \)

    let t:supwin[a:supwinid][a:grouptypename].hidden = 0
    let subwindict = {}
    for i in range(len(a:subwinids))
        let typename = g:subwingrouptype[a:grouptypename].typenames[i]
        let subwindict[typename] = {
       \    'id': a:subwinids[i],
       \    'afterimaged': 0
       \}

        let t:subwin[a:subwinids[i]] = {
       \    'supwin': a:supwinid,
       \    'grouptypename': a:grouptypename,
       \    'typename': typename,
       \    'aibuf': -1
       \}
    endfor
    let t:supwin[a:supwinid][a:grouptypename].subwin = subwindict

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelChangeSubwinIds(supwinid, grouptypename, subwinids)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewWinids(
   \    a:subwinids,
   \    len(g:subwingrouptype[a:grouptypename].typenames)
   \)
 
    for i in range(len(a:subwinids))
        let typename = g:subwingrouptype[a:grouptypename].typenames[i]

        let oldsubwinid = t:supwin[a:supwinid][a:grouptypename].subwin[typename].id
        let t:subwin[a:subwinids[i]] = t:subwin[oldsubwinid]
        call remove(t:subwin, oldsubwinid)

        let t:supwin[a:supwinid][a:grouptypename].subwin[typename].id = a:subwinids[i]
    endfor

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelAfterimageSubwin(supwinid, grouptypename, typename, aibufnum)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinIsNotAfterimaged(a:supwinid, a:grouptypename, a:typename)
    let idx = index(g:subwingrouptype[a:grouptypename].typenames, a:typename)
    if !g:subwingrouptype[a:grouptypename].afterimaging[idx]
        throw 'cannot afterimage subwin of non-afterimaging subwin type ' .
       \      a:grouptypename .
       \      ':' .
       \      a:typename
    endif
    if a:aibufnum < 0
        throw 'bad afterimage buffer number ' . a:aibufnum
    endif
    let subwinid = t:supwin[a:supwinid][a:grouptypename].subwin[a:typename].id
    call s:AssertSubwinidIsInSubwinList(subwinid)
    let t:supwin[a:supwinid][a:grouptypename].subwin[a:typename].afterimaged = 1
    let t:subwin[subwinid].aibuf = a:aibufnum
    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

" TODO - group types will need callbacks for incorporating supwins and subwins
" into the model when they spontaneously appear

" TODO - Some individual types need an option for a non-default toClose callback
" so that the resolver doesn't have to stomp them with :q! when their groups
" become incomplete
