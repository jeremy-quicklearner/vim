" Window Model
" See window.vim

" g:tabenterpreresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:supwinsaddedresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:postuseropcallbacks = [
"     <funcref>
"     ...
" ]
" g:uberwingrouptype = {
"     <grouptypename>: {
"         typenames: [ <typename>, ... ]
"         statuslines: [<statusline>, ...]
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
"         statuslines: [<statusline>, ...]
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
" t:prevwin = {
"     category: <'uberwin'|'supwin'|'subwin'|'none'>
"     grouptypename: <grouptypename>
"     grouptype: <grouptype>
"     supwin: <winid>
"     id: <winid>
" }
" t:curwin = {
"     category: <'uberwin'|'supwin'|'subwin'|'none'>
"     grouptypename: <grouptypename>
"     grouptype: <grouptype>
"     supwin: <winid>
"     id: <winid>
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
"         aibuf: <bufnr>
"         relnr: <relnr>
"         w: <width>
"         h: <height>
"     }
"     ...
" }

" Resolver and post-user-operation callbacks and group types are global
if !exists('g:uberwingrouptype')
    call EchomLog('window-model', 'info', 'Initializing global model')
    let g:tabenterpreresolvecallbacks = []
    let g:supwinsaddedresolvecallbacks = []
    let g:postuseropcallbacks = []
    let g:uberwingrouptype = {}
    let g:subwingrouptype = {}
endif

" The rest of the model is tab-specific
function! WinModelExists()
    call EchomLog('window-model', 'debug', 'WinModelExists')
    return exists('t:uberwin')
endfunction

" Initialize the tab-specific portion of the model
function! WinModelInit()
    if WinModelExists()
        return
    endif
    call EchomLog('window-model', 'info', 'WinModelInit')
    let t:prevwin = {'category':'none','id':0}
    let t:curwin = {'category':'none','id':0}
    let t:uberwin = {}
    let t:supwin = {}
    let t:subwin = {}
endfunction

function! s:EnsureWinModelExists()
    call EchomLog('window-model', 'debug', 'EnsureWinModelExists')
    if !WinModelExists()
        call WinModelInit()
    endif
endfunction


" Resolve callback manipulation
function! s:AddTypedCallback(type, callback)
    call EchomLog('window-model', 'debug', 'Callback: ', a:type, ', ', a:callback)
    if type(a:callback) != v:t_func
        throw 'Resolve callback is not a function'
    endif
    if !exists('g:' . a:type . 'callbacks')
        throw 'Callback type ' . a:type . ' does not exist')
    endif
    if eval('index(g:' . a:type . 'callbacks, a:callback)') >= 0
        throw 'Callback is already registered'
    endif

    execute 'call add(g:' . a:type . 'callbacks, a:callback)'
endfunction
function! WinModelAddTabEnterPreResolveCallback(callback)
    call EchomLog('window-model', 'debug', 'TabEnter PreResolve Callback: ', a:callback)
    call s:AddTypedCallback('tabenterpreresolve', a:callback)
endfunction
function! WinModelAddSupwinsAddedResolveCallback(callback)
    call EchomLog('window-model', 'debug', 'SupwinsAdded Resolve Callback: ', a:callback)
    call s:AddTypedCallback('supwinsaddedresolve', a:callback)
endfunction
function! WinModelAddPostUserOperationCallback(callback)
    call EchomLog('window-model', 'debug', 'Post-User Operation Callbacl: ', a:callback)
    call s:AddTypedCallback('postuserop', a:callback)
endfunction
function! WinModelTabEnterPreResolveCallbacks()
    call EchomLog('window-model', 'debug', 'WinModelTabEnterPreResolveCallbacks')
    return g:tabenterpreresolvecallbacks
endfunction
function! WinModelSupwinsAddedResolveCallbacks()
    call EchomLog('window-model', 'debug', 'WinModelSupwinsAddedResolveCallbacks')
    return g:supwinsaddedresolvecallbacks
endfunction
function! WinModelPostUserOperationCallbacks()
    call EchomLog('window-model', 'debug', 'WinModelPostUserOperationCallbacks')
    return g:postuseropcallbacks
endfunction

" Uberwin group type manipulation
function! s:UberwinGroupTypeExists(grouptypename)
    call EchomLog('window-model', 'debug', 'UberwinGroupTypeExists ', a:grouptypename)
    return has_key(g:uberwingrouptype, a:grouptypename )
