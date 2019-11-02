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
function! VimVersionString()
    let rv = '%#TabLineFill#[Vim ' . v:version / 100 . '.' . v:version % 100 . ']'
    return [rv, len(rv) - 14]
endfunction

" If a register is populated, return its letter. Else an empty string
function! EmptyIfEmpty(letter)
    if len(getreg(a:letter))
        return a:letter
    else
        return ''
    endif
endfunction

" Tabs
function! TabString(tabnum, tabcols)
    " If there's no room for square brackets, use just one digit
    if a:tabcols < 3
        return tabnum % 10
    endif

    let buflist = tabpagebuflist(a:tabnum)
    let winnr = tabpagewinnr(a:tabnum)
    let bufname = bufname(buflist[winnr - 1])
    if len(bufname)
        let path = bufname
    else
        let path = '---'
    endif
    let numwins = tabpagewinnr(a:tabnum, '$')
    if numwins > 1
        let plusOthers = ' (+' . (tabpagewinnr(a:tabnum, '$') - 1) . ')'
    else
        let plusOthers = ''
    endif

    let rv = '[' . a:tabnum . '|' . path . plusOthers . ']'
    while len(rv) > a:tabcols
        let rv = rv[1:]
    endwhile

    return rv

endfunction
function! TabsString(cols)
    let rv = ''
    let tabcount = tabpagenr('$')
    let tabcols = a:cols / tabcount
    for i in range(tabcount)
        " select the highlighting
        if i + 1 == tabpagenr()
            let rv .= '%#TabLineSel#'
        else
            let rv .= '%#TabLine#'
        endif

        " set the tab page number (for mouse clicks)
        let rv .= '%' . (i + 1) . 'T'

        " the label is made by MyTabLabel()
        let rv .= '%{TabString(' . (i + 1) . ',' . tabcols . ')}'
    endfor

    " after the last tab fill with TabLineFill and reset tab page nr
    let rv .= '%#TabLine#%T'

    " right-align the label to close the current tab page
    let rv .= '%=%#TabLine#%999X'

    return rv
endfunction

" Get a list of registers in use as a tabline-friendly string
function! RegListString()
    let rv = '%5*[Reg '
    for i in ['a', 'b', 'c', 'd', 'e',
             \'f', 'g', 'h', 'i', 'j',
             \'k', 'l', 'm', 'n', 'o',
             \'p', 'q', 'r', 's', 't',
             \'u', 'v', 'w', 'x', 'y',
             \'z']
        let rv .= '%{EmptyIfEmpty("' . i . '")}'
    endfor
    let rv .= ']'
    return [rv, 32]
endfunction

" Get the quickfix window flag
function! QfWinFlag()
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
    " Compute each widget
    let vimVersionString = VimVersionString()
    let regListString = RegListString()
    let qfWinFlag = QfWinFlag()
    
    " Measure each widget's length and subtract from the available columns.
    " What's left is available to the tabs
    let colsForTabs = &columns
    let colsForTabs -= vimVersionString[1]
    let colsForTabs -= regListString[1]
    let colsForTabs -= qfWinFlag[1]
    let tabsString = TabsString(colsForTabs)

    " Construct the tabline using the widgets and tabs
    let tabline = ""
    let tabline .= vimVersionString[0]
    let tabline .= tabsString
    let tabline .= regListString[0]
    let tabline .= qfWinFlag[0]
    return tabline
endfunction

" Set the tabline
set tabline=%!GetTabLine()

"" Buffer type
"set tabline+=%3*\%y
"" Buffer state
"set tabline+=%4*%r
"set tabline+=%4*%m%<
"" Buffer number
"set tabline+=%1*[%n]
"" Filename
"set tabline+=%1*[%f]\ 
"" Argument status
"set tabline+=%4*%a%1*
"" Long space
"set tabline+=%=
"" Location window flag
"set tabline+=%2*%{LocWinFlag()}
"" [Column][Current line/Total lines][% of file]
"set tabline+=%3*[%c][%l/%L][%p%%]

" Always show the line
set showtabline=2
