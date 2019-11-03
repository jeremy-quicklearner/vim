" Tabline definition

" Convert a global variable to a string based on a map lookup
" If the variable doesn't exist, return dne
" If the value of the variable isn't in the map, return the value directly
function! GlobalVarAsFlag(name, dne, map)
    if !exists('g:' . a:name)
        return a:dne
    else
        let val = eval('g:' . a:name)
        return get(a:map, val, val)
    endif
endfunction

" Convert a tab-local variable to a string based on a map lookup
" If the variable doesn't exist, return dne
" If the value of the variable isn't in the map, return the value directly
function! TabVarAsFlag(name, dne, map)
    if !exists('t:' . a:name)
        return a:dne
    else
        let val = eval('t:' . a:name)
        return get(a:map, val, val)
    endif
endfunction

" Get the current Vim version as a tabline-friendly string
function! GetVimVersionString()
    let rv = '%#TabLineFill#[Vim ' . v:version / 100 . '.' . v:version % 100 . ']'
    return [rv, len(rv) - 14]
endfunction

" If a register is populated, return its letter. Else a hyphen
function! HyphenIfEmpty(letter)
    if len(getreg(a:letter))
        return a:letter
    else
        return '-'
    endif
endfunction

" Tabs

" This function produces a string for one tab
function! GetTabString(tabnum, tabcols)
    " Special case for when there isn't enough room for two characters
    if a:tabcols < 2
        return printf('%X', a:tabnum % 0xF)
    endif

    " Special case when there's no room for one character between square brackets
    if a:tabcols < 3
        return printf('%X', a:tabnum % 0xFF)
    endif

    " Get tab information
    let buflist = tabpagebuflist(a:tabnum)
    let winnr = tabpagewinnr(a:tabnum)

    " Name of file in active window of the tab
    let wininfo = getwininfo(win_getid(winnr, a:tabnum))

    " Quickfix and location lists are special cases
    if len(wininfo) && wininfo[0]['loclist']
        let bufname = '[Location List]'
    elseif len(wininfo) && wininfo[0]['quickfix']
        let bufname = '[Quickfix List]'

    " Otherwise use the file name. No absolute paths unless they're needed
    else
        let bufname = fnamemodify(bufname(buflist[winnr - 1]), ':~:.')
    endif

    " If there's no buffer name (like in a new buffer) use '---'
    if len(bufname)
        let path = bufname
    else
        let path = '---'
    endif

    " Number of windows in the tab. Shown as '(+X)' so subtract one
    let numwins = tabpagewinnr(a:tabnum, '$')
    if numwins > 1
        let plusOthers = ' (+' . (tabpagewinnr(a:tabnum, '$') - 1) . ')'
    else
        let plusOthers = ''
    endif

    " Start by showing all the information
    let rv = '[' . a:tabnum . '|' . path . plusOthers . ']'
    let lenrv = len(rv)

    " Try to make it fit by trucating directories in the path down to one
    " letter each
    while lenrv > a:tabcols
        if rv =~# '[^|\/]\{2,}/'
            let rv = substitute(rv, '\([^|\/]\)[^|\/]\+/', '\1/', '')
            let lenrv = len(rv)
        else
            break
        endif
    endwhile

    " Try to make it fit by truncating the path with '...', but not the
    " filename
    if lenrv > a:tabcols
        let rv = substitute(rv, '|.\{-2,}[^/]/', '|.../', '')
        let lenrv = len(rv)
    endif
    while lenrv > a:tabcols
        if rv =~# '/.*/'
            let rv = substitute(rv, '|\.\.\./[^\/]/', '|.../', '')
            let lenrv = len(rv)
        else
            break
        endif
    endwhile

    " Try to make it fit by showing only the filename
    if lenrv > a:tabcols
        let rv = substitute(rv, '\.\.\./', '', '')
        let lenrv = len(rv)
    endif

    " Try to make it fit by removing the window count
    if lenrv > a:tabcols
        let rv = substitute(rv, ' (+\d*)', '', '')
        let lenrv = len(rv)
    endif

    " Try to make it fit by truncating the file name with '...'
    if lenrv > a:tabcols
        let rv = substitute(rv, '[^|]\{4}\]', '...]', '')
        let lenrv = len(rv)
        while lenrv > a:tabcols
            if rv =~# '|[^|]\+\.\.\.\]'
                let rv = substitute(rv, '.\.\.\.', '...', '')
                let lenrv = len(rv)
            else
                break
            endif
        endwhile
    endif

    " Try just the tab number
    if lenrv > a:tabcols
        let rv = '[' . a:tabnum . ']'
        let lenrv = len(rv)
    endif

    " Try just the tab number in hex
    if lenrv > a:tabcols
        let rv = printf('[%X]', a:tabnum)
        let lenrv = len(rv)
    endif

    " Try displaying only trailing digits of the tab number
    let radix = printf('%X', a:tabnum)
    while lenrv > a:tabcols
        let radix = radix[1:]
        let rv = '[' . radix . ']'
        let lenrv = len(rv)
    endwhile

    " If the result is too short, pad it
    if lenrv < a:tabcols
        let rv = substitute(rv, '\]', repeat('-', (a:tabcols - lenrv)) . ']', '')
    endif

    " If just one digit in square brackets doesn't fit, the special cases at
    " the start will have caught it
    return rv
