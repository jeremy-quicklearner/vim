" Wince Model
" See wince.vim

" g:wince_tabenterpreresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:wince_supwinsaddedresolvecallbacks = [
"     <funcref>
"     ...
" ]
" g:wince_postuseropcallbacks = [
"     <funcref>
"     ...
" ]
" g:wince_uberwingrouptype = {
"     <grouptypename>: {
"         typenames: [<typename>, ...]
"         statuslines: [<statusline>, ...]
"         flag: <flag>
"         hidflag: <flag>
"         flagcol: <1-9>
"         priority: <num>
"         canHaveLoclist: [<0|1>, ...]
"         widths: <num>
"         heights: <num>
"         toOpen: <funcref>
"         toClose: <funcref>
"         toIdentify: <funcref>
"     }
"     ...
" }
" g:wince_subwingrouptype = {
"     <grouptypename>: {
"         typenames: [<typename>, ...]
"         statuslines: [<statusline>, ...]
"         flag: <flag>
"         hidflag: <flag>
"         flagcol: <1-9>
"         priority: <num>
"         afterimaging: [ <0|1>, ... ]
"         canHaveLoclist: [<0|1>, ...]
"         closeWithBelowRight: <0|1>
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
" t:wince_uberwin = {
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
" t:wince_supwin = {
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
" t:wince_subwin = {
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
if !exists('g:wince_uberwingrouptype')
    call EchomLog('wince-model', 'info', 'Initializing global model')
    let g:wince_tabenterpreresolvecallbacks = []
    let g:wince_supwinsaddedresolvecallbacks = []
    let g:wince_postuseropcallbacks = []
    let g:wince_uberwingrouptype = {}
    let g:wince_subwingrouptype = {}
endif

" The rest of the model is tab-specific
function! WinceModelExists()
    call EchomLog('wince-model', 'debug', 'WinceModelExists')
    return exists('t:wince_uberwin')
endfunction

" Initialize the tab-specific portion of the model
function! WinceModelInit()
    if WinceModelExists()
        return
    endif
    call EchomLog('wince-model', 'info', 'WinceModelInit')
    let t:prevwin = {'category':'none','id':0}
    let t:curwin = {'category':'none','id':0}
    let t:wince_uberwin = {}
    let t:wince_supwin = {}
    let t:wince_subwin = {}
endfunction

function! s:EnsureWinceModelExists()
    call EchomLog('wince-model', 'debug', 'EnsureWinceModelExists')
    if !WinceModelExists()
        call WinceModelInit()
    endif
endfunction


" Resolve callback manipulation
function! s:AddTypedCallback(type, callback)
    call EchomLog('wince-model', 'debug', 'Callback: ', a:type, ', ', a:callback)
    if type(a:callback) != v:t_func
        throw 'Resolve callback is not a function'
    endif
    if !exists('g:wince_' . a:type . 'callbacks')
        throw 'Callback type ' . a:type . ' does not exist')
    endif
    if eval('index(g:wince_' . a:type . 'callbacks, a:callback)') >= 0
        throw 'Callback is already registered'
    endif

    execute 'call add(g:wince_' . a:type . 'callbacks, a:callback)'
endfunction
function! WinceModelAddTabEnterPreResolveCallback(callback)
    call EchomLog('wince-model', 'debug', 'TabEnter PreResolve Callback: ', a:callback)
    call s:AddTypedCallback('tabenterpreresolve', a:callback)
endfunction
function! WinceModelAddSupwinsAddedResolveCallback(callback)
    call EchomLog('wince-model', 'debug', 'SupwinsAdded Resolve Callback: ', a:callback)
    call s:AddTypedCallback('supwinsaddedresolve', a:callback)
endfunction
function! WinceModelAddPostUserOperationCallback(callback)
    call EchomLog('wince-model', 'debug', 'Post-User Operation Callbacl: ', a:callback)
    call s:AddTypedCallback('postuserop', a:callback)
endfunction
function! WinceModelTabEnterPreResolveCallbacks()
    call EchomLog('wince-model', 'debug', 'WinceModelTabEnterPreResolveCallbacks')
    return g:wince_tabenterpreresolvecallbacks
endfunction
function! WinceModelSupwinsAddedResolveCallbacks()
    call EchomLog('wince-model', 'debug', 'WinceModelSupwinsAddedResolveCallbacks')
    return g:wince_supwinsaddedresolvecallbacks
endfunction
function! WinceModelPostUserOperationCallbacks()
    call EchomLog('wince-model', 'debug', 'WinceModelPostUserOperationCallbacks')
    return g:wince_postuseropcallbacks
endfunction

" Uberwin group type manipulation
function! s:UberwinGroupTypeExists(grouptypename)
    call EchomLog('wince-model', 'debug', 'UberwinGroupTypeExists ', a:grouptypename)
    return has_key(g:wince_uberwingrouptype, a:grouptypename )
