" Window Model
" See window.vim

" g:tabinitpreresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:tabenterpreresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:preresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:uberwinsaddedresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:supwinsaddedresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:subwinsaddedresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:resolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:postresolvecallbacks = [
"     <funcref>
"     ...
" ]
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
"         toIdentify: <funcref>
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
"         toIdentify: <funcref>
"     }
"     ...
" }
" t:uberwin = {
"     <grouptypename>: {
"         hidden: <0|1>
"         uberwin: {
"             <typename>: {
"                 id: <uberwinid>
"                 nr: <winnr>
"                 w: <width>
"                 h: <height>
"             }
"             ...
"         }
"     }
"     ...
" }
" t:supwin = {
"     <supwinid>: {
"         nr: <winnr>
"         w: <width>
"         h: <height>
"         subwin: {
"             <grouptypename>: {
"                 hidden: <0|1|2>
"                 subwin: {
"                     <typename>: {
"                         afterimaged: <0|1>
"                         id: <subwinid>
"                     }
"                     ...
"                 }
"             }
"             ...
"         }
"     }
"     ...
" }
" t:subwin = {
"     <subwinid>: {
"         supwin: <supwinid>
"         grouptypename: <grouptypename>
"         typename: <typename>
"         aibuf: <burnr>
"         relnr: <relnr>
"         w: <width>
"         h: <height>
"     }
"     ...
" }

" Resolver callbacks and group types are global
let g:tabinitpreresolvecallbacks = []
let g:tabenterpreresolvecallbacks = []
let g:preresolvecallbacks = []
let g:uberwinsaddedresolvecallbacks = []
let g:supwinsaddedresolvecallbacks = []
let g:subwinsaddedresolvecallbacks = []
let g:resolvecallbacks = []
let g:postresolvecallbacks = []
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

" Resolve callback manipulation
function! s:AddTypedResolveCallback(type, callback)
    if type(a:callback) != v:t_func
        throw 'Resolve callback is not a function'
    endif

    if index(g:preresolvecallbacks, a:callback) >= 0
        throw 'Resolve callback is already registered'
    endif

    execute 'call add(g:' . a:type . 'resolvecallbacks, a:callback)'
endfunction
" TODO: Clean up this mess
function! WinModelAddTabInitPreResolveCallback(callback)
    call s:AddTypedResolveCallback('tabinitpre', a:callback)
endfunction
function! WinModelAddTabEnterPreResolveCallback(callback)
    call s:AddTypedResolveCallback('tabenterpre', a:callback)
endfunction
function! WinModelAddPreResolveCallback(callback)
    call s:AddTypedResolveCallback('pre', a:callback)
endfunction
function! WinModelAddUberwinsAddedResolveCallback(callback)
    call s:AddTypedResolveCallback('uberwinsadded', a:callback)
endfunction
function! WinModelAddSupwinsAddedResolveCallback(callback)
    call s:AddTypedResolveCallback('supwinsadded', a:callback)
endfunction
function! WinModelAddSubwinsAddedResolveCallback(callback)
    call s:AddTypedResolveCallback('subwinsadded', a:callback)
endfunction
function! WinModelAddResolveCallback(callback)
    call s:AddTypedResolveCallback('', a:callback)
endfunction
function! WinModelAddPostResolveCallback(callback)
    call s:AddTypedResolveCallback('post', a:callback)
endfunction
function! WinModelTabInitPreResolveCallbacks()
    return g:tabinitpreresolvecallbacks
endfunction
function! WinModelTabEnterPreResolveCallbacks()
    return g:tabenterpreresolvecallbacks
endfunction
function! WinModelPreResolveCallbacks()
    return g:preresolvecallbacks
 endfunction
function! WinModelUberwinsAddedResolveCallbacks()
    return g:uberwinsaddedresolvecallbacks
endfunction
function! WinModelSupwinsAddedResolveCallbacks()
    return g:supwinsaddedresolvecallbacks
endfunction
function! WinModelSubwinsAddedResolveCallbacks()
    return g:subwinsaddedresolvecallbacks
endfunction
function! WinModelResolveCallbacks()
    return g:resolvecallbacks
