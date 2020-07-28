" Cosmetic adjustments

" The active window is the only one with relative numbers and a CursorLine
function! IndicateActiveWindow()
    let winids = WinStateGetWinidsByCurrentTab()
    for winid in winids
        call setwinvar(winid, '&relativenumber', 0)

        let idxline = 0
        if !empty(ToIdentifyLoclist(winid))
            let idxline = get(getloclist(winid,{'idx':0}),'idx',-1)
        elseif !empty(ToIdentifyQuickfix(winid))
            let idxline = get(getqflist({'idx':0}),'idx',-1)
        endif

        if idxline
            let curwinid = win_getid()
            call WinStateMoveCursorToWinidSilently(winid)
            let locline = line('.')
            call WinStateMoveCursorToWinidSilently(curwinid)
            if idxline ==# locline
                call setwinvar(winid, '&cursorline', 0)
            else
                call setwinvar(winid, '&cursorline', 1)
            endif
        else
            call setwinvar(winid, '&cursorline', 1)
        endif
    endfor

    let winid = WinStateGetCursorWinId()
    call setwinvar(winid, '&relativenumber', 1)
    call setwinvar(winid, '&cursorline', 0)
endfunction
if !exists('g:j_activewin_chc')
    let g:j_activewin_chc = 1
    call RegisterCursorHoldCallback(function('IndicateActiveWindow'), [], 0, 90, 1, 1)
    call WinAddPostUserOperationCallback(function('IndicateActiveWindow'))
endif

" For code, colour columns
augroup ColumnLimit
    autocmd!
    execute "autocmd FileType " . g:jeremyColouredColumnFileTypes .
           \" setlocal colorcolumn=" . g:jeremyColouredColumns
augroup END

" Line numbers
augroup LineNumbers
    autocmd!
    autocmd BufWinEnter * set number
    autocmd BufWinEnter * set numberwidth=1
augroup END

" Show the sign column only if there are signs
set signcolumn=auto

" Highlight search results everywhere
set hlsearch
set incsearch

" Use my colour scheme
colorscheme jeremy