endfunction
function! WinModelAssertUberwinGroupTypeExists(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertUberwinGroupTypeExists ', a:grouptypename)
    if !s:UberwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent uberwin group type ' . a:grouptypename
    endif
endfunction
function! WinModelAssertUberwinTypeExists(grouptypename, typename)
    call EchomLog('window-model', 'debug', 'WinModelAssertUberwinTypeExists ', a:grouptypename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    if index(g:uberwingrouptype[a:grouptypename].typenames, a:typename) < 0
        throw 'uberwin group type ' .
       \      a:grouptypename .
       \      ' has no uberwin type ' .
       \      a:typename
    endif
endfunction
function! WinModelAddUberwinGroupType(name, typenames, statuslines,
                                     \flag, hidflag, flagcol,
                                     \priority, widths, heights, toOpen, toClose,
                                     \toIdentify)
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
    if type(a:statuslines) != v:t_list
        throw 'statuslines must be a list'
    endif
    for elem in a:statuslines
        if type(elem) != v:t_string
            throw 'statuslines must be a list of strings'
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

    call EchomLog('window-model', 'debug', 'Uberwin Group Type: ', a:name)

    " Add the uberwin type group
    let g:uberwingrouptype[a:name] = {
    \    'name': a:name,
    \    'typenames': a:typenames,
    \    'statuslines': a:statuslines,
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
    call EchomLog('window-model', 'debug', 'SubwinGroupTypeExists ', a:grouptypename)
    return has_key(g:subwingrouptype, a:grouptypename )
endfunction
function! WinModelAssertSubwinGroupTypeExists(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinGroupTypeExists ', a:grouptypename)
    if !s:SubwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent subwin group type ' . a:grouptypename
    endif
endfunction
function! WinModelAssertSubwinTypeExists(grouptypename, typename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinTypeExists ', a:grouptypename, ':', a:typename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    if index(g:subwingrouptype[a:grouptypename].typenames, a:typename) < 0
        throw 'subwin group type ' .
       \      a:grouptypename .
       \      ' has no subwin type ' .
       \      a:typename
    endif
endfunction
function! WinModelSubwinGroupTypeHasAfterimagingSubwin(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinGroupTypeHasAfterimagingSubwin ', a:grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    for idx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        call EchomLog('window-model', 'verbose', 'Checking if ', a:grouptypename, ';', g:subwingrouptype[a:grouptypename].typenames[idx], ' subwin type is afterimaging')
        if g:subwingrouptype[a:grouptypename].afterimaging[idx]
            call EchomLog('window-model', 'debug', 'Subwin group type ', a:grouptypename, ' has afterimaging subwin type ', g:subwingrouptype[a:grouptypename].typenames[idx])
            return 1
        endif
    endfor
    return 0
endfunction
function! WinModelAddSubwinGroupType(name, typenames, statuslines,
                                    \flag, hidflag, flagcol,
                                    \priority, afterimaging, widths, heights,
                                    \toOpen, toClose, toIdentify)
    " All parameters must be of the correct type
    if type(a:name) != v:t_string
        throw 'name must be a string'
    endif
    if type(a:typenames) != v:t_list
        throw 'typenames must be a list'
    endif
    if type(a:statuslines) != v:t_list
        throw 'statuslines must be a list'
    endif
    for elem in a:statuslines
        if type(elem) != v:t_string
            throw 'statuslines must be a list of strings'
        endif
    endfor
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

    call EchomLog('window-model', 'debug', 'Subwin Group Type: ', a:name)

    " Add the subwin type group
    let g:subwingrouptype[a:name] = {
    \    'name': a:name,
    \    'typenames': a:typenames,
    \    'statuslines': a:statuslines,
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

" Previous window info manipulation
function! WinModelPreviousWinInfo()
    call EchomLog('window-model', 'debug', 'WinModelPreviousWinInfo')
    call s:EnsureWinModelExists()
    call EchomLog('window-model', 'debug', 'Previous window: ', t:prevwin)
    return t:prevwin
endfunction

function! WinModelSetPreviousWinInfo(info)
    call EchomLog('window-model', 'info', 'WinModelSetPreviousWinInfo ', a:info)
    if !WinModelIdByInfo(a:info)
        throw "Attempted to set previous window to one that doesn't exist in model: " . string(a:info)
    endif
    let t:prevwin = a:info
endfunction

" Current window info manipulation
function! WinModelCurrentWinInfo()
    call EchomLog('window-model', 'debug', 'WinModelCurrentWinInfo')
    call s:EnsureWinModelExists()
    call EchomLog('window-model', 'debug', 'Current window: ', t:curwin)
    return t:curwin
endfunction

function! WinModelSetCurrentWinInfo(info)
    call EchomLog('window-model', 'info', 'WinModelSetCurrentWinInfo ', a:info)
    if !WinModelIdByInfo(a:info)
        throw "Attempted to set current window to one that doesn't exist in model: " . string(a:info)
    endif
    let t:curwin = a:info
endfunction

" General Getters

" Returns the names of all uberwin groups in the current tab, shown or not
function! WinModelUberwinGroups()
    call EchomLog('window-model', 'debug', 'WinModelUberwinGroups')
    call s:EnsureWinModelExists()
    call EchomLog('window-model', 'debug', 'Uberwin groups: ', keys(t:uberwin))
    return keys(t:uberwin)
endfunction

" Returns a list containing the IDs of all uberwins in an uberwin group
function! WinModelUberwinIdsByGroupTypeName(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelUberwinIdsByGroupTypeName ', a:grouptypename)
    call s:EnsureWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    let uberwinids = []
    if !WinModelUberwinGroupExists(a:grouptypename) ||
   \   WinModelUberwinGroupIsHidden(a:grouptypename)
        call EchomLog('window-model', 'debug', 'No shown uberwin group ', a:grouptypename)
        return []
    endif
    for typename in WinModelUberwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('window-model', 'verbose', 'Uberwin ', a:grouptypename, ':', typename, ' has ID ', t:uberwin[a:grouptypename].uberwin[typename].id)
        call add(uberwinids, t:uberwin[a:grouptypename].uberwin[typename].id)
    endfor
    call EchomLog('window-model', 'debug', 'Uberwin IDs for group ', a:grouptypename, ': ', uberwinids)
    return uberwinids
endfunction

" Returns a list containing all uberwin IDs
function! WinModelUberwinIds()
    call EchomLog('window-model', 'debug', 'WinModelUberwinIds')
    call s:EnsureWinModelExists()
    let uberwinids = []
    for grouptype in keys(t:uberwin)
        if t:uberwin[grouptype].hidden
            call EchomLog('window-model', 'verbose', 'Skipping hidden uberwin group ', grouptype)
            continue
        endif
        for typename in keys(t:uberwin[grouptype].uberwin)
            call EchomLog('window-model', 'verbose', 'Uberwin ', grouptype, ':', typename, ' has ID ', t:uberwin[grouptype].uberwin[typename].id)
            call add(uberwinids, t:uberwin[grouptype].uberwin[typename].id)
        endfor
    endfor
    call EchomLog('window-model', 'debug', 'Uberwin IDs: ', uberwinids)
    return uberwinids
endfunction

" Returns a string with uberwin flags to be included in the tabline, and its
" length (not counting colour-changing escape sequences)
function! WinModelUberwinFlagsStr()
    call EchomLog('window-model', 'debug', 'WinModelUberwinFlagsStr')
    if !WinModelExists()
        call EchomLog('window-model', 'debug', 'No model. Returning empty string.')
        return ['', 0]
    endif

    let flagsstr = ''
    let flagslen = 0

    for grouptypename in WinModelUberwinGroups()
        if WinModelUberwinGroupIsHidden(grouptypename)
            call EchomLog('window-model', 'verbose', 'Hidden uberwin group ', grouptypename, ' contributes ', g:uberwingrouptype[grouptypename].hidflag)
            let flag = g:uberwingrouptype[grouptypename].hidflag
        else
            call EchomLog('window-model', 'verbose', 'Shown uberwin group ', grouptypename, ' contributes ', g:uberwingrouptype[grouptypename].flag)
            let flag = g:uberwingrouptype[grouptypename].flag
        endif
        let flagsstr .= '%' . g:uberwingrouptype[grouptypename].flagcol . '*[' . flag . ']'
        let flagslen += len(flag) + 2
    endfor

    call EchomLog('window-model', 'debug', 'Uberwin flags: ', flagsstr)
    return [flagsstr, flagslen]
endfunction

" Returns a list containing all supwin IDs
function! WinModelSupwinIds()
    call EchomLog('window-model', 'debug', 'WinModelSupwinIds')
    call s:EnsureWinModelExists()
    call EchomLog('window-model', 'debug', 'Supwin IDs: ', map(keys(t:supwin), 'str2nr(v:val)'))
    return map(keys(t:supwin), 'str2nr(v:val)')
endfunction

" Returns the names of all subwin groups for a given supwin, shown or not
function! WinModelSubwinGroupsBySupwin(supwinid)
    call EchomLog('window-model', 'debug', 'WinModelSubwinGroupsBySupwin ', a:supwinid)
    call WinModelAssertSupwinExists(a:supwinid)
    call EchomLog('window-model', 'debug', 'Subwin groups for supwin ', a:supwinid, ': ', keys(t:supwin[a:supwinid].subwin))
    return keys(t:supwin[a:supwinid].subwin)
endfunction

" Returns a list containing the IDs of all subwins in a subwin group
function! WinModelSubwinIdsByGroupTypeName(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinIdsByGroupTypeName ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSupwinExists(a:supwinid)
    if !WinModelSubwinGroupExists(a:supwinid, a:grouptypename) ||
   \   WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        call EchomLog('window-model', 'debug', 'No shown subwin group ', a:supwinid, ':', a:grouptypename)
        return []
    endif
    let subwinids = []
    for typename in WinModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('window-model', 'verbose', 'Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' has ID ', t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id)
        call add(subwinids, t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id)
    endfor
    call EchomLog('window-model', 'debug', 'Subwin IDs for group ', a:supwinid, ':', a:grouptypename, ': ', subwinids)
    return subwinids
endfunction

" Returns which flag to show for a given supwin due to a given subwin group
" type's existence, hiddenness, etc.
function! WinModelSubwinFlagByGroup(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinFlagByGroup ', a:supwinid, ':', a:grouptypename)
    if !WinModelExists() ||
   \   !WinModelSupwinExists(a:supwinid) ||
   \   !WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call EchomLog('window-model', 'debug', 'No subwin group ', a:supwinid, ':', a:grouptypename, '. Returning empty string.')
        return ''
    endif

    if WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        call EchomLog('window-model', 'debug', 'Hidden subwin group ', a:supwinid, ':', a:grouptypename, ' gives ', g:subwingrouptype[a:grouptypename].hidflag)
        let flag = g:subwingrouptype[a:grouptypename].hidflag
    else
        call EchomLog('window-model', 'debug', 'Shown subwin group ', a:supwinid, ':', a:grouptypename, ' gives ', g:subwingrouptype[a:grouptypename].flag)
        let flag = g:subwingrouptype[a:grouptypename].flag
    endif

    return '[' . flag . ']'
endfunction

function! WinModelSubwinFlagCol(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinFlagCol ', a:grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call EchomLog('window-model', 'debug', 'Flag colour is ', g:subwingrouptype[a:grouptypename].flagcol)
    return g:subwingrouptype[a:grouptypename].flagcol
endfunction

" Returns a list containing all subwin IDs
function! WinModelSubwinIds()
    call EchomLog('window-model', 'debug', 'WinModelSubwinIds')
    call s:EnsureWinModelExists()
    call EchomLog('window-model', 'debug', 'Subwin IDs: ', map(keys(t:subwin), 'str2nr(v:val)'))
    return map(keys(t:subwin), 'str2nr(v:val)')
endfunction

" Returns 1 if a winid is represented in the model. 0 otherwise.
function! WinModelWinExists(winid)
    call EchomLog('window-model', 'debug', 'WinModelWinExists ', a:winid)
    call s:EnsureWinModelExists()
    if index(WinModelUberwinIds(), str2nr(a:winid)) > -1
        call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in uberwin list')
        return 1
    endif
    if index(WinModelSupwinIds(), str2nr(a:winid)) > -1
        call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in supwin list')
        return 1
    endif
    if index(WinModelSubwinIds(), a:winid) > -1
        call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in subwin list')
        return 1
    endif
    call EchomLog('window-model', 'debug', 'ID ', a:winid, ' not found')
    return 0
endfunction
function! s:AssertWinExists(winid)
    call EchomLog('window-model', 'debug', 'AssertWinExists ', a:winid)
    if !WinModelWinExists(a:winid)
        throw 'nonexistent window ' . a:winid
    endif
endfunction
function! s:AssertWinDoesntExist(winid)
    call EchomLog('window-model', 'debug', 'AssertWinDoesntExist ', a:winid)
    if WinModelWinExists(a:winid)
        throw 'window ' . a:winid . ' exists'
    endif
endfunction


" Given a window ID, return a dict that identifies it within the model
function! WinModelInfoById(winid)
    call EchomLog('window-model', 'debug', 'WinModelInfoById ', a:winid)
    call EchomLog('window-model', 'verbose', 'Check for ID', a:winid, ' in supwin list')
    if has_key(t:supwin, a:winid)
        call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in supwin list with dimensions [', t:supwin[a:winid].nr, ',', t:supwin[a:winid].w, ',', t:supwin[a:winid].h, ']')
        return {
       \    'category': 'supwin',
       \    'id': a:winid,
       \    'nr': t:supwin[a:winid].nr,
       \    'w': t:supwin[a:winid].w,
       \    'h': t:supwin[a:winid].h
       \}
    endif

    call EchomLog('window-model', 'verbose', 'Check for ID', a:winid, ' in subwin list')
    if has_key(t:subwin, a:winid)
        call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in subwin listas ', t:subwin[a:winid].supwin, ':', t:subwin[a:winid].typename, ' with dimensions [', t:subwin[a:winid].relnr, ',', t:subwin[a:winid].w, ',', t:subwin[a:winid].h, ']')
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

    for grouptypename in keys(t:uberwin)
        for typename in keys(t:uberwin[grouptypename].uberwin)
            call EchomLog('window-model', 'verbose', 'Check for ID ', a:winid, ' in uberwin ', grouptypename, ':', typename)
            if t:uberwin[grouptypename].uberwin[typename].id == a:winid
                call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in uberwin record with dimensions [', t:uberwin[grouptypename].uberwin[typename].nr, ',', t:uberwin[grouptypename].uberwin[typename].w, ',', t:uberwin[grouptypename].uberwin[typename].h, ']')
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

    call EchomLog('window-model', 'debug', 'ID ', a:winid, ' not found in model')
    return {'category': 'none', 'id': a:winid}
endfunction

" Given a supwin id, returns it. Given a subwin ID, returns the ID if the
" supwin if the subwin. Given anything else, fails
function! WinModelSupwinIdBySupwinOrSubwinId(winid)
    call EchomLog('window-model', 'debug', 'WinModelSupwinIdBySupwinOrSubwinId ', a:winid)
    let info = WinModelInfoById(a:winid)
    if info.category ==# 'none'
        throw 'Window with id ' . a:winid . ' is uncategorized'
    endif
    if info.category ==# 'uberwin'
        throw 'Window with id ' . a:winid . ' is an uberwin'
    endif
    if info.category ==# 'supwin'
        call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in supwin list')
        return a:winid
    endif
    if info.category ==# 'subwin'
        call EchomLog('window-model', 'debug', 'ID ', a:winid, ' found in subwin list with supwin ', info.supwin)
        return info.supwin
    endif
    throw 'Control should never reach here'
endfunction

" Given window info, return a statusline for that window. Returns an empty
" string if the window should have the default statusline
function! WinModelStatusLineByInfo(info)
    call EchomLog('window-model', 'debug', 'WinModelStatusLineByInfo ', a:info)
    if !WinModelExists()
        return ''
    endif

    if a:info.category ==# 'supwin' || a:info.category ==# 'none'
        call EchomLog('window-model', 'debug', 'Supwin or uncategorized window carries default statusline')
        return ''
    elseif a:info.category ==# 'uberwin'
        call WinModelAssertUberwinTypeExists(a:info.grouptype, a:info.typename)
        call EchomLog('window-model', 'debug', 'Uberwin type ', a:info.grouptype, ':', a:info.typename, ' specifies statusline')
        let grouptype = g:uberwingrouptype[a:info.grouptype]
    elseif a:info.category ==# 'subwin'
        call WinModelAssertSubwinTypeExists(a:info.grouptype, a:info.typename)
        call EchomLog('window-model', 'debug', 'Subwin type ', a:info.grouptype, ':', a:info.typename, ' specifies statusline')
        let grouptype = g:subwingrouptype[a:info.grouptype]
    endif

    let typeidx = index(grouptype.typenames, a:info.typename)
    call EchomLog('window-model', 'debug', 'Statusline: ', grouptype.statuslines[typeidx])
    return grouptype.statuslines[typeidx]
endfunction

" Given an info dict from WinModelInfoById, return the window ID
function! WinModelIdByInfo(info)
    call EchomLog('window-model', 'debug', 'WinModelIdByInfo ', a:info)
    if a:info.category ==# 'supwin' || a:info.category ==# 'none'
        if WinModelSupwinExists(a:info.id)
            call EchomLog('window-model', 'debug', 'Supwin with ID ', a:info.id, ' found')
            return a:info.id
        endif
        call EchomLog('window-model', 'debug', 'Supwin with ID ', a:info.id, ' not found')
    elseif a:info.category ==# 'uberwin'
        if WinModelUberwinGroupExists(a:info.grouptype) &&
       \   !WinModelUberwinGroupIsHidden(a:info.grouptype)
            call EchomLog('window-model', 'debug', 'Uberwin ', a:info.grouptype, ':', a:info.typename, ' has ID ', t:uberwin[a:info.grouptype].uberwin[a:info.typename].id)
            return t:uberwin[a:info.grouptype].uberwin[a:info.typename].id
        endif
        call EchomLog('window-model', 'debug', 'Uberwin group ', a:info.grouptype, ' not shown')
    elseif a:info.category ==# 'subwin'
        if WinModelSupwinExists(a:info.supwin) &&
       \   WinModelSubwinGroupExists(a:info.supwin, a:info.grouptype) &&
       \   !WinModelSubwinGroupIsHidden(a:info.supwin, a:info.grouptype)
            call EchomLog('window-model', 'debug', 'Subwin ', a:info.supwin, ':', a:info.grouptype, ':', a:info.typename, ' has ID ', t:supwin[a:info.supwin].subwin[a:info.grouptype].subwin[a:info.typename].id)
            return t:supwin[a:info.supwin].subwin[a:info.grouptype].subwin[a:info.typename].id
        endif
        call EchomLog('window-model', 'debug', 'Subwin group ', a:info.supwin, ':', a:info.grouptype, ' not shown')
    endif
    return 0
endfunction

" Comparator for sorting uberwin group type names by priority
function! s:CompareUberwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    call EchomLog('window-model', 'verbose', 'CompareUberwinGroupTypeNamesByMinPriority ', a:grouptypename1, a:grouptypename2)
    let priority1 = g:uberwingrouptype[a:grouptypename1].priority
    let priority2 = g:uberwingrouptype[a:grouptypename2].priority

    return priority1 == priority2 ? 0 : priority1 > priority2 ? 1 : -1
endfunction

" Comparator for sorting subwin group type names by priority
function! s:CompareSubwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    call EchomLog('window-model', 'verbose', 'CompareSubwinGroupTypeNamesByMinPriority ', a:grouptypename1, ' ', a:grouptypename2)
    let priority1 = g:subwingrouptype[a:grouptypename1].priority
    let priority2 = g:subwingrouptype[a:grouptypename2].priority

    return priority1 == priority2 ? 0 : priority1 > priority2 ? 1 : -1
endfunction

" Return a list of names of group types of all non-hidden uberwin groups with
" priorities higher than a given, sorted in ascending order of priority
function! WinModelUberwinGroupTypeNamesByMinPriority(minpriority)
    call EchomLog('window-model', 'debug', 'WinModelUberwinGroupTypeNamesByMinPriority ', a:minpriority)
    call s:EnsureWinModelExists()
    if type(a:minpriority) != v:t_number
        throw 'minpriority must be a number'
    endif

    let grouptypenames = []
    for grouptypename in keys(t:uberwin)
        if t:uberwin[grouptypename].hidden
            call EchomLog('window-model', 'verbose', 'Omitting hidden uberwin group ', grouptypename)
            continue
        endif
        if g:uberwingrouptype[grouptypename].priority <= a:minpriority
            call EchomLog('window-model', 'verbose', 'Omitting uberwin group ', grouptypename, ' due to its low priority ', g:uberwingrouptype[grouptypename].priority)
            continue
        endif
        call EchomLog('window-model', 'verbose', 'Uberwin group ', grouptypename, ' included in query')
        call add(grouptypenames, grouptypename)
    endfor

    call EchomLog('window-model', 'verbose', 'Sorting uberwin groups')
    call sort(grouptypenames, function('s:CompareUberwinGroupTypeNamesByPriority'))
    call EchomLog('window-model', 'debug', 'Uberwin groups: ', grouptypenames)
    return grouptypenames
endfunction

" Return a list of names of group types of all non-hidden subwin groups with
" priority higher than a given, for a given supwin, sorted in ascending order
" of priority
function! WinModelSubwinGroupTypeNamesByMinPriority(supwinid, minpriority)
    call EchomLog('window-model', 'debug', 'WinModelSubwinGroupTypeNamesByMinPriority ', a:supwinid, a:minpriority)
    call s:EnsureWinModelExists()
    if type(a:minpriority) != v:t_number
        throw 'minpriority must be a number'
    endif

    let grouptypenames = []
    for grouptypename in keys(t:supwin[a:supwinid].subwin)
        if t:supwin[a:supwinid].subwin[grouptypename].hidden
            call EchomLog('window-model', 'verbose', 'Omitting hidden subwin group ', a:supwinid, ':', grouptypename)
            continue
        endif
        if g:subwingrouptype[grouptypename].priority <= a:minpriority
            call EchomLog('window-model', 'verbose', 'Omitting subwin group ', a:supwinid, ':', grouptypename, ' due to its low priority ', g:subwingrouptype[grouptypename].priority)
            continue
        endif
        call EchomLog('window-model', 'verbose', 'Subwin group ', a:supwinid, ':', grouptypename, ' included in query')
        call add(grouptypenames, grouptypename)
    endfor

    call EchomLog('window-model', 'verbose', 'Sorting subwin groups')
    call sort(grouptypenames, function('s:CompareSubwinGroupTypeNamesByPriority'))
    call EchomLog('window-model', 'debug', 'Subwin groups: ', grouptypenames)
    return grouptypenames
endfunction

" Validate a list of winids to be added to the model someplace
function! s:ValidateNewWinids(winids, explen)
    call EchomLog('window-model', 'debug', 'ValidateNewWinids ', a:winids, ' ', a:explen)
    " Validate that winids is a list
    if type(a:winids) != v:t_list
        throw 'expected list of winids but got param of type ' . type(a:winids)
    endif

    " Validate the number of winids
    if a:explen > -1
        if len(a:winids) != a:explen
            throw 'expected ' . a:explen . ' winids but ' . len(a:winids) . ' provided'
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
        if index(existingwinids, str2nr(winid)) != -1
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
    call EchomLog('window-model', 'debug', 'ValidateNewDimensions ', a:category, ':', a:grouptypename, ':', a:typename, ' [', a:nr, ',', a:w, ',', a:h, ']')
    if type(a:nr) !=# v:t_number || (a:nr !=# -1 && a:nr <=# 0)
        throw "nr must be a positive number or -1"
    endif
    if type(a:w) !=# v:t_number || a:w <# -1
        throw "w must be at least -1"
    endif
    if type(a:h) !=# v:t_number || a:h <# -1
        throw "h must be at least -1"
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
    call EchomLog('window-model', 'debug', 'ValidateNewDimensionsList ', a:category, ':', a:grouptypename, ' ', a:dims)
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
            call EchomLog('window-model', 'debug', 'Populated dummy dimensions: ', retlist)
            return retlist
        endif
        if len(a:dims) !=# len(g:uberwingrouptype[a:grouptypename].typenames)
            throw len(a:dims) . ' is the wrong number of dimensions for ' . a:grouptypename
        endif
    endif

    for typeidx in range(len(g:uberwingrouptype[a:grouptypename].typenames))
        call EchomLog('window-model', 'verbose', 'Validate dimensions ', a:dims[typeidx])
        " TODO? Fill in missing dicts with -1,-1,-1
        " - This will only be required if there's ever a case where multiple
        "   windows are added to the model at the same time, but only some of
        "   them have non-dummy dimensions
        let dim = a:dims[typeidx]
        let typename = g:uberwingrouptype[a:grouptypename].typenames[typeidx]
        if type(dim) !=# v:t_dict
            throw 'given dimensions are not a dict'
        endif
        for key in ['nr', 'w', 'h']
            if !has_key(dim, key)
                throw 'dimensions must have keys nr, w, and h'
            endif
        endfor
        call s:ValidateNewDimensions(a:category, a:grouptypename, typename, dim.nr, dim.w, dim.h)
    endfor
    return a:dims
endfunction

" Validate dimensions of a subwin to be added to the model someplace
function! s:ValidateNewSubwinDimensions(grouptypename, typename, relnr, w, h)
    call EchomLog('window-model', 'debug', 'ValidateNewSubwinDimensionsList ', a:grouptypename, ':', a:typename, ' [', a:relnr, ',', a:w, ',', a:h, ']')
    if type(a:relnr) !=# v:t_number
        throw "relnr must be a number"
    endif
    if type(a:w) !=# v:t_number || a:w <# -1
        throw "w must be at least -1"
    endif
    if type(a:h) !=# v:t_number || a:h <# -1
        throw "h must be at least -1"
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
    call EchomLog('window-model', 'debug', 'ValidateNewSubwinDimensionsList ', a:grouptypename, ' ', a:dims)
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
        call EchomLog('window-model', 'debug', 'Populated dummy dimensions: ', retlist)
        return retlist
    endif
    if len(a:dims) !=# len(g:subwingrouptype[a:grouptypename].typenames)
        throw len(dims) . ' is the wrong number of dimensions for ' . a:grouptypename
    endif

    for typeidx in range(len(g:subwingrouptype[a:grouptypename].typenames))
        call EchomLog('window-model', 'verbose', 'Validate dimensions ', a:dims[typeidx])
        " TODO? Fill in missing dicts with 0,-1,-1
        " - This will only be required if there's ever a case where multiple
        "   windows are added to the model at the same time, but only some of
        "   them have non-dummy dimensions
        let typename = g:subwingrouptype[a:grouptypename].typenames[typeidx]
        let dim = a:dims[typeidx]

        if type(dim) !=# v:t_dict
            throw 'given subwin dimensions are not a dict'
        endif
        for key in ['relnr', 'w', 'h']
            if !has_key(dim, key)
                throw 'subwin dimensions must have keys relnr, w, and h'
            endif
        endfor
        call s:ValidateNewSubwinDimensions(
       \    a:grouptypename,
       \    typename,
       \    dim.relnr,
       \    dim.w,
       \    dim.h
       \)
    endfor
    return a:dims
endfunction

" Get a dict of all uberwins' toIdentify functions keyed by their group type
function! WinModelToIdentifyUberwins()
    call EchomLog('window-model', 'debug', 'WinModelToIdentifyUberwins')
    let retdict = {}
    for grouptypename in keys(g:uberwingrouptype)
        let retdict[grouptypename] = g:uberwingrouptype[grouptypename].toIdentify
    endfor
    call EchomLog('window-model', 'debug', 'Retrieved: ', retdict)
    return retdict
endfunction

" Get a dict of all subwins' toIdentify functions keyed by their group type
function! WinModelToIdentifySubwins()
    call EchomLog('window-model', 'debug', 'WinModelToIdentifySubwins')
    let retdict = {}
    for grouptypename in keys(g:subwingrouptype)
        let retdict[grouptypename] = g:subwingrouptype[grouptypename].toIdentify
    endfor
    call EchomLog('window-model', 'debug', 'Retrieved: ', retdict)
    return retdict
endfunction

" Uberwin group manipulation
function! WinModelUberwinGroupExists(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelUberwinGroupExists ', a:grouptypename)
    call s:EnsureWinModelExists()
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    return has_key(t:uberwin, a:grouptypename )
endfunction
function! WinModelAssertUberwinGroupExists(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertUberwinGroupExists ', a:grouptypename)
    if !WinModelUberwinGroupExists(a:grouptypename)
        throw 'nonexistent uberwin group ' . a:grouptypename
    endif
endfunction
function! WinModelAssertUberwinGroupDoesntExist(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertUberwinGroupDoesntExist ', a:grouptypename)
    if WinModelUberwinGroupExists(a:grouptypename)
        throw 'uberwin group ' . a:grouptypename . ' exists'
    endif
endfunction

function! WinModelUberwinGroupIsHidden(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelUberwinGroupIsHidden ', a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    return t:uberwin[ a:grouptypename ].hidden
endfunction
function! WinModelAssertUberwinGroupIsHidden(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertUberwinGroupIsHidden ', a:grouptypename)
    if !WinModelUberwinGroupIsHidden(a:grouptypename)
       throw 'uberwin group ' . a:grouptypename . ' is not hidden'
    endif
endfunction
function! WinModelAssertUberwinGroupIsNotHidden(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertUberwinGroupIsNotHidden ', a:grouptypename)
    if WinModelUberwinGroupIsHidden(a:grouptypename)
        throw 'uberwin group ' . a:grouptypename . ' is hidden'
    endif
endfunction
function! WinModelUberwinGroupTypeNames()
    call EchomLog('window-model', 'debug', 'WinModelUberwinGroupTypeNames ', a:grouptypename)
    return keys(g:uberwingrouptype)
endfunction
function! WinModelShownUberwinGroupTypeNames()
    call EchomLog('window-model', 'debug', 'WinModelShownUberwinGroupTypeNames')
    call s:EnsureWinModelExists()
    let grouptypenames = []
    for grouptypename in keys(t:uberwin)
        if !WinModelUberwinGroupIsHidden(grouptypename)
            call add(grouptypenames, grouptypename)
        endif
    endfor
    call sort(grouptypenames, function('s:CompareUberwinGroupTypeNamesByPriority'))
    call EchomLog('window-model', 'debug', 'Shown uberwin groups: ', grouptypenames)
    return grouptypenames
endfunction
function! WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelUberwinTypeNamesByGroupTypeName ', a:grouptypename)
    call WinModelAssertUberwinGroupTypeExists(a:grouptypename)
    let typenames =  g:uberwingrouptype[a:grouptypename].typenames
    call EchomLog('window-model', 'debug', 'Type names for uberwin group ', a:grouptypename, ': ', typenames)
    return typenames
endfunction
function! WinModelUberwinDimensions(grouptypename, typename)
    call EchomLog('window-model', 'debug', 'WinModelUberwinDimensions ', a:grouptypename, ':', a:typename)
    call WinModelAssertUberwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    let windict = t:uberwin[a:grouptypename].uberwin[a:typename]
    let retdict = {'nr':windict.nr,'w':windict.w,'h':windict.h}
    call EchomLog('window-model', 'debug', 'Dimensions of uberwin ', a:grouptypename, ':', a:typename, ': ', retdict)
    return retdict
endfunction

function! WinModelAddUberwins(grouptypename, winids, dimensions)
    call EchomLog('window-model', 'info', 'WinModelAddUberwins ', a:grouptypename, ' ', a:winids, ' ', a:dimensions)
    call WinModelAssertUberwinGroupDoesntExist(a:grouptypename)
    
    " If no winids are supplied, the uberwin is initially hidden
    if !len(a:winids)
        call EchomLog('window-model', 'verbose', 'No winids give, Adding uberwin group ', a:grouptypename, ' as hidden')
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
        
        call EchomLog('window-model', 'verbose', 'Winids and dimensions valid. Adding uberwin group ', a:grouptypename, ' as shown')
        
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
    call EchomLog('window-model', 'info', 'WinModelRemoveUberwins ', a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call remove(t:uberwin, a:grouptypename)
endfunction

function! WinModelHideUberwins(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelHideUberwins ', a:grouptypename)
    call WinModelAssertUberwinGroupExists(a:grouptypename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)

    let t:uberwin[a:grouptypename].hidden = 1
    let t:uberwin[a:grouptypename].uberwin = {}
endfunction

function! WinModelShowUberwins(grouptypename, winids, dimensions)
    call EchomLog('window-model', 'info', 'WinModelShowUberwins ', a:grouptypename, ' ', a:winids, ' ', a:dimensions)
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

function! WinModelAddOrShowUberwins(grouptypename, uberwinids, dimensions)
    call EchomLog('window-model', 'info', 'WinModelAddOrShowUberwins ', a:grouptypename, ' ', a:uberwinids, ' ', a:dimensions)
    if !WinModelUberwinGroupExists(a:grouptypename)
        call EchomLog('window-model', 'verbose', 'Uberwin group ', a:grouptypename, ' not present in model. Adding.')
        call WinModelAddUberwins(a:grouptypename, a:uberwinids, a:dimensions)
    else
        call EchomLog('window-model', 'verbose', 'Uberwin group ', a:grouptypename, ' hidden in model. Showing.')
        call WinModelShowUberwins(a:grouptypename, a:uberwinids, a:dimensions)
    endif
endfunction

function! WinModelChangeUberwinIds(grouptypename, winids)
    call EchomLog('window-model', 'info', 'WinModelChangeUberwinIds ', a:grouptypename, ' ', a:winids)
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
    call EchomLog('window-model', 'debug', 'WinModelChangeUberwinDimensions ', a:grouptypename, ':', a:typename, ' [', a:nr, ',', a:w, ',', a:h, ']')
    call WinModelAssertUberwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    call s:ValidateNewDimensions('uberwin', a:grouptypename, a:typename, a:nr, a:w, a:h)

    let t:uberwin[a:grouptypename].uberwin[a:typename].nr = a:nr
    let t:uberwin[a:grouptypename].uberwin[a:typename].w = a:w
    let t:uberwin[a:grouptypename].uberwin[a:typename].h = a:h
endfunction

function! WinModelChangeUberwinGroupDimensions(grouptypename, dims)
    call EchomLog('window-model', 'debug', 'WinModelChangeUberwinGroupDimensions ', a:grouptypename, ' ', a:dims)
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
    call EchomLog('window-model', 'debug', 'WinModelSupwinExists ', a:winid)
    call s:EnsureWinModelExists()
    return has_key(t:supwin, a:winid)
endfunction
function! WinModelAssertSupwinExists(winid)
    call EchomLog('window-model', 'debug', 'WinModelAssertSupwinExists ', a:winid)
    if !WinModelSupwinExists(a:winid)
        throw 'nonexistent supwin ' . a:winid
    endif
endfunction
function! WinModelAssertSupwinDoesntExist(winid)
    call EchomLog('window-model', 'debug', 'WinModelAssertSupwinDoesntExist ', a:winid)
    if WinModelSupwinExists(a:winid)
        throw 'supwin ' . a:winid . ' exists'
    endif
endfunction
function! WinModelSupwinDimensions(supwinid)
    call EchomLog('window-model', 'debug', 'WinModelSupwinDimensions ', a:supwinid)
    call WinModelAssertSupwinExists(a:supwinid)
    let windict = t:supwin[a:supwinid]
    let retdict = {'nr':windict.nr,'w':windict.w,'h':windict.h}
    call EchomLog('window-model', 'debug', 'Dimensions of supwin ', a:supwinid, ': ', retdict)
    return retdict
endfunction

function! WinModelChangeSupwinDimensions(supwinid, nr, w, h)
    call EchomLog('window-model', 'debug', 'WinModelChangeSupwinDimensions ', a:supwinid, ' [', a:nr, ',', a:w, ',', a:h, ']')
    call WinModelAssertSupwinExists(a:supwinid)
    call s:ValidateNewDimensions('supwin', '', '', a:nr, a:w, a:h)

    let t:supwin[a:supwinid].nr = a:nr
    let t:supwin[a:supwinid].w = a:w
    let t:supwin[a:supwinid].h = a:h
endfunction

" Subwin group manipulation
function! WinModelSubwinGroupExists(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinGroupExists ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinModelAssertSupwinExists(a:supwinid)

    return has_key(t:supwin[a:supwinid].subwin, a:grouptypename)
endfunction
function! WinModelAssertSubwinGroupExists(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinGroupExists ', a:supwinid, ':', a:grouptypename)
    if !WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has no subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinModelAssertSubwinGroupDoesntExist(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinGroupDoesntExist ', a:supwinid, ':', a:grouptypename)
    if WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinModelSubwinGroupIsHidden(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinGroupIsHidden ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    return t:supwin[a:supwinid].subwin[a:grouptypename].hidden
endfunction
function! WinModelAssertSubwinGroupIsHidden(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinGroupIsHidden ', a:supwinid, ':', a:grouptypename)
    if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        throw 'subwin group ' .
       \      a:grouptypename .
       \      ' not hidden for supwin ' .
       \      a:supwinid
    endif
endfunction
function! WinModelAssertSubwinGroupIsNotHidden(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinGroupIsNotHidden ', a:supwinid, ':', a:grouptypename)
    if WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        throw 'subwin group ' .
       \      a:grouptypename .
       \      ' is hidden for supwin ' .
       \      a:supwinid
    endif
endfunction
function! WinModelSubwinIsAfterimaged(supwinid, grouptypename, typename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinIsAfterimaged ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call WinModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    return t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].afterimaged
endfunction
function! WinModelAssertSubwinIsAfterimaged(supwinid, grouptypename, typename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinIsAfterimaged ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    if !WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, a:typename)
        throw 'subwin ' .
       \      a:grouptypename .
       \      ':' .
       \      a:typename .
       \      ' for supwin ' .
       \      a:supwinid .
       \      ' is not afterimaged'
    endif
endfunction
function! WinModelAssertSubwinIsNotAfterimaged(supwinid, grouptypename, typename)
    call EchomLog('window-model', 'debug', 'WinModelAssertSubwinIsNotAfterimaged ', a:supwinid, ':', a:grouptypename, ':', a:typename)
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
function! WinModelSubwinGroupHasAfterimagedSubwin(supwinid, grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinGroupHasAfterimagedSubwin ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    for typename in WinModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('window-model', 'verbose', 'Checking subwin ', a:supwinid, ':', a:grouptypename, ':', typename)
        if WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call EchomLog('window-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' has afterimaged subwin ', typename)
            return 1
        endif
    endfor
    call EchomLog('window-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' has no afterimaged subwins')
    return 0
endfunction
function! s:SubwinidIsInSubwinList(subwinid)
    call EchomLog('window-model', 'debug', 'SubwinidIsInSubwinList ', a:subwinid)
    call s:EnsureWinModelExists()
    return has_key(t:subwin, a:subwinid)
endfunction
function! s:AssertSubwinidIsInSubwinList(subwinid)
    call EchomLog('window-model', 'debug', 'AssertSubwinidIsInSubwinList ', a:subwinid)
    if !s:SubwinidIsInSubwinList(a:subwinid)
        throw 'subwin id ' . a:subwinid . ' not in subwin list'
    endif
endfunction
function! s:AssertSubwinidIsNotInSubwinList(subwinid)
    call EchomLog('window-model', 'debug', 'AssertSubwinidIsNotInSubwinList ', a:subwinid)
    if s:SubwinidIsInSubwinList(a:subwinid)
        throw 'subwin id ' . a:subwinid . ' is in subwin list'
    endif
endfunction
function! s:SubwinIdFromSubwinList(supwinid, grouptypename, typename)
    call EchomLog('window-model', 'debug', 'SubwinIdFromSubwinList ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call s:EnsureWinModelExists()
    let foundsubwinid = 0
    for subwinid in keys(t:subwin)
        call EchomLog('window-model', 'verbose', 'Checking subwin ID ', subwinid)
        let subwin = t:subwin[subwinid]
        if subwin.supwin ==# a:supwinid &&
       \   subwin.grouptypename ==# a:grouptypename &&
       \   subwin.typename ==# a:typename
            call EchomLog('window-model', 'Subwin ID ', subwinid, ' matches subwin ', a:supwinid, ':', a:grouptypename, ':', a:typename)
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
    call EchomLog('window-model', 'debug', 'AssertSubwinIsInSubwinList ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    if !s:SubwinIdFromSubwinList(a:supwinid, a:grouptypename, a:typename)
        throw 'subwin ' . a:grouptypename . ':' . a:typename . ' for supwin ' .
       \      a:supwinid . ' not in subwin list'
    endif
endfunction
function! s:AssertSubwinIsNotInSubwinList(supwinid, grouptypename, typename)
    call EchomLog('window-model', 'debug', 'AssertSubwinIsNotInSubwinList ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    let subwinid = s:SubwinIdFromSubwinList(a:supwinid, a:grouptypename, a:typename)
    if subwinid
        throw 'subwin ' . a:grouptypename . ':' . a:typename . ' for supwin ' .
       \      a:supwinid . ' in subwin list with subwin id ' . subwinid
    endif
endfunction
function! s:AssertSubwinListHas(subwinid, supwinid, grouptypename, typename)
    call EchomLog('window-model', 'debug', 'AssertSubwinListHas ', a:subwinid, ' ', a:supwinid, ':', a:grouptypename, ':', a:typename)
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
    call EchomLog('window-model', 'debug', 'AssertSubwinGroupIsConsistent ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    if !WinModelSupwinExists(a:supwinid)
        return
    elseif WinModelSubwinGroupExists(a:supwinid, a:grouptypename) &&
   \       !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for typename in g:subwingrouptype[a:grouptypename].typenames
            call EchomLog('window-model', 'verbose', 'Checking shown subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' for model consistency')
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
            call EchomLog('window-model', 'verbose', 'Checking hidden subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' for model consistency')
            call s:AssertSubwinIsNotInSubwinList(
           \    a:supwinid,
           \    a:grouptypename,
           \    typename
           \)
        endfor
    endif
endfunction
function! WinModelSubwinGroupTypeNames()
    call EchomLog('window-model', 'debug', 'WinModelSubwinGroupTypeNames')
    call EchomLog('window-model', 'debug', 'Subwin group type names: ', keys(g:subwingrouptype))
    return keys(g:subwingrouptype)
endfunction
function! WinModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
    call EchomLog('window-model', 'debug', 'WinModelShownSubwinGroupTypeNamesBySupwinId ', a:supwinid)
    call WinModelAssertSupwinExists(a:supwinid)
    let grouptypenames = []
    for grouptypename in keys(t:supwin[a:supwinid].subwin)
        if !WinModelSubwinGroupIsHidden(a:supwinid, grouptypename)
            call add(grouptypenames, grouptypename)
        endif
    endfor
    call EchomLog('window-model', 'debug', 'Shown subwin groups for supwin ', a:supwinid, ': ', grouptypenames)
    return sort(grouptypenames, function('s:CompareSubwinGroupTypeNamesByPriority'))
endfunction
function! WinModelSubwinTypeNamesByGroupTypeName(grouptypename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinTypeNamesByGroupTypeName ', a:grouptypename)
    call WinModelAssertSubwinGroupTypeExists(a:grouptypename)
    let typenames =  g:subwingrouptype[a:grouptypename].typenames
    call EchomLog('window-model', 'debug', 'Type names for subwin group ', a:grouptypename, ': ', typenames)
    return typenames
endfunction
function! WinModelSubwinDimensions(supwinid, grouptypename, typename)
    call EchomLog('window-model', 'debug', 'WinModelSubwinDimensions ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call WinModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    let subwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let windict = t:subwin[subwinid]
    let retdict =  {'relnr':windict.relnr,'w':windict.w,'h':windict.h}
    call EchomLog('window-model', 'debug', 'Dimensions of subwin ', a:supwinid, ':', a:grouptypename, ':', a:typename, ': ', retdict)
    return retdict
endfunction
function! WinModelSubwinAibufBySubwinId(subwinid)
    call EchomLog('window-model', 'debug', 'WinModelSubwinAibufBySubwinId ', a:subwinid)
    call s:EnsureWinModelExists()
    call s:AssertSubwinidIsInSubwinList(a:subwinid)
    call EchomLog('window-model', 'debug', 'Afterimage buffer for subwin ', a:subwinid, ': ', t:subwin[a:subwinid].aibuf)
    return t:subwin[a:subwinid].aibuf
endfunction
function! WinModelShownSubwinIdsBySupwinId(supwinid)
    call EchomLog('window-model', 'debug', 'WinModelShownSubwinIdsBySupwinId ', a:supwinid)
    call WinModelAssertSupwinExists(a:supwinid)
    let winids = []
    for grouptypename in keys(t:supwin[a:supwinid].subwin)
        if !WinModelSubwinGroupIsHidden(a:supwinid, grouptypename)
            for typename in keys(t:supwin[a:supwinid].subwin[grouptypename].subwin)
                call EchomLog('window-model', 'verbose', 'Shown subwin ', a:supwinid, ':', grouptypename, ':', typename, ' has ID ', t:supwin[a:supwinid].subwin[grouptypename].subwin[typename].id)
                call add(winids, t:supwin[a:supwinid].subwin[grouptypename].subwin[typename].id)
            endfor
        endif
    endfor
    call EchomLog('window-model', 'debug', 'IDs of shown subwins of supwin ', a:supwinid, ': ', winids)
    return winids
endfunction

function! WinModelAddSupwin(winid, nr, w, h)
    call EchomLog('window-model', 'info', 'WinModelAddSupwin ', a:winid, ' [', a:nr, ',', a:w, ',', a:h, ']')
    call s:EnsureWinModelExists()
    if has_key(t:supwin, a:winid)
        throw 'window ' . a:winid . ' is already a supwin'
    endif
    call s:ValidateNewDimensions('supwin', '', '', a:nr, a:w, a:h)
    let t:supwin[a:winid] = {'subwin':{},'nr':a:nr,'w':a:w,'h':a:h}
endfunction

function! WinModelRemoveSupwin(winid)
    call EchomLog('window-model', 'info', 'WinModelRemoveSupwin ', a:winid)
    call WinModelAssertSupwinExists(a:winid)

    for grouptypename in keys(t:supwin[a:winid].subwin)
        call WinModelAssertSubwinGroupExists(a:winid, grouptypename)
        for typename in keys(t:supwin[a:winid].subwin[grouptypename].subwin)
            call EchomLog('window-model', 'debug', 'Removing subwin ', a:winid, ':', grouptypename, ':', typename, ' with ID ', t:supwin[a:winid].subwin[grouptypename].subwin[typename].id, ' from subwin list')
            call remove(t:subwin, t:supwin[a:winid].subwin[grouptypename].subwin[typename].id)
        endfor
    endfor

    call remove(t:supwin, a:winid)
endfunction

function! WinModelAddSubwins(supwinid, grouptypename, subwinids, dimensions)
    call EchomLog('window-model', 'info', 'WinModelAddSubwins ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids, ' ', a:dimensions)
    call WinModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)
    
    " If no winids are supplied, the uberwin is initially hidden
    if !len(a:subwinids)
        call EchomLog('window-model', 'verbose', 'No winids given. Adding subwin group ', a:supwinid, ':', a:grouptypename, ' as hidden')
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

        call EchomLog('window-model', 'verbose', 'Winids and dimensions valid. Adding subwin group ', a:supwinid, ':', a:grouptypename, ' as shown')
        
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
    call EchomLog('window-model', 'info', 'WinModelRemoveSubwins ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    if !WinModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for subwintypename in keys(t:supwin[a:supwinid].subwin[a:grouptypename].subwin)
            call EchomLog('window-model', 'debug', 'Removing subwin ', a:supwinid, ':', a:grouptypename, ':', subwintypename, ' with ID ', t:supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id, ' from subwin list')
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
    call EchomLog('window-model', 'info', 'WinModelHideSubwins ', a:supwinid, ':', a:grouptypename)
    call WinModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    for subwintypename in keys(t:supwin[a:supwinid].subwin[a:grouptypename].subwin)
            call EchomLog('window-model', 'debug', 'Removing subwin ', a:supwinid, ':', a:grouptypename, ':', subwintypename, ' with ID ', t:supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id, ' from subwin list')
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
    call EchomLog('window-model', 'info', 'WinModelShowSubwins ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids, ' ', a:dimensions)
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
    call EchomLog('window-model', 'info', 'WinModelAddOrShowSubwins ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids, ' ', a:dimensions)
    if !WinModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call EchomLog('window-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' not present in model. Adding.')
        call WinModelAddSubwins(a:supwinid, a:grouptypename, a:subwinids, a:dimensions)
    else
        call EchomLog('window-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' hidden in model. Showing.')
        call WinModelShowSubwins(a:supwinid, a:grouptypename, a:subwinids, a:dimensions)
    endif
endfunction

function! WinModelChangeSubwinIds(supwinid, grouptypename, subwinids)
    call EchomLog('window-model', 'info', 'WinModelChangeSubwinIds ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewWinids(
   \    a:subwinids,
   \    len(g:subwingrouptype[a:grouptypename].typenames)
   \)
 
    for i in range(len(a:subwinids))
        let typename = g:subwingrouptype[a:grouptypename].typenames[i]

        let oldsubwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id
        let t:subwin[a:subwinids[i]] = t:subwin[oldsubwinid]

        call EchomLog('window-model', 'debug', 'Moving subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' from ID ', oldsubwinid, ' to ', a:subwinids[i], ' in subwin list')
        call remove(t:subwin, oldsubwinid)

        let t:supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id = a:subwinids[i]
    endfor

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelChangeSubwinDimensions(supwinid, grouptypename, typename, relnr, w, h)
    call EchomLog('window-model', 'debug', 'WinModelChangeSubwinDimensions ', a:supwinid, ':', a:grouptypename, ':', a:typename, ' [', a:relnr, ',', a:w, ',', a:h, ']')
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewSubwinDimensions(a:grouptypename, a:typename, a:relnr, a:w, a:h)

    let subwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let t:subwin[subwinid].relnr = a:relnr
    let t:subwin[subwinid].w = a:w
    let t:subwin[subwinid].h = a:h

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelChangeSubwinGroupDimensions(supwinid, grouptypename, dims)
    call EchomLog('window-model', 'debug', 'WinModelChangeSubwinGroupDimensions ', a:supwinid, ':', a:grouptypename, ' ', a:dims)
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
    call EchomLog('window-model', 'info', 'WinModelAfterimageSubwin ', a:supwinid, ':', a:grouptypename, ':', a:typename, ' ', a:aibufnum)
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

function! WinModelDeafterimageSubwin(supwinid, grouptypename, typename)
    call EchomLog('window-model', 'info', 'WinModelDeafterimageSubwin ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call WinModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call WinModelAssertSubwinIsAfterimaged(a:supwinid, a:grouptypename, a:typename)
    let subwinid = t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let t:supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].afterimaged = 0
    let t:subwin[subwinid].aibuf = -1
    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinModelDeafterimageSubwinsByGroup(supwinid, grouptypename)
    call EchomLog('window-model', 'info', 'WinModelDeafterimageSubwinsByGroup ', a:supwinid, ':', a:grouptypename)
    if !WinModelSubwinGroupHasAfterimagedSubwin(a:supwinid, a:grouptypename)
        return
    endif

    for typename in g:subwingrouptype[a:grouptypename].typenames
        if WinModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call WinModelDeafterimageSubwin(a:supwinid, a:grouptypename, typename)
        endif
    endfor
endfunction

function! WinModelReplaceWinid(oldwinid, newwinid)
    call EchomLog('window-model', 'info', 'WinModelReplaceWinid ', a:oldwinid, a:newwinid)
    let info = WinModelInfoById(a:oldwinid)
    call s:AssertWinDoesntExist(a:newwinid)

    if info.category ==# 'uberwin'
        let t:uberwin[info.grouptype].uberwin[info.typename].id = a:newwinid

    elseif info.category ==# 'supwin'
        let t:supwin[a:newwinid] = t:supwin[a:oldwinid]
        unlet t:supwin[a:oldwinid]
        for subwinid in keys(t:subwin)
            if t:subwin[subwinid].supwin ==# a:oldwinid
                let t:subwin[subwinid].supwin = a:newwinid
            endif
        endfor

    elseif info.category ==# 'subwin'
        let t:supwin[info.supwin].subwin[info.grouptype].subwin[info.typename].id = a:newwinid
        let t:subwin[a:newwinid] = t:subwin[a:oldwinid]
        unlet t:subwin[a:oldwinid]

    else
        throw 'Window with changed winid is neither uberwin nor supwin nor subwin'
    endif

    if t:curwin.id ==# a:oldwinid
        let t:curwin.id = a:newwinid
    endif
    if t:prevwin.id ==# a:oldwinid
        let t:prevwin.id = a:newwinid
endfunction

" TODO? Some individual types may need an option for a non-default toClose
" callback so that the resolver doesn't have to stomp them with :q! when their groups
" become incomplete
" - So far that hasn't been needed