endfunction
function! WinModelPostResolveCallbacks()
    return g:postresolvecallbacks
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
function! WinModelAssertUberwinTypeExists(grouptypename, typename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    if index(g:uberwingrouptype[a:grouptypename].typenames, a:typename) < 0
        throw 'uberwin group type ' .
       \      a:grouptypename .
       \      ' has no uberwin type ' .
       \      a:typename
    endif
endfunction
function! WinModelAddUberwinGroupType(name, typenames, flag, hidflag, flagcol,
                                     \priority, widths, heights, toOpen, toClose,
                                     \toIdentify)
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
    if type(a:priority) != v:t_number || a:priority <=# 0
        throw 'priority must be a positive number'
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
    if type(a:toIdentify) != v:t_func
        throw 'toIdentify must be a function'
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
    \    'toClose': a:toClose,
    \    'toIdentify': a:toIdentify
    \}
endfunction

" Subwin group type manipulation
function! s:SubwinGroupTypeExists(grouptypename)
    return has_key(g:subwingrouptype, a:grouptypename )
endfunction
function! WinModelAssertSubwinGroupTypeExists(grouptypename)
    if !s:SubwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent subwin group type ' . a:grouptypename
    endif
endfunction
function! WinModelAssertSubwinTypeExists(grouptypename, typename)
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
                                    \toOpen, toClose, toIdentify)
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
    if type(a:priority) != v:t_number || a:priority <= 0
        throw 'priority must be a positive number'
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
    if type(a:toIdentify) != v:t_func
        throw 'toIdentify must be a function'
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
    \    'toClose': a:toClose,
    \    'toIdentify': a:toIdentify
    \}
endfunction

" General Getters

" Returns a list containing the IDs of all uberwins in an uberwin group
function! WinModelUberwinIdsByGroupTypeName(grouptypename)
    call s:AssertWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    let uberwinids = []
    if !WinModelUberwinGroupExists(a:grouptypename) ||
   \   WinModelUberwinGroupIsHidden(a:grouptypename)
        return []
    endif
    for typename in WinModelUberwinTypeNamesByGroupTypeName(a:grouptypename)
        call add(uberwinids, t:uberwin[a:grouptypename].uberwin[typename].id)
    endfor
    return uberwinids
endfunction

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

