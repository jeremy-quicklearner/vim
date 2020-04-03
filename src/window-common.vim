" Window manipulation code common to resolve function and user operations
" See window.vim

" Returns a data structure that encodes information about the window that the
" cursor is in
function! WinCommonGetCursorWinInfo()
    return WinModelInfoById(WinStateGetCursorWinId())
endfunction

" Moves the cursor to a window remembered with WinCommonGetCursorWinInfo, if it still
" exists
function! WinCommonRestoreCursorWinInfo(info)
    let winid = WinModelIdByInfo(a:info)
    if winid > 0
        call WinStateMoveCursorToWinid(winid)
    endif
endfunction

" Closes and reopens all uberwins with priority higher than a given
function! WinCommonCloseAndReopenUberwinsWithHigherPriority(priority)
    let grouptypenames = WinModelUberwinGroupTypeNamesByMinPriority(a:priority)
    for grouptypename in grouptypenames
        call WinStateCloseUberwinsByGroupType(g:uberwingrouptype[grouptypename])
        let winids = WinStateOpenUberwinsByGroupType(
       \    g:uberwingrouptype[grouptypename]
       \)
        call WinModelChangeUberwinIds(grouptypename, winids)
    endfor
endfunction

" Closes and reopens all subwins with priority higher than a given
function! WinCommonCloseAndReopenSubwinsWithHigherPriority(supwinid, priority)
    let grouptypenames = WinModelSubwinGroupTypeNamesByMinPriority(a:supwinid, a:priority)
    for grouptypename in grouptypenames
        call WinStateCloseSubwinsByGroupType(a:supwinid, g:subwingrouptype[grouptypename])
        let winids = WinStateOpenSubwinsByGroupType(
       \    a:supwinid,
       \    g:subwingrouptype[grouptypename]
       \)
        call WinModelChangeSubwinIds(a:supwinid, grouptypename, winids)
    endfor
endfunction

" Run all the toIdentify callbacks against the current window until one of
" them succeeds. Return the model info obtained.
function! WinCommonIdentifyCurrentWindow(toIdentifyUberwins, toIdentifySubwins)
    for uberwingrouptypename in keys(a:toIdentifyUberwins)
        let uberwintypename = a:toIdentifyUberwins[uberwingrouptypename]()
        if !empty(uberwintypename)
            return {
           \    'category': 'uberwin',
           \    'grouptype': uberwingrouptypename,
           \    'typename': uberwintypename,
           \    'id': win_getid()
           \}
        endif
    endfor
    for subwingrouptypename in keys(a:toIdentifySubwins)
        let subwindict = a:toIdentifySubwins[subwingrouptypename]()
        if !empty(subwindict)
            return {
           \    'category': 'subwin',
           \    'supwin': subwindict.supwin,
           \    'grouptype': subwingrouptypename,
           \    'typename': subwindict.typename,
           \    'id': win_getid()
           \}
        endif
    endfor
    return {
   \    'category': 'supwin',
   \    'id': win_getid()
   \}
endfunction

" Convert a list of window info dicts (as returned by
" WinCommonIdentifyCurrentWindow) and group them by category, supwin id, group
" type, and type. Any incomplete groups are dropped.
function! WinCommonGroupInfo(wininfos)
    let uberwingroupinfo = {}
    let subwingroupinfo = {}
    let supwininfo = []
    " Group the window info
    for wininfo in a:wininfos
        if wininfo.category ==# 'uberwin'
            if !has_key(uberwingroupinfo, wininfo.grouptype)
                let uberwingroupinfo[wininfo.grouptype] = {}
            endif
            " TODO: Handle case where two uberwins of the same type are
            "       present?
            let uberwingroupinfo[wininfo.grouptype][wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'subwin'
            if !has_key(subwingroupinfo, wininfo.supwin)
                let subwingroupinfo[wininfo.supwin] = {}
            endif
            if !has_key(subwingroupinfo[wininfo.supwin], wininfo.grouptype)
                let subwingroupinfo[wininfo.supwin][wininfo.grouptype] = {}
            endif
            " TODO: Handle case where two subwins of the same type are present
            "       for the same supwin?
            let subwingroupinfo[wininfo.supwin]
                              \[wininfo.grouptype]
                              \[wininfo.typename] = wininfo.id
        elseif wininfo.category ==# 'supwin'
            call add(supwininfo, wininfo.id)
        endif
    endfor

    " Validate groups. Prune any incomplete groups. Convert typename-keyed
    " winid dicts to lists
    for grouptypename in keys(uberwingroupinfo)
        for typename in keys(uberwingroupinfo[grouptypename])
            call WinModelAssertUberwinTypeExists(grouptypename, typename)
        endfor
        let uberwingroupinfo[grouptypename].winids = []
        for typename in WinModelUberwinTypeNamesByGroupTypeName(grouptypename)
            if !has_key(uberwingroupinfo[grouptypename], typename)
                unlet uberwingroupinfo[grouptypename]
                break
            endif
            call add(uberwingroupinfo[grouptypename].winids,
                    \uberwingroupinfo[grouptypename][typename])
        endfor
    endfor
    for supwinid in keys(subwingroupinfo)
        for grouptypename in keys(subwingroupinfo[supwinid])
            for typename in keys(subwingroupinfo[supwinid][grouptypename])
                call WinModelAssertSubwinTypeExists(grouptypename, typename)
            endfor
            let subwingroupinfo[supwinid][grouptypename].winids = []
            for typename in WinModelSubwinTypeNamesByGroupTypeName(grouptypename)
                if !has_key(subwingroupinfo[supwinid][grouptypename], typename)
                    unlet subwingroupinfo[supwinid][grouptypename]
                    break
                endif
                call add(subwingroupinfo[supwinid][grouptypename].winids,
                        \subwingroupinfo[supwinid][grouptypename][typename])
            endfor
        endfor
    endfor
    return {'uberwin':uberwingroupinfo,'supwin':supwininfo,'subwin':subwingroupinfo}
endfunction

function! WinCommonGroupSubwinInfo(wininfo)
endfunction