endfunction

" This function produces a string for all the tabs
function! GetTabsString(cols)
    let rv = ''

    " Each tab gets an equal number of columns to work with
    let tabcount = tabpagenr('$')
    if tabcount < 16
        let tabcols = (a:cols + 1) / tabcount
    else
        let tabcols = a:cols / tabcount
    endif

    " Start truncating at the start of the tabs
    let rv .= '%<'

    " Use the Tabline colour group
    let rv .= '%#TabLine#'

    " The tabs
    for i in range(tabcount)
        " At 16 tabs, the tabline exceeds 80 substitution items and a
        " different format must be used
        " See: :help E541
        if tabcount < 16
            " Select colour group for tab
            if i + 1 == tabpagenr()
                let rv .= '%#TabLineSel#'
            else
                let rv .= '%#TabLine#'
            endif

            " Call GetTabString() dynamically
            let rv .= '%{GetTabString(' . (i + 1) . ',' . (tabcols - 1) . ')}'

            " Include a black separator between tabs
            if i + 1 != tabcount
                let rv .= '%#Normal#|'
            endif
        else
            " For the substitution-item-saving case, only switch colours
            " before and after the current tab. This means no black
            " separators. No substitution items are needed to switch colours
            " to black and back between all the non-current tabs
            if i + 1 == tabpagenr()
                let rv .= '%#TabLineSel#'
            endif

            " Call GetTabString() statically
            let rv .= GetTabString(i + 1, tabcols)

            " See above
            if i + 1 == tabpagenr()
                let rv .= '%#TabLine#'
            endif
        endif

    endfor

    " The rest of the tabline is tabline-coloured
    let rv .= '%#TabLine#'

    " Everything after the tabs is right-aligned. Truncate again.
    let rv .= '%=%<'

    return rv
endfunction

" These next functions are for items on the tabline. Each returns a text and a
" length. The length will be subtracted from the available space for tabs.

" Get a list of registers in use as a tabline-friendly string
function! GetRegListString()
    let rv = '%5*[Reg '
    for i in ['A', 'B', 'C', 'D', 'E',
             \'F', 'G', 'H', 'I', 'J',
             \'K', 'L', 'M', 'N', 'O',
             \'P', 'Q', 'R', 'S', 'T',
             \'U', 'V', 'W', 'X', 'Y',
             \'X']
        " Call HyphenIfEmpty() dynamically so that the register list will
        " update without messy autocmds
        let rv .= '%{HyphenIfEmpty("' . i . '")}'
    endfor
    let rv .= ']'
    return [rv, 32]
endfunction

" Get the quickfix window flag
function! GetQfWinFlag()
    " If there is a quickfix list, the flag is visible
    if len(getqflist())
        " The flag is [Qfx] or [Hid] depending on whether the quickfix window
        " is hidden
        return ['%2*' . TabVarAsFlag('qfwinHidden', '', {0:'[Qfx]',1:'[Hid]'}), 5]
    else
        return ['', 0]
    endif
endfunction

" Construct the tabline
function! GetTabLine()
    " Compute everything except the tabs first
    let vimVersionString = GetVimVersionString()
    let regListString = GetRegListString()
    let qfWinFlag = GetQfWinFlag()

    " Measure each item's length and subtract from the available columns.
    " What's left is available to the tabs. The reason not to just call len()
    " on each one is that len() doesn't interpret the tabline's substitution
    " items
    let colsForTabs = &columns
    let colsForTabs -= vimVersionString[1]
    let colsForTabs -= regListString[1]
    let colsForTabs -= qfWinFlag[1]

    " Use the remaining space for tabs
    let tabsString = GetTabsString(colsForTabs)

    " Construct the tabline using all the items
    let tabline = ""
    let tabline .= vimVersionString[0]
    let tabline .= tabsString
    let tabline .= regListString[0]
    let tabline .= qfWinFlag[0]
    return tabline
endfunction

" Self-explanatory
set tabline=%!GetTabLine()

" Always show the line
set showtabline=2