" Returns a list containing the IDs of all subwins in a subwin group
function! WinModelSubwinIdsByGroupTypeName(supwinid, grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSupwinExists(a:supwinid)
    let subwinids = []
    if !WinModelSubwinGroupExists(a:supwinid, a:grouptypename) ||
   \   WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        return []
    endif
    for typename in WinModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call add(subwinids, t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id)
    endfor
    return subwinids
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
    if index(WinModelSupwinIds(), a:winid) != -1
        return {
       \    'category': 'supwin',
       \    'id': a:winid,
       \    'nr': t:supwin[a:winid].nr,
       \    'w': t:supwin[a:winid].w,
       \    'h': t:supwin[a:winid].h
       \}
    endif

    if index(WinModelSubwinIds(), a:winid) != -1
        return {
       \    'category': 'subwin',
       \    'supwin': t:subwin[a:winid].supwin,
       \    'grouptype': t:subwin[a:winid].grouptypename,
       \    'typename': t:subwin[a:winid].typename,
       \    'relnr': t:subwin[a:winid].relnr,
       \    'w': t:subwin[a:winid].w,
       \    'h': t:subwin[a:winid].h
       \}
    endif

    if index(WinModelUberwinIds(), a:winid) != -1
        for grouptypename in keys(t:uberwin)
            for typename in keys(t:uberwin[grouptypename].uberwin)
                if t:uberwin[grouptypename].uberwin[typename].id == a:winid
                    return {
                   \    'category': 'uberwin',
                   \    'grouptype': grouptypename,
                   \    'typename': typename,
                   \    'nr': t:uberwin[grouptypename].uberwin[typename].nr,
                   \    'w': t:uberwin[grouptypename].uberwin[typename].w,
                   \    'h': t:uberwin[grouptypename].uberwin[typename].h
                   \}
                endif
            endfor
        endfor
    endif

    return {'category': 'none', 'id': a:winid}
endfunction

" Given an info dict from WinModelInfoById, return the window ID
function! WinModelIdByInfo(info)
    if a:info.category ==# 'supwin' || a:info.category ==# 'none'
        if WinModelSupwinExists(a:info.id)
            return a:info.id
        endif
    elseif a:info.category ==# 'uberwin'
        if WinModelUberwinGroupExists(a:info.grouptype) &&
       \   !WinModelUberwinGroupIsHidden(a:info.grouptype)
            return t:uberwin[a:info.grouptype].uberwin[a:info.typename].id
        endif
    elseif a:info.category ==# 'subwin'
        if WinModelSubwinGroupExists(a:info.supwin, a:info.grouptype) &&
       \   !WinModelSubwinGroupIsHidden(a:info.supwin, a:info.grouptype)
            return t:supwin[a:info.supwin].subwin[a:info.grouptype].subwin[a:info.typename].id
        endif
    endif
    return 0
endfunction

" Comparator for sorting uberwin group type names by priority
function! s:CompareUberwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    let priority1 = g:uberwingrouptype[a:grouptypename1].priority
    let priority2 = g:uberwingrouptype[a:grouptypename2].priority

    return priority1 == priority2 ? 0 : priority1 > priority2 ? 1 : -1
endfunction

" Comparator for sorting subwin group type names by priority
function! s:CompareSubwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    let priority1 = g:subwingrouptype[a:grouptypename1].priority
    let priority2 = g:subwingrouptype[a:grouptypename2].priority

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
    for grouptypename in keys(t:supwin[a:supwinid].subwin)
        if t:supwin[a:supwinid].subwin[grouptypename].hidden
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
    " Validate that winids is a list
    if type(a:winids) != v:t_list
        throw 'expected list of winids but got param of type ' . type(a:winids)
    endif

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

" Validate dimensions of an uberwin or supwin to be added to the model
" someplace
function! s:ValidateNewDimensions(category, grouptypename, typename, nr, w, h)
    if type(a:nr) !=# v:t_number || (a:nr !=# -1 && a:nr <=# 0)
        throw "nr must be a positive number or -1"
    endif
    if type(a:w) !=# v:t_number || (a:w !=# -1 && a:w <=# 0)
        throw "w must be a positive number or -1"
    endif
    if type(a:h) !=# v:t_number || (a:h !=# -1 && a:h <=# 0)
        throw "h must be a positive number or -1"
    endif
    if a:category ==# 'uberwin'
        call WinModelAssertUberwinTypeExists(a:grouptypename, a:typename)
        let typeidx = index(g:uberwingrouptype[a:grouptypename].typenames, a:typename)
        let expw = g:uberwingrouptype[a:grouptypename].widths[typeidx]
        let exph = g:uberwingrouptype[a:grouptypename].heights[typeidx]
        " The group type's prescribed width and height are maximums because if
        " Vim is resized into a small terminal, they need to shrink
        if expw !=# -1 && a:w !=# -1 && expw < a:w
            throw 'width ' .
           \      a:w .
           \      ' invalid for ' .
           \      a:grouptypename .
           \      ':' .
           \      a:typename
        endif
        " The group type's prescribed width and height are maximums because if
        " Vim is resized into a small terminal, they need to shrink
        if exph !=# -1 && a:h !=# -1 && exph < a:h
            throw 'height ' .
           \      a:h .
           \      ' invalid for ' .
           \      a:grouptypename .
           \      ':' .
           \      a:typename
        endif
    elseif a:category ==# 'supwin'
        return
    else
        throw 'category is neither uberwin nor supwin'
    endif
endfunction

" Validate a list of dimensions of uberwins or supwins to be added to the
" model someplace
function! s:ValidateNewDimensionsList(category, grouptypename, dims)
    if type(a:dims) !=# v:t_list
        throw 'given dimensions list is not a list'
    endif
    
    if a:category ==# 'uberwin'
        if empty(a:dims)
            let retlist = []
            for i in range(len(g:uberwingrouptype[a:grouptypename].typenames))
                call add(retlist, {
               \    'nr': -1,
               \    'w': -1,
               \    'h': -1 
               \})
            endfor
            return retlist
        endif
        if len(a:dims) !=# len(g:uberwingrouptype[a:grouptypename].typenames)
            throw len(a:dims) . ' is the wrong number of dimensions for ' . a:grouptypename
        endif
    endif

    for typeidx in range(len(g:uberwingrouptype[a:grouptypename].typenames))
        " TODO: Fill in missing dicts with -1,-1,-1
        let dim = a:dims[typeidx]
        let typename = g:uberwingrouptype[a:grouptypename].typenames[typeidx]
        if type(dim) !=# v:t_dict
            throw 'given dimensions are not a dict'
        endif
        for key in ['nr', 'w', 'h']
            if !has_key(dim, key)
                throw 'dimensions must have keys nr, w, and h'
            endif
            call s:ValidateNewDimensions(a:category, a:grouptypename, typename, dim.nr, dim.w, dim.h)
        endfor
    endfor
    return a:dims
endfunction

" Validate dimensions of a subwin to be added to the model someplace
function! s:ValidateNewSubwinDimensions(grouptypename, typename, relnr, w, h)
    if type(a:relnr) !=# v:t_number
        throw "relnr must be a number"
    endif
    if type(a:w) !=# v:t_number || (a:w !=# -1 && a:w <=# 0)
        throw "w must be a positive number or -1"
    endif
    if type(a:h) !=# v:t_number || (a:h !=# -1 && a:h <=# 0)
        throw "h must be a positive number or -1"
    endif
    call WinModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    let typeidx = index(g:subwingrouptype[a:grouptypename].typenames, a:typename)
    let expw = g:subwingrouptype[a:grouptypename].widths[typeidx]
    let exph = g:subwingrouptype[a:grouptypename].heights[typeidx]
    " The group type's prescribed width and height are maximums because if
    " Vim is resized into a small terminal, they need to shrink
    if expw !=# -1 && a:w !=# -1 && expw < a:w
        throw 'width ' . a:w . ' invalid for ' . a:grouptypename . ':' . a:typename
    endif
    " The group type's prescribed width and height are maximums because if
    " Vim is resized into a small terminal, they need to shrink
    if exph !=# -1 && a:h !=# -1 && exph < a:h
        throw 'height ' . a:h . ' invalid for ' . a:grouptypename . ':' . a:typename
    endif
endfunction

" Validate a list of dimensions of subwins to be added to the model someplace
function! s:ValidateNewSubwinDimensionsList(grouptypename, dims)
    if type(a:dims) !=# v:t_list
        throw 'given subwin dimensions list is not a list'
    endif
    if empty(a:dims)
        let retlist = []
        for i in range(len(g:subwingrouptype[a:grouptypename].typenames))
            call add(retlist, {
           \    'relnr': 0,
           \    'w': -1,
           \    'h': -1 
           \})
        endfor
        return retlist
    endif
    if len(a:dims) !=# len(g:subwingrouptype[a:grouptypename].typenames)
        throw len(dims) . ' is the wrong number of dimensions for ' . a:grouptypename
    endif

    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        " TODO: FIll in missing dicts with 0,-1,-1
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        let dim = a:dims[typeidx]

        if type(dim) !=# v:t_dict
            throw 'given subwin dimensions are not a dict'
        endif
        for key in ['relnr', 'w', 'h']
            if !has_key(dim, key)
                throw 'subwin dimensions must have keys relnr, w, and h'
            endif
            call s:ValidateNewSubwinDimensions(
           \    a:grouptypename,
           \    typename,
           \    dim.relnr,
           \    dim.w,
           \    dim.h
           \)
        endfor
    endfor
    return a:dims
endfunction

" Get a dict of all uberwins' toIdentify functions keyed by their group type
function! WinModelToIdentifyUberwins()
    let retdict = {}
    for grouptypename in keys(g:uberwingrouptype)
        let retdict[grouptypename] = g:uberwingrouptype[grouptypename].toIdentify
    endfor
    return retdict
endfunction

" Get a dict of all subwins' toIdentify functions keyed by their group type
function! WinModelToIdentifySubwins()
    let retdict = {}
    for grouptypename in keys(g:subwingrouptype)
        let retdict[grouptypename] = g:subwingrouptype[grouptypename].toIdentify
    endfor
    return retdict
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
    call WinModelAssertUberwinGroupExists(a:grouptypename)
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
function! WinModelUberwinGroupTypeNames()
    return keys(g:uberwingrouptype)
endfunction
function! WinModelShownUberwinGroupTypeNames()
    call s:AssertWinModelExists()
    let grouptypenames = []
    for grouptypename in keys(t:uberwin)
        if !WinModelUberwinGroupIsHidden(grouptypename)
            call add(grouptypenames, grouptypename)
        endif
    endfor
    return sort(grouptypenames, function('s:CompareUberwinGroupTypeNamesByPriority'))
endfunction
function! WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    return g:uberwingrouptype[a:grouptypename].typenames
endfunction
function! WinModelUberwinDimensions(grouptypename, typename)
    call WinModelAssertUberwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    let windict = t:uberwin[a:grouptypename].uberwin[a:typename]
    return {'nr':windict.nr,'w':windict.w,'h':windict.h}
endfunction

function! WinModelAddUberwins(grouptypename, winids, dimensions)
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

        let vdimensions = s:ValidateNewDimensionsList(
       \    'uberwin',
       \    a:grouptypename,
       \    a:dimensions,
       \)
        
        let hidden = 0

        " Build the model for this uberwin group
        let uberwindict = {}
        for i in range(len(a:winids))
            let uberwindict[g:uberwingrouptype[a:grouptypename].typenames[i]] = {
           \    'id': a:winids[i],
           \    'nr': vdimensions[i].nr,
           \    'w': vdimensions[i].w,
           \    'h': vdimensions[i].h
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
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call remove(t:uberwin, a:grouptypename)
endfunction

function! WinModelHideUberwins(grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)

    let t:uberwin[a:grouptypename].hidden = 1
    let t:uberwin[a:grouptypename].uberwin = {}
endfunction

function! WinModelShowUberwins(grouptypename, winids, dimensions)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call WinModelAssertUberwinGroupIsHidden(a:grouptypename)
    call s:ValidateNewWinids(
   \    a:winids,
   \    len(g:uberwingrouptype[a:grouptypename].typenames)
   \)
    let vdimensions = s:ValidateNewDimensionsList(
   \    'uberwin',
   \    a:grouptypename,
   \    a:dimensions,
   \)

    let t:uberwin[a:grouptypename].hidden = 0
    let uberwindict = {}
    for i in range(len(a:winids))
        let uberwindict[g:uberwingrouptype[a:grouptypename].typenames[i]] = {
       \    'id': a:winids[i],
       \    'nr': vdimensions[i].nr,
       \    'w': vdimensions[i].w,
       \    'h': vdimensions[i].h
       \}
    endfor
    let t:uberwin[a:grouptypename].uberwin = uberwindict
endfunction

function! WinModelAddOrShowUberwins(grouptypename, subwinids, dimensions)
    if !WinModelUberwinGroupExists(a:grouptypename)
        call WinModelAddSubwins(a:grouptypename, a:subwinids, a:dimensions)
    else
        call WinModelShowSubwins(a:grouptypename, a:subwinids, a:dimensions)
    endif
endfunction

function! WinModelChangeUberwinIds(grouptypename, winids)
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

function! WinModelChangeUberwinDimensions(grouptypename, typename, nr, w, h)
    call WinModelAssertUberwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    call s:ValidateNewDimensions('uberwin', a:grouptypename, a:typename, a:nr, a:w, a:h)

    let t:uberwin[a:grouptypename].uberwin[a:typename].nr = a:nr
    let t:uberwin[a:grouptypename].uberwin[a:typename].w = a:w
    let t:uberwin[a:grouptypename].uberwin[a:typename].h = a:h
endfunction

function! WinModelChangeUberwinGroupDimensions(grouptypename, dims)
    let vdims = s:ValidateNewDimensionsList('uberwin', a:grouptypename, a:dims)

    for typeidx in range(len(g:uberwingrouptype[a:grouptypename].typenames))
        let typename = g:uberwingrouptype[a:grouptypename].typenames[typeidx]
        call WinModelChangeUberwinDimensions(
       \    a:grouptypename,
       \    typename,
       \    vdims[typeidx].nr,
       \    vdims[typeidx].w,
       \    vdims[typeidx].h
       \)
    endfor
endfunction

" Supwin manipulation
function! WinModelSupwinExists(winid)
    call s:AssertWinModelExists()
    return has_key(t:supwin, a:winid)
endfunction
function! WinModelAssertSupwinExists(winid)
    if !WinModelSupwinExists(a:winid)
        throw 'nonexistent supwin ' . a:winid
    endif
endfunction
function! WinModelAssertSupwinDoesntExist(winid)
    if WinModelSupwinExists(a:winid)
        throw 'supwin ' . a:winid . ' exists'
    endif
endfunction
function! WinModelSupwinDimensions(supwinid)
    call WinModelAssertSupwinExists(a:supwinid)
    let windict = t:supwin[a:supwinid]
    return {'nr':windict.nr,'w':windict.w,'h':windict.h}
endfunction

function! WinModelChangeSupwinDimensions(supwinid, nr, w, h)
    call WinModelAssertSupwinExists(a:supwinid)
    call s:ValidateNewDimensions('supwin', '', '', a:nr, a:w, a:h)

    let t:supwin[a:supwinid].nr = a:nr
    let t:supwin[a:supwinid].w = a:w
    let t:supwin[a:supwinid].h = a:h
endfunction

" Subwin manipulation
function! WinModelSubwinGroupExists(supwinid, grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSupwinExists(a:supwinid)

    return has_key(t:supwin[a:supwinid].subwin, a:grouptypename)
endfunction
function! WinModelAssertSubwinGroupExists(supwinid, grouptypename)
    if !WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has no subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinModelAssertSubwinGroupDoesntExist(supwinid, grouptypename)
    if WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinModelSubwinGroupIsHidden(supwinid, grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    return t:supwin[a:supwinid].subwin[a:grouptypename].hidden
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
    call WinModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    return t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].afterimaged
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
    if !WinModelSupwinExists(a:supwinid)
        return
    elseif WinModelSubwinGroupExists(a:supwinid, a:grouptypename) &&
   \       !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for typename in g:subwingrouptype[a:grouptypename].typenames
            let subwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id
            call s:AssertSubwinListHas(
           \    subwinid,
           \    a:supwinid,
           \    a:grouptypename,
           \    typename
           \)
            call s:ValidateNewSubwinDimensions(
           \    a:grouptypename,
           \    typename,
           \    t:subwin[subwinid].relnr,
           \    t:subwin[subwinid].w,
           \    t:subwin[subwinid].h
           \)
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
        endfor
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
function! WinModelSubwinGroupTypeNames()
    return keys(g:subwingrouptype)
endfunction
function! WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
    call WinModelAssertSupwinExists(a:supwinid)
    let grouptypenames = []
    for grouptypename in keys(t:supwin[a:supwinid].subwin)
        if !WinModelSubwinGroupIsHidden(a:supwinid, grouptypename)
            call add(grouptypenames, grouptypename)
        endif
    endfor
    return sort(grouptypenames, function('s:CompareSubwinGroupTypeNamesByPriority'))
endfunction
function! WinModelSubwinTypeNamesByGroupTypeName(grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    return g:subwingrouptype[a:grouptypename].typenames
endfunction
function! WinModelSubwinDimensions(supwinid, grouptypename, typename)
    call WinModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    let subwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let windict = t:subwin[subwinid]
    return {'relnr':windict.relnr,'w':windict.w,'h':windict.h}
endfunction


function! WinModelAddSupwin(winid, nr, w, h)
    call s:AssertWinModelExists()
    if has_key(t:supwin, a:winid)
        throw 'window ' . a:winid . ' is already a supwin'
    endif
    call s:ValidateNewDimensions('supwin', '', '', a:nr, a:w, a:h)
    let t:supwin[a:winid] = {'subwin':{},'nr':a:nr,'w':a:w,'h':a:h}
endfunction

function! WinModelRemoveSupwin(winid)
    call WinModelAssertSupwinExists(a:winid)

    for grouptypename in keys(t:supwin[a:winid].subwin)
        call WinModelAssertSubwinGroupExists(a:winid, grouptypename)
        for typename in keys(t:supwin[a:winid].subwin[grouptypename].subwin)
            call remove(t:subwin, t:supwin[a:winid].subwin[grouptypename].subwin[typename].id)
        endfor
    endfor

    call remove(t:supwin, a:winid)
endfunction

function! WinModelAddSubwins(supwinid, grouptypename, subwinids, dimensions)
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

        let vdimensions = s:ValidateNewSubwinDimensionsList(
       \    a:grouptypename,
       \    a:dimensions,
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
           \    'aibuf': -1,
           \    'relnr': vdimensions[i].relnr,
           \    'w': vdimensions[i].w,
           \    'h': vdimensions[i].h
           \}
        endfor
    endif

    " Record the model
    let t:supwin[a:supwinid].subwin[a:grouptypename] = {
   \    'hidden': hidden,
   \    'subwin': subwindict
   \}

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelRemoveSubwins(supwinid, grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for subwintypename in keys(t:supwin[a:supwinid].subwin[a:grouptypename].subwin)
            call remove(
           \    t:subwin,
           \    t:supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id
           \)
        endfor
    endif
    call remove(t:supwin[a:supwinid].subwin, a:grouptypename)

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelHideSubwins(supwinid, grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    for subwintypename in keys(t:supwin[a:supwinid].subwin[a:grouptypename].subwin)
        call remove(
       \    t:subwin,
       \    t:supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id
       \)
        let t:supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].afterimaged = 0
    endfor

    let t:supwin[a:supwinid].subwin[a:grouptypename].hidden = 1
    let t:supwin[a:supwinid].subwin[a:grouptypename].subwin = {}

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelShowSubwins(supwinid, grouptypename, subwinids, dimensions)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinGroupIsHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewWinids(
   \    a:subwinids,
   \    len(g:subwingrouptype[a:grouptypename].typenames)
   \)
    let vdimensions = s:ValidateNewSubwinDimensionsList(
   \    a:grouptypename,
   \    a:dimensions,
   \)

    let t:supwin[a:supwinid].subwin[a:grouptypename].hidden = 0
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
       \    'aibuf': -1,
       \    'relnr': vdimensions[i].relnr,
       \    'w': vdimensions[i].w,
       \    'h': vdimensions[i].h
       \}
    endfor
    let t:supwin[a:supwinid].subwin[a:grouptypename].subwin = subwindict

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelAddOrShowSubwins(supwinid, grouptypename, subwinids, dimensions)
    if !WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call WinModelAddSubwins(a:supwinid, a:grouptypename, a:subwinids, a:dimensions)
    else
        call WinModelShowSubwins(a:supwinid, a:grouptypename, a:subwinids, a:dimensions)
    endif
endfunction

function! WinModelChangeSubwinIds(supwinid, grouptypename, subwinids)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewWinids(
   \    a:subwinids,
   \    len(g:subwingrouptype[a:grouptypename].typenames)
   \)
 
    for i in range(len(a:subwinids))
        let typename = g:subwingrouptype[a:grouptypename].typenames[i]

        let oldsubwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id
        let t:subwin[a:subwinids[i]] = t:subwin[oldsubwinid]
        call remove(t:subwin, oldsubwinid)

        let t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id = a:subwinids[i]
    endfor

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelChangeSubwinDimensions(supwinid, grouptypename, typename, relnr, w, h)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewSubwinDimensions(a:grouptypename, a:typename, a:relnr, a:w, a:h)

    let subwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let t:subwin[subwinid].relnr = a:relnr
    let t:subwin[subwinid].w = a:w
    let t:subwin[subwinid].l = a:h

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelChangeSubwinGroupDimensions(supwinid, grouptypename, dims)
    let vdims = s:ValidateNewSubwinDimensionsList(a:grouptypename, a:dims)

    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        call WinModelChangeSubwinDimensions(
       \    a:supwinid,
       \    a:grouptypename,
       \    typename,
       \    vdims[typeidx].relnr,
       \    vdims[typeidx].w,
       \    vdims[typeidx].h
       \)
    endfor
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
    let subwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    call s:AssertSubwinidIsInSubwinList(subwinid)
    let t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].afterimaged = 1
    let t:subwin[subwinid].aibuf = a:aibufnum
    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

" TODO - Some individual types may need an option for a non-default toClose
" callback so that the resolver doesn't have to stomp them with :q! when their groups
" become incomplete