endfunction
function! WinceModelAssertUberwinGroupTypeExists(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertUberwinGroupTypeExists ', a:grouptypename)
    if !s:UberwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent uberwin group type ' . a:grouptypename
    endif
endfunction
function! WinceModelAssertUberwinTypeExists(grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertUberwinTypeExists ', a:grouptypename)
    call WinceModelAssertUberwinGroupTypeExists(a:grouptypename)
    if index(g:wince_uberwingrouptype[a:grouptypename].typenames, a:typename) < 0
        throw 'uberwin group type ' .
       \      a:grouptypename .
       \      ' has no uberwin type ' .
       \      a:typename
    endif
endfunction
function! WinceModelAddUberwinGroupType(name, typenames, statuslines,
                                     \flag, hidflag, flagcol,
                                     \priority, canHaveLoclist,
                                     \widths, heights, toOpen, toClose,
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
    if type(a:canHaveLoclist) != v:t_list
        throw 'canHaveLoclist must be a list'
    endif
    for elem in a:canHaveLoclist
        if type(elem) != v:t_number || elem < 0 || elem > 1
            throw 'canHaveLoclist must be a list of 0s and 1s'
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
        throw len(a:widths) . ' widths provided for ' . numtypes . ' uberwin types'
    endif
    if len(a:heights) != numtypes
        throw len(a:heights) . ' heights provided for ' . numtypes . ' uberwin types'
    endif

    call EchomLog('wince-model', 'debug', 'Uberwin Group Type: ', a:name)

    " Add the uberwin type group
    let g:wince_uberwingrouptype[a:name] = {
    \    'name': a:name,
    \    'typenames': a:typenames,
    \    'statuslines': a:statuslines,
    \    'flag': a:flag,
    \    'hidflag': a:hidflag,
    \    'flagcol': a:flagcol,
    \    'priority': a:priority,
    \    'canHaveLoclist': a:canHaveLoclist,
    \    'widths': a:widths,
    \    'heights': a:heights,
    \    'toOpen': a:toOpen,
    \    'toClose': a:toClose,
    \    'toIdentify': a:toIdentify
    \}
endfunction

" Subwin group type manipulation
function! s:SubwinGroupTypeExists(grouptypename)
    call EchomLog('wince-model', 'debug', 'SubwinGroupTypeExists ', a:grouptypename)
    return has_key(g:wince_subwingrouptype, a:grouptypename )
endfunction
function! WinceModelAssertSubwinGroupTypeExists(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinGroupTypeExists ', a:grouptypename)
    if !s:SubwinGroupTypeExists(a:grouptypename)
        throw 'nonexistent subwin group type ' . a:grouptypename
    endif
endfunction
function! WinceModelAssertSubwinTypeExists(grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinTypeExists ', a:grouptypename, ':', a:typename)
    call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    if index(g:wince_subwingrouptype[a:grouptypename].typenames, a:typename) < 0
        throw 'subwin group type ' .
       \      a:grouptypename .
       \      ' has no subwin type ' .
       \      a:typename
    endif
endfunction
function! WinceModelSubwinGroupTypeHasAfterimagingSubwin(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinGroupTypeHasAfterimagingSubwin ', a:grouptypename)
    call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    for idx in range(len(g:wince_subwingrouptype[a:grouptypename].typenames))
        call EchomLog('wince-model', 'verbose', 'Checking if ', a:grouptypename, ';', g:wince_subwingrouptype[a:grouptypename].typenames[idx], ' subwin type is afterimaging')
        if g:wince_subwingrouptype[a:grouptypename].afterimaging[idx]
            call EchomLog('wince-model', 'debug', 'Subwin group type ', a:grouptypename, ' has afterimaging subwin type ', g:wince_subwingrouptype[a:grouptypename].typenames[idx])
            return 1
        endif
    endfor
    return 0
endfunction
function! WinceModelAddSubwinGroupType(name, typenames, statuslines,
                                    \flag, hidflag, flagcol,
                                    \priority, afterimaging,
                                    \canHaveLoclist, stompWithBelowRight,
                                    \widths, heights,
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
    if type(a:canHaveLoclist) != v:t_list
        throw 'canHaveLoclist must be a list'
    endif
    for elem in a:canHaveLoclist
        if type(elem) != v:t_number || elem < 0 || elem > 1
            throw 'canHaveLoclist must be a list of 0s and 1s'
        endif
    endfor
    if type(a:stompWithBelowRight) != v:t_number || elem < 0 || elem > 1
        throw 'stompWithBelowRight must be a 0 or 1'
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
        throw len(a:widths) . ' widths provided for ' . numtypes . ' subwin types'
    endif
    if len(a:heights) != numtypes
        throw len(a:heights) . ' heights provided for ' . numtypes . ' subwin types'
    endif
    if len(a:afterimaging) != numtypes
        throw len(a:afterimaging) . ' afterimaging flags provided for ' . numtypes . ' subwin types'
    endif

    call EchomLog('wince-model', 'debug', 'Subwin Group Type: ', a:name)

    " Add the subwin type group
    let g:wince_subwingrouptype[a:name] = {
    \    'name': a:name,
    \    'typenames': a:typenames,
    \    'statuslines': a:statuslines,
    \    'flag': a:flag,
    \    'hidflag': a:hidflag,
    \    'flagcol': a:flagcol,
    \    'priority': a:priority,
    \    'afterimaging': a:afterimaging,
    \    'canHaveLoclist': a:canHaveLoclist,
    \    'stompWithBelowRight': a:stompWithBelowRight,
    \    'widths': a:widths,
    \    'heights': a:heights,
    \    'toOpen': a:toOpen,
    \    'toClose': a:toClose,
    \    'toIdentify': a:toIdentify
    \}
endfunction

" Previous window info manipulation
function! WinceModelPreviousWinInfo()
    call EchomLog('wince-model', 'debug', 'WinceModelPreviousWinInfo')
    call s:EnsureWinceModelExists()
    call EchomLog('wince-model', 'debug', 'Previous window: ', t:prevwin)
    return t:prevwin
endfunction

function! WinceModelSetPreviousWinInfo(info)
    if !WinceModelIdByInfo(a:info)
        call EchomLog('wince-model', 'info', "Attempted to set previous window to one that doesn't exist in model: " . string(a:info), '. Default to current window')
        let t:prevwin = t:curwin
        return
    endif
    call EchomLog('wince-model', 'info', 'WinceModelSetPreviousWinInfo ', a:info)
    let t:prevwin = a:info
endfunction

" Current window info manipulation
function! WinceModelCurrentWinInfo()
    call EchomLog('wince-model', 'debug', 'WinceModelCurrentWinInfo')
    call s:EnsureWinceModelExists()
    call EchomLog('wince-model', 'debug', 'Current window: ', t:curwin)
    return t:curwin
endfunction

function! WinceModelSetCurrentWinInfo(info)
    call EchomLog('wince-model', 'info', 'WinceModelSetCurrentWinInfo ', a:info)
    if !WinceModelIdByInfo(a:info)
        throw "Attempted to set current window to one that doesn't exist in model: " . string(a:info)
    endif
    let t:curwin = a:info
endfunction

" General Getters

" Returns the names of all uberwin groups in the current tab, shown or not
function! WinceModelUberwinGroups()
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinGroups')
    call s:EnsureWinceModelExists()
    call EchomLog('wince-model', 'debug', 'Uberwin groups: ', keys(t:wince_uberwin))
    return keys(t:wince_uberwin)
endfunction

" Returns a list containing the IDs of all uberwins in an uberwin group
function! WinceModelUberwinIdsByGroupTypeName(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinIdsByGroupTypeName ', a:grouptypename)
    call s:EnsureWinceModelExists()
    call WinceModelAssertUberwinGroupTypeExists(a:grouptypename)
    let uberwinids = []
    if !WinceModelUberwinGroupExists(a:grouptypename) ||
   \   WinceModelUberwinGroupIsHidden(a:grouptypename)
        call EchomLog('wince-model', 'debug', 'No shown uberwin group ', a:grouptypename)
        return []
    endif
    for typename in WinceModelUberwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('wince-model', 'verbose', 'Uberwin ', a:grouptypename, ':', typename, ' has ID ', t:wince_uberwin[a:grouptypename].uberwin[typename].id)
        call add(uberwinids, t:wince_uberwin[a:grouptypename].uberwin[typename].id)
    endfor
    call EchomLog('wince-model', 'debug', 'Uberwin IDs for group ', a:grouptypename, ': ', uberwinids)
    return uberwinids
endfunction

" Returns a list containing all uberwin IDs
function! WinceModelUberwinIds()
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinIds')
    call s:EnsureWinceModelExists()
    let uberwinids = []
    for grouptype in keys(t:wince_uberwin)
        if t:wince_uberwin[grouptype].hidden
            call EchomLog('wince-model', 'verbose', 'Skipping hidden uberwin group ', grouptype)
            continue
        endif
        for typename in keys(t:wince_uberwin[grouptype].uberwin)
            call EchomLog('wince-model', 'verbose', 'Uberwin ', grouptype, ':', typename, ' has ID ', t:wince_uberwin[grouptype].uberwin[typename].id)
            call add(uberwinids, t:wince_uberwin[grouptype].uberwin[typename].id)
        endfor
    endfor
    call EchomLog('wince-model', 'debug', 'Uberwin IDs: ', uberwinids)
    return uberwinids
endfunction

" Returns a string with uberwin flags to be included in the tabline, and its
" length (not counting colour-changing escape sequences)
function! WinceModelUberwinFlagsStr()
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinFlagsStr')
    if !WinceModelExists()
        call EchomLog('wince-model', 'debug', 'No model. Returning empty string.')
        return ['', 0]
    endif

    let flagsstr = ''
    let flagslen = 0

    for grouptypename in WinceModelUberwinGroups()
        if WinceModelUberwinGroupIsHidden(grouptypename)
            call EchomLog('wince-model', 'verbose', 'Hidden uberwin group ', grouptypename, ' contributes ', g:wince_uberwingrouptype[grouptypename].hidflag)
            let flag = g:wince_uberwingrouptype[grouptypename].hidflag
        else
            call EchomLog('wince-model', 'verbose', 'Shown uberwin group ', grouptypename, ' contributes ', g:wince_uberwingrouptype[grouptypename].flag)
            let flag = g:wince_uberwingrouptype[grouptypename].flag
        endif
        let flagsstr .= '%' . g:wince_uberwingrouptype[grouptypename].flagcol . '*[' . flag . ']'
        let flagslen += len(flag) + 2
    endfor

    call EchomLog('wince-model', 'debug', 'Uberwin flags: ', flagsstr)
    return [flagsstr, flagslen]
endfunction

" Returns a list containing all supwin IDs
function! WinceModelSupwinIds()
    call EchomLog('wince-model', 'debug', 'WinceModelSupwinIds')
    call s:EnsureWinceModelExists()
    call EchomLog('wince-model', 'debug', 'Supwin IDs: ', map(keys(t:wince_supwin), 'str2nr(v:val)'))
    return map(keys(t:wince_supwin), 'str2nr(v:val)')
endfunction

" Returns the names of all subwin groups for a given supwin, shown or not
function! WinceModelSubwinGroupsBySupwin(supwinid)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinGroupsBySupwin ', a:supwinid)
    call WinceModelAssertSupwinExists(a:supwinid)
    call EchomLog('wince-model', 'debug', 'Subwin groups for supwin ', a:supwinid, ': ', keys(t:wince_supwin[a:supwinid].subwin))
    return keys(t:wince_supwin[a:supwinid].subwin)
endfunction

" Returns a list containing the IDs of all subwins in a subwin group
function! WinceModelSubwinIdsByGroupTypeName(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinIdsByGroupTypeName ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinceModelAssertSupwinExists(a:supwinid)
    if !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename) ||
   \   WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        call EchomLog('wince-model', 'debug', 'No shown subwin group ', a:supwinid, ':', a:grouptypename)
        return []
    endif
    let subwinids = []
    for typename in WinceModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('wince-model', 'verbose', 'Subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' has ID ', t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id)
        call add(subwinids, t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id)
    endfor
    call EchomLog('wince-model', 'debug', 'Subwin IDs for group ', a:supwinid, ':', a:grouptypename, ': ', subwinids)
    return subwinids
endfunction

" Returns which flag to show for a given supwin due to a given subwin group
" type's existence, hiddenness, etc.
function! WinceModelSubwinFlagByGroup(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinFlagByGroup ', a:supwinid, ':', a:grouptypename)
    if !WinceModelExists() ||
   \   !WinceModelSupwinExists(a:supwinid) ||
   \   !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call EchomLog('wince-model', 'debug', 'No subwin group ', a:supwinid, ':', a:grouptypename, '. Returning empty string.')
        return ''
    endif

    if WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        call EchomLog('wince-model', 'debug', 'Hidden subwin group ', a:supwinid, ':', a:grouptypename, ' gives ', g:wince_subwingrouptype[a:grouptypename].hidflag)
        let flag = g:wince_subwingrouptype[a:grouptypename].hidflag
    else
        call EchomLog('wince-model', 'debug', 'Shown subwin group ', a:supwinid, ':', a:grouptypename, ' gives ', g:wince_subwingrouptype[a:grouptypename].flag)
        let flag = g:wince_subwingrouptype[a:grouptypename].flag
    endif

    return '[' . flag . ']'
endfunction

function! WinceModelSubwinFlagCol(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinFlagCol ', a:grouptypename)
    call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    call EchomLog('wince-model', 'debug', 'Flag colour is ', g:wince_subwingrouptype[a:grouptypename].flagcol)
    return g:wince_subwingrouptype[a:grouptypename].flagcol
endfunction

" Returns a list containing all subwin IDs
function! WinceModelSubwinIds()
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinIds')
    call s:EnsureWinceModelExists()
    call EchomLog('wince-model', 'debug', 'Subwin IDs: ', map(keys(t:wince_subwin), 'str2nr(v:val)'))
    return map(keys(t:wince_subwin), 'str2nr(v:val)')
endfunction

" Returns 1 if a winid is represented in the model. 0 otherwise.
function! WinceModelWinExists(winid)
    call EchomLog('wince-model', 'debug', 'WinceModelWinExists ', a:winid)
    call s:EnsureWinceModelExists()
    if index(WinceModelUberwinIds(), str2nr(a:winid)) > -1
        call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in uberwin list')
        return 1
    endif
    if index(WinceModelSupwinIds(), str2nr(a:winid)) > -1
        call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in supwin list')
        return 1
    endif
    if index(WinceModelSubwinIds(), a:winid) > -1
        call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in subwin list')
        return 1
    endif
    call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' not found')
    return 0
endfunction
function! s:AssertWinExists(winid)
    call EchomLog('wince-model', 'debug', 'AssertWinExists ', a:winid)
    if !WinceModelWinExists(a:winid)
        throw 'nonexistent window ' . a:winid
    endif
endfunction
function! s:AssertWinDoesntExist(winid)
    call EchomLog('wince-model', 'debug', 'AssertWinDoesntExist ', a:winid)
    if WinceModelWinExists(a:winid)
        throw 'window ' . a:winid . ' exists'
    endif
endfunction


" Given a window ID, return a dict that identifies it within the model
function! WinceModelInfoById(winid)
    call EchomLog('wince-model', 'debug', 'WinceModelInfoById ', a:winid)
    call EchomLog('wince-model', 'verbose', 'Check for ID', a:winid, ' in supwin list')
    call s:EnsureWinceModelExists()
    if has_key(t:wince_supwin, a:winid)
        call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in supwin list with dimensions [', t:wince_supwin[a:winid].nr, ',', t:wince_supwin[a:winid].w, ',', t:wince_supwin[a:winid].h, ']')
        return {
       \    'category': 'supwin',
       \    'id': a:winid,
       \    'nr': t:wince_supwin[a:winid].nr,
       \    'w': t:wince_supwin[a:winid].w,
       \    'h': t:wince_supwin[a:winid].h
       \}
    endif

    call EchomLog('wince-model', 'verbose', 'Check for ID', a:winid, ' in subwin list')
    if has_key(t:wince_subwin, a:winid)
        call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in subwin listas ', t:wince_subwin[a:winid].supwin, ':', t:wince_subwin[a:winid].typename, ' with dimensions [', t:wince_subwin[a:winid].relnr, ',', t:wince_subwin[a:winid].w, ',', t:wince_subwin[a:winid].h, ']')
        return {
       \    'category': 'subwin',
       \    'supwin': t:wince_subwin[a:winid].supwin,
       \    'grouptype': t:wince_subwin[a:winid].grouptypename,
       \    'typename': t:wince_subwin[a:winid].typename,
       \    'relnr': t:wince_subwin[a:winid].relnr,
       \    'w': t:wince_subwin[a:winid].w,
       \    'h': t:wince_subwin[a:winid].h
       \}
    endif

    for grouptypename in keys(t:wince_uberwin)
        for typename in keys(t:wince_uberwin[grouptypename].uberwin)
            call EchomLog('wince-model', 'verbose', 'Check for ID ', a:winid, ' in uberwin ', grouptypename, ':', typename)
            if t:wince_uberwin[grouptypename].uberwin[typename].id == a:winid
                call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in uberwin record with dimensions [', t:wince_uberwin[grouptypename].uberwin[typename].nr, ',', t:wince_uberwin[grouptypename].uberwin[typename].w, ',', t:wince_uberwin[grouptypename].uberwin[typename].h, ']')
                return {
               \    'category': 'uberwin',
               \    'grouptype': grouptypename,
               \    'typename': typename,
               \    'nr': t:wince_uberwin[grouptypename].uberwin[typename].nr,
               \    'w': t:wince_uberwin[grouptypename].uberwin[typename].w,
               \    'h': t:wince_uberwin[grouptypename].uberwin[typename].h
               \}
            endif
        endfor
    endfor

    call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' not found in model')
    return {'category': 'none', 'id': a:winid}
endfunction

" Given a supwin id, returns it. Given a subwin ID, returns the ID if the
" supwin if the subwin. Given anything else, fails
function! WinceModelSupwinIdBySupwinOrSubwinId(winid)
    call EchomLog('wince-model', 'debug', 'WinceModelSupwinIdBySupwinOrSubwinId ', a:winid)
    let info = WinceModelInfoById(a:winid)
    if info.category ==# 'none'
        throw 'Window with id ' . a:winid . ' is uncategorized'
    endif
    if info.category ==# 'uberwin'
        throw 'Window with id ' . a:winid . ' is an uberwin'
    endif
    if info.category ==# 'supwin'
        call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in supwin list')
        return a:winid
    endif
    if info.category ==# 'subwin'
        call EchomLog('wince-model', 'debug', 'ID ', a:winid, ' found in subwin list with supwin ', info.supwin)
        return info.supwin
    endif
    throw 'Control should never reach here'
endfunction

" Given window info, return a statusline for that window. Returns an empty
" string if the window should have the default statusline
function! WinceModelStatusLineByInfo(info)
    call EchomLog('wince-model', 'debug', 'WinceModelStatusLineByInfo ', a:info)
    if !WinceModelExists()
        return ''
    endif

    if a:info.category ==# 'supwin' || a:info.category ==# 'none'
        call EchomLog('wince-model', 'debug', 'Supwin or uncategorized window carries default statusline')
        return ''
    elseif a:info.category ==# 'uberwin'
        call WinceModelAssertUberwinTypeExists(a:info.grouptype, a:info.typename)
        call EchomLog('wince-model', 'debug', 'Uberwin type ', a:info.grouptype, ':', a:info.typename, ' specifies statusline')
        let grouptype = g:wince_uberwingrouptype[a:info.grouptype]
    elseif a:info.category ==# 'subwin'
        call WinceModelAssertSubwinTypeExists(a:info.grouptype, a:info.typename)
        call EchomLog('wince-model', 'debug', 'Subwin type ', a:info.grouptype, ':', a:info.typename, ' specifies statusline')
        let grouptype = g:wince_subwingrouptype[a:info.grouptype]
    endif

    let typeidx = index(grouptype.typenames, a:info.typename)
    call EchomLog('wince-model', 'debug', 'Statusline: ', grouptype.statuslines[typeidx])
    return grouptype.statuslines[typeidx]
endfunction

" Given an info dict from WinceModelInfoById, return the window ID
function! WinceModelIdByInfo(info)
    call EchomLog('wince-model', 'debug', 'WinceModelIdByInfo ', a:info)
    if a:info.category ==# 'supwin' || a:info.category ==# 'none'
        if WinceModelSupwinExists(a:info.id)
            call EchomLog('wince-model', 'debug', 'Supwin with ID ', a:info.id, ' found')
            return a:info.id
        endif
        call EchomLog('wince-model', 'debug', 'Supwin with ID ', a:info.id, ' not found')
    elseif a:info.category ==# 'uberwin'
        if WinceModelUberwinGroupExists(a:info.grouptype) &&
       \   !WinceModelUberwinGroupIsHidden(a:info.grouptype)
            call EchomLog('wince-model', 'debug', 'Uberwin ', a:info.grouptype, ':', a:info.typename, ' has ID ', t:wince_uberwin[a:info.grouptype].uberwin[a:info.typename].id)
            return t:wince_uberwin[a:info.grouptype].uberwin[a:info.typename].id
        endif
        call EchomLog('wince-model', 'debug', 'Uberwin group ', a:info.grouptype, ' not shown')
    elseif a:info.category ==# 'subwin'
        if WinceModelSupwinExists(a:info.supwin) &&
       \   WinceModelSubwinGroupExists(a:info.supwin, a:info.grouptype) &&
       \   !WinceModelSubwinGroupIsHidden(a:info.supwin, a:info.grouptype)
            call EchomLog('wince-model', 'debug', 'Subwin ', a:info.supwin, ':', a:info.grouptype, ':', a:info.typename, ' has ID ', t:wince_supwin[a:info.supwin].subwin[a:info.grouptype].subwin[a:info.typename].id)
            return t:wince_supwin[a:info.supwin].subwin[a:info.grouptype].subwin[a:info.typename].id
        endif
        call EchomLog('wince-model', 'debug', 'Subwin group ', a:info.supwin, ':', a:info.grouptype, ' not shown')
    endif
    return 0
endfunction

" Comparator for sorting uberwin group type names by priority
function! s:CompareUberwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    call EchomLog('wince-model', 'verbose', 'CompareUberwinGroupTypeNamesByMinPriority ', a:grouptypename1, a:grouptypename2)
    let priority1 = g:wince_uberwingrouptype[a:grouptypename1].priority
    let priority2 = g:wince_uberwingrouptype[a:grouptypename2].priority

    return priority1 == priority2 ? 0 : priority1 > priority2 ? 1 : -1
endfunction

" Comparator for sorting subwin group type names by priority
function! s:CompareSubwinGroupTypeNamesByPriority(grouptypename1, grouptypename2)
    call EchomLog('wince-model', 'verbose', 'CompareSubwinGroupTypeNamesByMinPriority ', a:grouptypename1, ' ', a:grouptypename2)
    let priority1 = g:wince_subwingrouptype[a:grouptypename1].priority
    let priority2 = g:wince_subwingrouptype[a:grouptypename2].priority

    return priority1 == priority2 ? 0 : priority1 > priority2 ? 1 : -1
endfunction

" Return a list of names of group types of all non-hidden uberwin groups with
" priorities higher than a given, sorted in ascending order of priority
function! WinceModelUberwinGroupTypeNamesByMinPriority(minpriority)
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinGroupTypeNamesByMinPriority ', a:minpriority)
    call s:EnsureWinceModelExists()
    if type(a:minpriority) != v:t_number
        throw 'minpriority must be a number'
    endif

    let grouptypenames = []
    for grouptypename in keys(t:wince_uberwin)
        if t:wince_uberwin[grouptypename].hidden
            call EchomLog('wince-model', 'verbose', 'Omitting hidden uberwin group ', grouptypename)
            continue
        endif
        if g:wince_uberwingrouptype[grouptypename].priority <= a:minpriority
            call EchomLog('wince-model', 'verbose', 'Omitting uberwin group ', grouptypename, ' due to its low priority ', g:wince_uberwingrouptype[grouptypename].priority)
            continue
        endif
        call EchomLog('wince-model', 'verbose', 'Uberwin group ', grouptypename, ' included in query')
        call add(grouptypenames, grouptypename)
    endfor

    call EchomLog('wince-model', 'verbose', 'Sorting uberwin groups')
    call sort(grouptypenames, function('s:CompareUberwinGroupTypeNamesByPriority'))
    call EchomLog('wince-model', 'debug', 'Uberwin groups: ', grouptypenames)
    return grouptypenames
endfunction
" Return a list of names of all uberwin group types sorted in ascending order
" of priority
function! WinceModelAllUberwinGroupTypeNamesByPriority()
    call EchomLog('wince-model', 'debug', 'WinceModelAllUberwinGroupTypeNamesByPriority')
    let grouptypenames = keys(g:wince_uberwingrouptype)

    call EchomLog('wince-model', 'verbose', 'Sorting uberwin group types')
    call sort(grouptypenames, function('s:CompareUberwinGroupTypeNamesByPriority'))
    call EchomLog('wince-model', 'debug', 'Uberwin groups: ', grouptypenames)
    return grouptypenames
endfunction

" Return a list of names of group types of all non-hidden subwin groups with
" priority higher than a given, for a given supwin, sorted in ascending order
" of priority
function! WinceModelSubwinGroupTypeNamesByMinPriority(supwinid, minpriority)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinGroupTypeNamesByMinPriority ', a:supwinid, a:minpriority)
    call s:EnsureWinceModelExists()
    if type(a:minpriority) != v:t_number
        throw 'minpriority must be a number'
    endif

    let grouptypenames = []
    for grouptypename in keys(t:wince_supwin[a:supwinid].subwin)
        if t:wince_supwin[a:supwinid].subwin[grouptypename].hidden
            call EchomLog('wince-model', 'verbose', 'Omitting hidden subwin group ', a:supwinid, ':', grouptypename)
            continue
        endif
        if g:wince_subwingrouptype[grouptypename].priority <= a:minpriority
            call EchomLog('wince-model', 'verbose', 'Omitting subwin group ', a:supwinid, ':', grouptypename, ' due to its low priority ', g:wince_subwingrouptype[grouptypename].priority)
            continue
        endif
        call EchomLog('wince-model', 'verbose', 'Subwin group ', a:supwinid, ':', grouptypename, ' included in query')
        call add(grouptypenames, grouptypename)
    endfor

    call EchomLog('wince-model', 'verbose', 'Sorting subwin groups')
    call sort(grouptypenames, function('s:CompareSubwinGroupTypeNamesByPriority'))
    call EchomLog('wince-model', 'debug', 'Subwin groups: ', grouptypenames)
    return grouptypenames
endfunction
" Return a list of names of all subwin group types sorted in ascending order
" of priority
function! WinceModelAllSubwinGroupTypeNamesByPriority()
    call EchomLog('wince-model', 'debug', 'WinceModelAllSubwinGroupTypeNamesByPriority')
    let grouptypenames = keys(g:wince_subwingrouptype)

    call EchomLog('wince-model', 'verbose', 'Sorting subwin group types')
    call sort(grouptypenames, function('s:CompareSubwinGroupTypeNamesByPriority'))
    call EchomLog('wince-model', 'debug', 'Subwin groups: ', grouptypenames)
    return grouptypenames
endfunction

" Validate a list of winids to be added to the model someplace
function! s:ValidateNewWinids(winids, explen)
    call EchomLog('wince-model', 'debug', 'ValidateNewWinids ', a:winids, ' ', a:explen)
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
    let existingwinids = WinceModelUberwinIds() +
                        \WinceModelSupwinIds() +
                        \WinceModelSubwinIds()
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
    call EchomLog('wince-model', 'debug', 'ValidateNewDimensions ', a:category, ':', a:grouptypename, ':', a:typename, ' [', a:nr, ',', a:w, ',', a:h, ']')
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
        call WinceModelAssertUberwinTypeExists(a:grouptypename, a:typename)
        let typeidx = index(g:wince_uberwingrouptype[a:grouptypename].typenames, a:typename)
        let expw = g:wince_uberwingrouptype[a:grouptypename].widths[typeidx]
        let exph = g:wince_uberwingrouptype[a:grouptypename].heights[typeidx]
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
    call EchomLog('wince-model', 'debug', 'ValidateNewDimensionsList ', a:category, ':', a:grouptypename, ' ', a:dims)
    if type(a:dims) !=# v:t_list
        throw 'given dimensions list is not a list'
    endif
    
    if a:category ==# 'uberwin'
        if empty(a:dims)
            let retlist = []
            for i in range(len(g:wince_uberwingrouptype[a:grouptypename].typenames))
                call add(retlist, {
               \    'nr': -1,
               \    'w': -1,
               \    'h': -1 
               \})
            endfor
            call EchomLog('wince-model', 'debug', 'Populated dummy dimensions: ', retlist)
            return retlist
        endif
        if len(a:dims) !=# len(g:wince_uberwingrouptype[a:grouptypename].typenames)
            throw len(a:dims) . ' is the wrong number of dimensions for ' . a:grouptypename
        endif
    endif

    for typeidx in range(len(g:wince_uberwingrouptype[a:grouptypename].typenames))
        call EchomLog('wince-model', 'verbose', 'Validate dimensions ', a:dims[typeidx])
        " TODO? Fill in missing dicts with -1,-1,-1
        " - This will only be required if there's ever a case where multiple
        "   windows are added to the model at the same time, but only some of
        "   them have non-dummy dimensions
        let dim = a:dims[typeidx]
        let typename = g:wince_uberwingrouptype[a:grouptypename].typenames[typeidx]
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
    call EchomLog('wince-model', 'debug', 'ValidateNewSubwinDimensionsList ', a:grouptypename, ':', a:typename, ' [', a:relnr, ',', a:w, ',', a:h, ']')
    if type(a:relnr) !=# v:t_number
        throw "relnr must be a number"
    endif
    if type(a:w) !=# v:t_number || a:w <# -1
        throw "w must be at least -1"
    endif
    if type(a:h) !=# v:t_number || a:h <# -1
        throw "h must be at least -1"
    endif
    call WinceModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    let typeidx = index(g:wince_subwingrouptype[a:grouptypename].typenames, a:typename)
    let expw = g:wince_subwingrouptype[a:grouptypename].widths[typeidx]
    let exph = g:wince_subwingrouptype[a:grouptypename].heights[typeidx]
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
    call EchomLog('wince-model', 'debug', 'ValidateNewSubwinDimensionsList ', a:grouptypename, ' ', a:dims)
    if type(a:dims) !=# v:t_list
        throw 'given subwin dimensions list is not a list'
    endif
    if empty(a:dims)
        let retlist = []
        for i in range(len(g:wince_subwingrouptype[a:grouptypename].typenames))
            call add(retlist, {
           \    'relnr': 0,
           \    'w': -1,
           \    'h': -1 
           \})
        endfor
        call EchomLog('wince-model', 'debug', 'Populated dummy dimensions: ', retlist)
        return retlist
    endif
    if len(a:dims) !=# len(g:wince_subwingrouptype[a:grouptypename].typenames)
        throw len(dims) . ' is the wrong number of dimensions for ' . a:grouptypename
    endif

    for typeidx in range(len(g:wince_subwingrouptype[a:grouptypename].typenames))
        call EchomLog('wince-model', 'verbose', 'Validate dimensions ', a:dims[typeidx])
        " TODO? Fill in missing dicts with 0,-1,-1
        " - This will only be required if there's ever a case where multiple
        "   windows are added to the model at the same time, but only some of
        "   them have non-dummy dimensions
        let typename = g:wince_subwingrouptype[a:grouptypename].typenames[typeidx]
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
function! WinceModelToIdentifyUberwins()
    call EchomLog('wince-model', 'debug', 'WinceModelToIdentifyUberwins')
    let retdict = {}
    for grouptypename in keys(g:wince_uberwingrouptype)
        let retdict[grouptypename] = g:wince_uberwingrouptype[grouptypename].toIdentify
    endfor
    call EchomLog('wince-model', 'debug', 'Retrieved: ', retdict)
    return retdict
endfunction

" Get a dict of all subwins' toIdentify functions keyed by their group type
function! WinceModelToIdentifySubwins()
    call EchomLog('wince-model', 'debug', 'WinceModelToIdentifySubwins')
    let retdict = {}
    for grouptypename in keys(g:wince_subwingrouptype)
        let retdict[grouptypename] = g:wince_subwingrouptype[grouptypename].toIdentify
    endfor
    call EchomLog('wince-model', 'debug', 'Retrieved: ', retdict)
    return retdict
endfunction

" Uberwin group manipulation
function! WinceModelUberwinGroupExists(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinGroupExists ', a:grouptypename)
    call s:EnsureWinceModelExists()
    call WinceModelAssertUberwinGroupTypeExists(a:grouptypename)
    return has_key(t:wince_uberwin, a:grouptypename )
endfunction
function! WinceModelAssertUberwinGroupExists(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertUberwinGroupExists ', a:grouptypename)
    if !WinceModelUberwinGroupExists(a:grouptypename)
        throw 'nonexistent uberwin group ' . a:grouptypename
    endif
endfunction
function! WinceModelAssertUberwinGroupDoesntExist(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertUberwinGroupDoesntExist ', a:grouptypename)
    if WinceModelUberwinGroupExists(a:grouptypename)
        throw 'uberwin group ' . a:grouptypename . ' exists'
    endif
endfunction

function! WinceModelUberwinGroupIsHidden(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinGroupIsHidden ', a:grouptypename)
    call WinceModelAssertUberwinGroupExists(a:grouptypename)
    return t:wince_uberwin[ a:grouptypename ].hidden
endfunction
function! WinceModelAssertUberwinGroupIsHidden(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertUberwinGroupIsHidden ', a:grouptypename)
    if !WinceModelUberwinGroupIsHidden(a:grouptypename)
       throw 'uberwin group ' . a:grouptypename . ' is not hidden'
    endif
endfunction
function! WinceModelAssertUberwinGroupIsNotHidden(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertUberwinGroupIsNotHidden ', a:grouptypename)
    if WinceModelUberwinGroupIsHidden(a:grouptypename)
        throw 'uberwin group ' . a:grouptypename . ' is hidden'
    endif
endfunction
function! WinceModelUberwinGroupTypeNames()
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinGroupTypeNames ', a:grouptypename)
    return keys(g:wince_uberwingrouptype)
endfunction
function! WinceModelShownUberwinGroupTypeNames()
    call EchomLog('wince-model', 'debug', 'WinceModelShownUberwinGroupTypeNames')
    call s:EnsureWinceModelExists()
    let grouptypenames = []
    for grouptypename in keys(t:wince_uberwin)
        if !WinceModelUberwinGroupIsHidden(grouptypename)
            call add(grouptypenames, grouptypename)
        endif
    endfor
    call sort(grouptypenames, function('s:CompareUberwinGroupTypeNamesByPriority'))
    call EchomLog('wince-model', 'debug', 'Shown uberwin groups: ', grouptypenames)
    return grouptypenames
endfunction
function! WinceModelUberwinTypeNamesByGroupTypeName(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinTypeNamesByGroupTypeName ', a:grouptypename)
    call WinceModelAssertUberwinGroupTypeExists(a:grouptypename)
    let typenames =  g:wince_uberwingrouptype[a:grouptypename].typenames
    call EchomLog('wince-model', 'debug', 'Type names for uberwin group ', a:grouptypename, ': ', typenames)
    return typenames
endfunction
function! WinceModelUberwinDimensions(grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'WinceModelUberwinDimensions ', a:grouptypename, ':', a:typename)
    call WinceModelAssertUberwinTypeExists(a:grouptypename, a:typename)
    call WinceModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    let windict = t:wince_uberwin[a:grouptypename].uberwin[a:typename]
    let retdict = {'nr':windict.nr,'w':windict.w,'h':windict.h}
    call EchomLog('wince-model', 'debug', 'Dimensions of uberwin ', a:grouptypename, ':', a:typename, ': ', retdict)
    return retdict
endfunction

function! WinceModelAddUberwins(grouptypename, winids, dimensions)
    call EchomLog('wince-model', 'info', 'WinceModelAddUberwins ', a:grouptypename, ' ', a:winids, ' ', a:dimensions)
    call WinceModelAssertUberwinGroupDoesntExist(a:grouptypename)
    
    " If no winids are supplied, the uberwin is initially hidden
    if !len(a:winids)
        call EchomLog('wince-model', 'verbose', 'No winids give, Adding uberwin group ', a:grouptypename, ' as hidden')
        let hidden = 1
        let uberwindict = {}

    " If winids are supplied, the uberwin is initially visible
    else
        call s:ValidateNewWinids(
       \    a:winids,
       \    len(g:wince_uberwingrouptype[a:grouptypename].typenames)
       \)

        let vdimensions = s:ValidateNewDimensionsList(
       \    'uberwin',
       \    a:grouptypename,
       \    a:dimensions,
       \)
        
        call EchomLog('wince-model', 'verbose', 'Winids and dimensions valid. Adding uberwin group ', a:grouptypename, ' as shown')
        
        let hidden = 0

        " Build the model for this uberwin group
        let uberwindict = {}
        for i in range(len(a:winids))
            let uberwindict[g:wince_uberwingrouptype[a:grouptypename].typenames[i]] = {
           \    'id': a:winids[i],
           \    'nr': vdimensions[i].nr,
           \    'w': vdimensions[i].w,
           \    'h': vdimensions[i].h
           \}
        endfor
    endif

    " Record the model
    let t:wince_uberwin[a:grouptypename] = {
   \    'hidden': hidden,
   \    'uberwin': uberwindict
   \}
endfunction

function! WinceModelRemoveUberwins(grouptypename)
    call EchomLog('wince-model', 'info', 'WinceModelRemoveUberwins ', a:grouptypename)
    call WinceModelAssertUberwinGroupExists(a:grouptypename)
    call remove(t:wince_uberwin, a:grouptypename)
endfunction

function! WinceModelHideUberwins(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelHideUberwins ', a:grouptypename)
    call WinceModelAssertUberwinGroupExists(a:grouptypename)
    call WinceModelAssertUberwinGroupIsNotHidden(a:grouptypename)

    let t:wince_uberwin[a:grouptypename].hidden = 1
    let t:wince_uberwin[a:grouptypename].uberwin = {}
endfunction

function! WinceModelShowUberwins(grouptypename, winids, dimensions)
    call EchomLog('wince-model', 'info', 'WinceModelShowUberwins ', a:grouptypename, ' ', a:winids, ' ', a:dimensions)
    call WinceModelAssertUberwinGroupExists(a:grouptypename)
    call WinceModelAssertUberwinGroupIsHidden(a:grouptypename)
    call s:ValidateNewWinids(
   \    a:winids,
   \    len(g:wince_uberwingrouptype[a:grouptypename].typenames)
   \)
    let vdimensions = s:ValidateNewDimensionsList(
   \    'uberwin',
   \    a:grouptypename,
   \    a:dimensions,
   \)

    let t:wince_uberwin[a:grouptypename].hidden = 0
    let uberwindict = {}
    for i in range(len(a:winids))
        let uberwindict[g:wince_uberwingrouptype[a:grouptypename].typenames[i]] = {
       \    'id': a:winids[i],
       \    'nr': vdimensions[i].nr,
       \    'w': vdimensions[i].w,
       \    'h': vdimensions[i].h
       \}
    endfor
    let t:wince_uberwin[a:grouptypename].uberwin = uberwindict
endfunction

function! WinceModelAddOrShowUberwins(grouptypename, uberwinids, dimensions)
    call EchomLog('wince-model', 'info', 'WinceModelAddOrShowUberwins ', a:grouptypename, ' ', a:uberwinids, ' ', a:dimensions)
    if !WinceModelUberwinGroupExists(a:grouptypename)
        call EchomLog('wince-model', 'verbose', 'Uberwin group ', a:grouptypename, ' not present in model. Adding.')
        call WinceModelAddUberwins(a:grouptypename, a:uberwinids, a:dimensions)
    else
        call EchomLog('wince-model', 'verbose', 'Uberwin group ', a:grouptypename, ' hidden in model. Showing.')
        call WinceModelShowUberwins(a:grouptypename, a:uberwinids, a:dimensions)
    endif
endfunction

function! WinceModelChangeUberwinIds(grouptypename, winids)
    call EchomLog('wince-model', 'info', 'WinceModelChangeUberwinIds ', a:grouptypename, ' ', a:winids)
    call WinceModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    call s:ValidateNewWinids(
   \    a:winids,
   \    len(g:wince_uberwingrouptype[a:grouptypename].typenames)
   \)

    let uberwindict = {}
    for i in range(len(a:winids))
        let typename = g:wince_uberwingrouptype[a:grouptypename].typenames[i]
        let t:wince_uberwin[a:grouptypename].uberwin[typename].id = a:winids[i]
    endfor
endfunction

function! WinceModelChangeUberwinDimensions(grouptypename, typename, nr, w, h)
    call EchomLog('wince-model', 'debug', 'WinceModelChangeUberwinDimensions ', a:grouptypename, ':', a:typename, ' [', a:nr, ',', a:w, ',', a:h, ']')
    call WinceModelAssertUberwinTypeExists(a:grouptypename, a:typename)
    call WinceModelAssertUberwinGroupIsNotHidden(a:grouptypename)
    call s:ValidateNewDimensions('uberwin', a:grouptypename, a:typename, a:nr, a:w, a:h)

    let t:wince_uberwin[a:grouptypename].uberwin[a:typename].nr = a:nr
    let t:wince_uberwin[a:grouptypename].uberwin[a:typename].w = a:w
    let t:wince_uberwin[a:grouptypename].uberwin[a:typename].h = a:h
endfunction

function! WinceModelChangeUberwinGroupDimensions(grouptypename, dims)
    call EchomLog('wince-model', 'debug', 'WinceModelChangeUberwinGroupDimensions ', a:grouptypename, ' ', a:dims)
    let vdims = s:ValidateNewDimensionsList('uberwin', a:grouptypename, a:dims)

    for typeidx in range(len(g:wince_uberwingrouptype[a:grouptypename].typenames))
        let typename = g:wince_uberwingrouptype[a:grouptypename].typenames[typeidx]
        call WinceModelChangeUberwinDimensions(
       \    a:grouptypename,
       \    typename,
       \    vdims[typeidx].nr,
       \    vdims[typeidx].w,
       \    vdims[typeidx].h
       \)
    endfor
endfunction

" Supwin manipulation
function! WinceModelSupwinExists(winid)
    call EchomLog('wince-model', 'debug', 'WinceModelSupwinExists ', a:winid)
    call s:EnsureWinceModelExists()
    return has_key(t:wince_supwin, a:winid)
endfunction
function! WinceModelAssertSupwinExists(winid)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSupwinExists ', a:winid)
    if !WinceModelSupwinExists(a:winid)
        throw 'nonexistent supwin ' . a:winid
    endif
endfunction
function! WinceModelAssertSupwinDoesntExist(winid)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSupwinDoesntExist ', a:winid)
    if WinceModelSupwinExists(a:winid)
        throw 'supwin ' . a:winid . ' exists'
    endif
endfunction
function! WinceModelSupwinDimensions(supwinid)
    call EchomLog('wince-model', 'debug', 'WinceModelSupwinDimensions ', a:supwinid)
    call WinceModelAssertSupwinExists(a:supwinid)
    let windict = t:wince_supwin[a:supwinid]
    let retdict = {'nr':windict.nr,'w':windict.w,'h':windict.h}
    call EchomLog('wince-model', 'debug', 'Dimensions of supwin ', a:supwinid, ': ', retdict)
    return retdict
endfunction

function! WinceModelChangeSupwinDimensions(supwinid, nr, w, h)
    call EchomLog('wince-model', 'debug', 'WinceModelChangeSupwinDimensions ', a:supwinid, ' [', a:nr, ',', a:w, ',', a:h, ']')
    call WinceModelAssertSupwinExists(a:supwinid)
    call s:ValidateNewDimensions('supwin', '', '', a:nr, a:w, a:h)

    let t:wince_supwin[a:supwinid].nr = a:nr
    let t:wince_supwin[a:supwinid].w = a:w
    let t:wince_supwin[a:supwinid].h = a:h
endfunction

" Subwin group manipulation
function! WinceModelSubwinGroupExists(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinGroupExists ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    call WinceModelAssertSupwinExists(a:supwinid)

    return has_key(t:wince_supwin[a:supwinid].subwin, a:grouptypename)
endfunction
function! WinceModelAssertSubwinGroupExists(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinGroupExists ', a:supwinid, ':', a:grouptypename)
    if !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has no subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinceModelAssertSubwinGroupDoesntExist(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinGroupDoesntExist ', a:supwinid, ':', a:grouptypename)
    if WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        throw 'supwin ' .
       \      a:supwinid .
       \      ' has subwin group of type ' .
       \      a:grouptypename
    endif
endfunction
function! WinceModelSubwinGroupIsHidden(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinGroupIsHidden ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    return t:wince_supwin[a:supwinid].subwin[a:grouptypename].hidden
endfunction
function! WinceModelAssertSubwinGroupIsHidden(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinGroupIsHidden ', a:supwinid, ':', a:grouptypename)
    if !WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        throw 'subwin group ' .
       \      a:grouptypename .
       \      ' not hidden for supwin ' .
       \      a:supwinid
    endif
endfunction
function! WinceModelAssertSubwinGroupIsNotHidden(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinGroupIsNotHidden ', a:supwinid, ':', a:grouptypename)
    if WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        throw 'subwin group ' .
       \      a:grouptypename .
       \      ' is hidden for supwin ' .
       \      a:supwinid
    endif
endfunction
function! WinceModelSubwinIsAfterimaged(supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinIsAfterimaged ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call WinceModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    return t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].afterimaged
endfunction
function! WinceModelAssertSubwinIsAfterimaged(supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinIsAfterimaged ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    if !WinceModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, a:typename)
        throw 'subwin ' .
       \      a:grouptypename .
       \      ':' .
       \      a:typename .
       \      ' for supwin ' .
       \      a:supwinid .
       \      ' is not afterimaged'
    endif
endfunction
function! WinceModelAssertSubwinIsNotAfterimaged(supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'WinceModelAssertSubwinIsNotAfterimaged ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    if WinceModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, a:typename)
        throw 'subwin ' .
       \      a:grouptypename .
       \      ':' .
       \      a:typename .
       \      ' for supwin ' .
       \      a:supwinid .
       \      ' is not afterimaged'
    endif
endfunction
function! WinceModelSubwinGroupHasAfterimagedSubwin(supwinid, grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinGroupHasAfterimagedSubwin ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    for typename in WinceModelSubwinTypeNamesByGroupTypeName(a:grouptypename)
        call EchomLog('wince-model', 'verbose', 'Checking subwin ', a:supwinid, ':', a:grouptypename, ':', typename)
        if WinceModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call EchomLog('wince-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' has afterimaged subwin ', typename)
            return 1
        endif
    endfor
    call EchomLog('wince-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' has no afterimaged subwins')
    return 0
endfunction
function! s:SubwinidIsInSubwinList(subwinid)
    call EchomLog('wince-model', 'debug', 'SubwinidIsInSubwinList ', a:subwinid)
    call s:EnsureWinceModelExists()
    return has_key(t:wince_subwin, a:subwinid)
endfunction
function! s:AssertSubwinidIsInSubwinList(subwinid)
    call EchomLog('wince-model', 'debug', 'AssertSubwinidIsInSubwinList ', a:subwinid)
    if !s:SubwinidIsInSubwinList(a:subwinid)
        throw 'subwin id ' . a:subwinid . ' not in subwin list'
    endif
endfunction
function! s:AssertSubwinidIsNotInSubwinList(subwinid)
    call EchomLog('wince-model', 'debug', 'AssertSubwinidIsNotInSubwinList ', a:subwinid)
    if s:SubwinidIsInSubwinList(a:subwinid)
        throw 'subwin id ' . a:subwinid . ' is in subwin list'
    endif
endfunction
function! s:SubwinIdFromSubwinList(supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'SubwinIdFromSubwinList ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call s:EnsureWinceModelExists()
    let foundsubwinid = 0
    for subwinid in keys(t:wince_subwin)
        call EchomLog('wince-model', 'verbose', 'Checking subwin ID ', subwinid)
        let subwin = t:wince_subwin[subwinid]
        if subwin.supwin ==# a:supwinid &&
       \   subwin.grouptypename ==# a:grouptypename &&
       \   subwin.typename ==# a:typename
            call EchomLog('wince-model', 'Subwin ID ', subwinid, ' matches subwin ', a:supwinid, ':', a:grouptypename, ':', a:typename)
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
    call EchomLog('wince-model', 'debug', 'AssertSubwinIsInSubwinList ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    if !s:SubwinIdFromSubwinList(a:supwinid, a:grouptypename, a:typename)
        throw 'subwin ' . a:grouptypename . ':' . a:typename . ' for supwin ' .
       \      a:supwinid . ' not in subwin list'
    endif
endfunction
function! s:AssertSubwinIsNotInSubwinList(supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'AssertSubwinIsNotInSubwinList ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    let subwinid = s:SubwinIdFromSubwinList(a:supwinid, a:grouptypename, a:typename)
    if subwinid
        throw 'subwin ' . a:grouptypename . ':' . a:typename . ' for supwin ' .
       \      a:supwinid . ' in subwin list with subwin id ' . subwinid
    endif
endfunction
function! s:AssertSubwinListHas(subwinid, supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'AssertSubwinListHas ', a:subwinid, ' ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call s:AssertSubwinidIsInSubwinList(a:subwinid)
    let subwin = t:wince_subwin[a:subwinid]
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
    call EchomLog('wince-model', 'debug', 'AssertSubwinGroupIsConsistent ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    if !WinceModelSupwinExists(a:supwinid)
        return
    elseif WinceModelSubwinGroupExists(a:supwinid, a:grouptypename) &&
   \       !WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for typename in g:wince_subwingrouptype[a:grouptypename].typenames
            call EchomLog('wince-model', 'verbose', 'Checking shown subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' for model consistency')
            let subwinid = t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id
            call s:AssertSubwinListHas(
           \    subwinid,
           \    a:supwinid,
           \    a:grouptypename,
           \    typename
           \)
            call s:ValidateNewSubwinDimensions(
           \    a:grouptypename,
           \    typename,
           \    t:wince_subwin[subwinid].relnr,
           \    t:wince_subwin[subwinid].w,
           \    t:wince_subwin[subwinid].h
           \)
            if WinceModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
                if t:wince_subwin[subwinid].aibuf == -1
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
                if t:wince_subwin[subwinid].aibuf != -1
                    throw 'subwin ' .
                   \      a:grouptypename .
                   \      ':' . typename .
                   \      ' (id ' .
                   \      subwinid .
                   \      ') for supwin ' .
                   \      a:supwinid .
                   \      ' is not afterimaged but has afterimage buffer ' .
                   \      t:wince_subwin[subwinid].aibuf
                endif
            endif
        endfor
    else
        for typename in g:wince_subwingrouptype[a:grouptypename].typenames
            call EchomLog('wince-model', 'verbose', 'Checking hidden subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' for model consistency')
            call s:AssertSubwinIsNotInSubwinList(
           \    a:supwinid,
           \    a:grouptypename,
           \    typename
           \)
        endfor
    endif
endfunction
function! WinceModelSubwinGroupTypeNames()
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinGroupTypeNames')
    call EchomLog('wince-model', 'debug', 'Subwin group type names: ', keys(g:wince_subwingrouptype))
    return keys(g:wince_subwingrouptype)
endfunction
function! WinceModelShownSubwinGroupTypeNamesBySupwinId(supwinid)
    call EchomLog('wince-model', 'debug', 'WinceModelShownSubwinGroupTypeNamesBySupwinId ', a:supwinid)
    call WinceModelAssertSupwinExists(a:supwinid)
    let grouptypenames = []
    for grouptypename in keys(t:wince_supwin[a:supwinid].subwin)
        if !WinceModelSubwinGroupIsHidden(a:supwinid, grouptypename)
            call add(grouptypenames, grouptypename)
        endif
    endfor
    call EchomLog('wince-model', 'debug', 'Shown subwin groups for supwin ', a:supwinid, ': ', grouptypenames)
    return sort(grouptypenames, function('s:CompareSubwinGroupTypeNamesByPriority'))
endfunction
function! WinceModelSubwinTypeNamesByGroupTypeName(grouptypename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinTypeNamesByGroupTypeName ', a:grouptypename)
    call WinceModelAssertSubwinGroupTypeExists(a:grouptypename)
    let typenames =  g:wince_subwingrouptype[a:grouptypename].typenames
    call EchomLog('wince-model', 'debug', 'Type names for subwin group ', a:grouptypename, ': ', typenames)
    return typenames
endfunction
function! WinceModelSubwinDimensions(supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinDimensions ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call WinceModelAssertSubwinTypeExists(a:grouptypename, a:typename)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    let subwinid = t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let windict = t:wince_subwin[subwinid]
    let retdict =  {'relnr':windict.relnr,'w':windict.w,'h':windict.h}
    call EchomLog('wince-model', 'debug', 'Dimensions of subwin ', a:supwinid, ':', a:grouptypename, ':', a:typename, ': ', retdict)
    return retdict
endfunction
function! WinceModelSubwinAibufBySubwinId(subwinid)
    call EchomLog('wince-model', 'debug', 'WinceModelSubwinAibufBySubwinId ', a:subwinid)
    call s:EnsureWinceModelExists()
    call s:AssertSubwinidIsInSubwinList(a:subwinid)
    call EchomLog('wince-model', 'debug', 'Afterimage buffer for subwin ', a:subwinid, ': ', t:wince_subwin[a:subwinid].aibuf)
    return t:wince_subwin[a:subwinid].aibuf
endfunction
function! WinceModelShownSubwinIdsBySupwinId(supwinid)
    call EchomLog('wince-model', 'debug', 'WinceModelShownSubwinIdsBySupwinId ', a:supwinid)
    call WinceModelAssertSupwinExists(a:supwinid)
    let winids = []
    for grouptypename in keys(t:wince_supwin[a:supwinid].subwin)
        if !WinceModelSubwinGroupIsHidden(a:supwinid, grouptypename)
            for typename in keys(t:wince_supwin[a:supwinid].subwin[grouptypename].subwin)
                call EchomLog('wince-model', 'verbose', 'Shown subwin ', a:supwinid, ':', grouptypename, ':', typename, ' has ID ', t:wince_supwin[a:supwinid].subwin[grouptypename].subwin[typename].id)
                call add(winids, t:wince_supwin[a:supwinid].subwin[grouptypename].subwin[typename].id)
            endfor
        endif
    endfor
    call EchomLog('wince-model', 'debug', 'IDs of shown subwins of supwin ', a:supwinid, ': ', winids)
    return winids
endfunction

function! WinceModelAddSupwin(winid, nr, w, h)
    call EchomLog('wince-model', 'info', 'WinceModelAddSupwin ', a:winid, ' [', a:nr, ',', a:w, ',', a:h, ']')
    call s:EnsureWinceModelExists()
    if has_key(t:wince_supwin, a:winid)
        throw 'window ' . a:winid . ' is already a supwin'
    endif
    call s:ValidateNewDimensions('supwin', '', '', a:nr, a:w, a:h)
    let t:wince_supwin[a:winid] = {'subwin':{},'nr':a:nr,'w':a:w,'h':a:h}
endfunction

" This function returns a data structure containing all of the information
" that was removed from the model, so that it can later be added back by
" WinceModelRestoreSupwin
function! WinceModelRemoveSupwin(winid)
    call EchomLog('wince-model', 'info', 'WinceModelRemoveSupwin ', a:winid)
    call WinceModelAssertSupwinExists(a:winid)

    let subwindata = {}
    for grouptypename in keys(t:wince_supwin[a:winid].subwin)
        call WinceModelAssertSubwinGroupExists(a:winid, grouptypename)
        for typename in keys(t:wince_supwin[a:winid].subwin[grouptypename].subwin)
            let subwinid = t:wince_supwin[a:winid].subwin[grouptypename].subwin[typename].id
            call EchomLog('wince-model', 'debug', 'Removing subwin ', a:winid, ':', grouptypename, ':', typename, ' with ID ', subwinid, ' from subwin list')
            let subwindata[subwinid] = t:wince_subwin[subwinid]
            call remove(t:wince_subwin, subwinid)
        endfor
    endfor

    let supwindata = t:wince_supwin[a:winid]
    call remove(t:wince_supwin, a:winid)

    return {'id':a:winid,'supwin':supwindata,'subwin':subwindata}
endfunction

" Use the return value of WinceModelRemoveSupwin to re-add a supwin to the model
function! WinceModelRestoreSupwin(data)
    call EchomLog('wince-model', 'info', 'WinceModelRestoreSupwin ', a:data)
    call s:EnsureWinceModelExists()
    call WinceModelAssertSupwinDoesntExist(a:data.id)

    let t:wince_supwin[a:data.id] = a:data.supwin
    for subwinid in keys(a:data.subwin)
        let t:wince_subwin[subwinid] = a:data.subwin[subwinid]
    endfor
endfunction

function! WinceModelAddSubwins(supwinid, grouptypename, subwinids, dimensions)
    call EchomLog('wince-model', 'info', 'WinceModelAddSubwins ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids, ' ', a:dimensions)
    call WinceModelAssertSubwinGroupDoesntExist(a:supwinid, a:grouptypename)
    
    " If no winids are supplied, the uberwin is initially hidden
    if !len(a:subwinids)
        call EchomLog('wince-model', 'verbose', 'No winids given. Adding subwin group ', a:supwinid, ':', a:grouptypename, ' as hidden')
        let hidden = 1
        let subwindict = {}

    " If winids are supplied, the subwin is initially visible
    else
        call s:ValidateNewWinids(
       \    a:subwinids,
       \    len(g:wince_subwingrouptype[a:grouptypename].typenames)
       \)

        let vdimensions = s:ValidateNewSubwinDimensionsList(
       \    a:grouptypename,
       \    a:dimensions,
       \)

        call EchomLog('wince-model', 'verbose', 'Winids and dimensions valid. Adding subwin group ', a:supwinid, ':', a:grouptypename, ' as shown')
        
        let hidden = 0

        " Build the model for this subwin group
        let subwindict = {}
        for i in range(len(a:subwinids))
            let typename = g:wince_subwingrouptype[a:grouptypename].typenames[i]
            let subwindict[typename] = {
           \    'id': a:subwinids[i],
           \    'afterimaged': 0
           \}

            let t:wince_subwin[a:subwinids[i]] = {
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
    let t:wince_supwin[a:supwinid].subwin[a:grouptypename] = {
   \    'hidden': hidden,
   \    'subwin': subwindict
   \}

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelRemoveSubwins(supwinid, grouptypename)
    call EchomLog('wince-model', 'info', 'WinceModelRemoveSubwins ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    if !WinceModelSubwinGroupIsHidden(a:supwinid, a:grouptypename)
        for subwintypename in keys(t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin)
            call EchomLog('wince-model', 'debug', 'Removing subwin ', a:supwinid, ':', a:grouptypename, ':', subwintypename, ' with ID ', t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id, ' from subwin list')
            call remove(
           \    t:wince_subwin,
           \    t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id
           \)
        endfor
    endif
    call remove(t:wince_supwin[a:supwinid].subwin, a:grouptypename)

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelHideSubwins(supwinid, grouptypename)
    call EchomLog('wince-model', 'info', 'WinceModelHideSubwins ', a:supwinid, ':', a:grouptypename)
    call WinceModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)

    for subwintypename in keys(t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin)
            call EchomLog('wince-model', 'debug', 'Removing subwin ', a:supwinid, ':', a:grouptypename, ':', subwintypename, ' with ID ', t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id, ' from subwin list')
        call remove(
       \    t:wince_subwin,
       \    t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].id
       \)
        let t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[subwintypename].afterimaged = 0
    endfor

    let t:wince_supwin[a:supwinid].subwin[a:grouptypename].hidden = 1
    let t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin = {}

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelShowSubwins(supwinid, grouptypename, subwinids, dimensions)
    call EchomLog('wince-model', 'info', 'WinceModelShowSubwins ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids, ' ', a:dimensions)
    call WinceModelAssertSubwinGroupExists(a:supwinid, a:grouptypename)
    call WinceModelAssertSubwinGroupIsHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewWinids(
   \    a:subwinids,
   \    len(g:wince_subwingrouptype[a:grouptypename].typenames)
   \)
    let vdimensions = s:ValidateNewSubwinDimensionsList(
   \    a:grouptypename,
   \    a:dimensions,
   \)

    let t:wince_supwin[a:supwinid].subwin[a:grouptypename].hidden = 0
    let subwindict = {}
    for i in range(len(a:subwinids))
        let typename = g:wince_subwingrouptype[a:grouptypename].typenames[i]
        let subwindict[typename] = {
       \    'id': a:subwinids[i],
       \    'afterimaged': 0
       \}

        let t:wince_subwin[a:subwinids[i]] = {
       \    'supwin': a:supwinid,
       \    'grouptypename': a:grouptypename,
       \    'typename': typename,
       \    'aibuf': -1,
       \    'relnr': vdimensions[i].relnr,
       \    'w': vdimensions[i].w,
       \    'h': vdimensions[i].h
       \}
    endfor
    let t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin = subwindict

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelAddOrShowSubwins(supwinid, grouptypename, subwinids, dimensions)
    call EchomLog('wince-model', 'info', 'WinceModelAddOrShowSubwins ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids, ' ', a:dimensions)
    if !WinceModelSubwinGroupExists(a:supwinid, a:grouptypename)
        call EchomLog('wince-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' not present in model. Adding.')
        call WinceModelAddSubwins(a:supwinid, a:grouptypename, a:subwinids, a:dimensions)
    else
        call EchomLog('wince-model', 'verbose', 'Subwin group ', a:supwinid, ':', a:grouptypename, ' hidden in model. Showing.')
        call WinceModelShowSubwins(a:supwinid, a:grouptypename, a:subwinids, a:dimensions)
    endif
endfunction

function! WinceModelChangeSubwinIds(supwinid, grouptypename, subwinids)
    call EchomLog('wince-model', 'info', 'WinceModelChangeSubwinIds ', a:supwinid, ':', a:grouptypename, ' ', a:subwinids)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewWinids(
   \    a:subwinids,
   \    len(g:wince_subwingrouptype[a:grouptypename].typenames)
   \)
 
    for i in range(len(a:subwinids))
        let typename = g:wince_subwingrouptype[a:grouptypename].typenames[i]

        let oldsubwinid = t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id
        let t:wince_subwin[a:subwinids[i]] = t:wince_subwin[oldsubwinid]

        call EchomLog('wince-model', 'debug', 'Moving subwin ', a:supwinid, ':', a:grouptypename, ':', typename, ' from ID ', oldsubwinid, ' to ', a:subwinids[i], ' in subwin list')
        call remove(t:wince_subwin, oldsubwinid)

        let t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[typename].id = a:subwinids[i]
    endfor

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelChangeSubwinDimensions(supwinid, grouptypename, typename, relnr, w, h)
    call EchomLog('wince-model', 'debug', 'WinceModelChangeSubwinDimensions ', a:supwinid, ':', a:grouptypename, ':', a:typename, ' [', a:relnr, ',', a:w, ',', a:h, ']')
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call s:ValidateNewSubwinDimensions(a:grouptypename, a:typename, a:relnr, a:w, a:h)

    let subwinid = t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let t:wince_subwin[subwinid].relnr = a:relnr
    let t:wince_subwin[subwinid].w = a:w
    let t:wince_subwin[subwinid].h = a:h

    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelChangeSubwinGroupDimensions(supwinid, grouptypename, dims)
    call EchomLog('wince-model', 'debug', 'WinceModelChangeSubwinGroupDimensions ', a:supwinid, ':', a:grouptypename, ' ', a:dims)
    let vdims = s:ValidateNewSubwinDimensionsList(a:grouptypename, a:dims)

    for typeidx in range(len(g:wince_subwingrouptype[a:grouptypename].typenames))
        let typename = g:wince_subwingrouptype[a:grouptypename].typenames[typeidx]
        call WinceModelChangeSubwinDimensions(
       \    a:supwinid,
       \    a:grouptypename,
       \    typename,
       \    vdims[typeidx].relnr,
       \    vdims[typeidx].w,
       \    vdims[typeidx].h
       \)
    endfor
endfunction

function! WinceModelAfterimageSubwin(supwinid, grouptypename, typename, aibufnum)
    call EchomLog('wince-model', 'info', 'WinceModelAfterimageSubwin ', a:supwinid, ':', a:grouptypename, ':', a:typename, ' ', a:aibufnum)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call WinceModelAssertSubwinIsNotAfterimaged(a:supwinid, a:grouptypename, a:typename)
    let idx = index(g:wince_subwingrouptype[a:grouptypename].typenames, a:typename)
    if !g:wince_subwingrouptype[a:grouptypename].afterimaging[idx]
        throw 'cannot afterimage subwin of non-afterimaging subwin type ' .
       \      a:grouptypename .
       \      ':' .
       \      a:typename
    endif
    if a:aibufnum < 0
        throw 'bad afterimage buffer number ' . a:aibufnum
    endif
    let subwinid = t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    call s:AssertSubwinidIsInSubwinList(subwinid)
    let t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].afterimaged = 1
    let t:wince_subwin[subwinid].aibuf = a:aibufnum
    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelDeafterimageSubwin(supwinid, grouptypename, typename)
    call EchomLog('wince-model', 'info', 'WinceModelDeafterimageSubwin ', a:supwinid, ':', a:grouptypename, ':', a:typename)
    call WinceModelAssertSubwinGroupIsNotHidden(a:supwinid, a:grouptypename)
    call WinceModelAssertSubwinIsAfterimaged(a:supwinid, a:grouptypename, a:typename)
    let subwinid = t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].id
    let t:wince_supwin[a:supwinid].subwin[a:grouptypename].subwin[a:typename].afterimaged = 0
    let t:wince_subwin[subwinid].aibuf = -1
    call s:AssertSubwinGroupIsConsistent(a:supwinid, a:grouptypename)
endfunction

function! WinceModelDeafterimageSubwinsByGroup(supwinid, grouptypename)
    call EchomLog('wince-model', 'info', 'WinceModelDeafterimageSubwinsByGroup ', a:supwinid, ':', a:grouptypename)
    if !WinceModelSubwinGroupHasAfterimagedSubwin(a:supwinid, a:grouptypename)
        return
    endif

    for typename in g:wince_subwingrouptype[a:grouptypename].typenames
        if WinceModelSubwinIsAfterimaged(a:supwinid, a:grouptypename, typename)
            call WinceModelDeafterimageSubwin(a:supwinid, a:grouptypename, typename)
        endif
    endfor
endfunction

function! WinceModelReplaceWinid(oldwinid, newwinid)
    call EchomLog('wince-model', 'info', 'WinceModelReplaceWinid ', a:oldwinid, a:newwinid)
    let info = WinceModelInfoById(a:oldwinid)
    call s:AssertWinDoesntExist(a:newwinid)

    if info.category ==# 'uberwin'
        let t:wince_uberwin[info.grouptype].uberwin[info.typename].id = a:newwinid

    elseif info.category ==# 'supwin'
        let t:wince_supwin[a:newwinid] = t:wince_supwin[a:oldwinid]
        unlet t:wince_supwin[a:oldwinid]
        for subwinid in keys(t:wince_subwin)
            if t:wince_subwin[subwinid].supwin ==# a:oldwinid
                let t:wince_subwin[subwinid].supwin = a:newwinid
            endif
        endfor

    elseif info.category ==# 'subwin'
        let t:wince_supwin[info.supwin].subwin[info.grouptype].subwin[info.typename].id = a:newwinid
        let t:wince_subwin[a:newwinid] = t:wince_subwin[a:oldwinid]
        unlet t:wince_subwin[a:oldwinid]

    else
        throw 'Window with changed winid is neither uberwin nor supwin nor subwin'
    endif

    if t:curwin.id ==# a:oldwinid
        let t:curwin.id = a:newwinid
    endif
    if t:prevwin.id ==# a:oldwinid
        let t:prevwin.id = a:newwinid
    endif
endfunction

" TODO? Some individual types may need an option for a non-default toClose
" callback so that the resolver doesn't have to stomp them with :q! when their groups
" become incomplete
" - So far that hasn't been needed
