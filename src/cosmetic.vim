" Cosmetic adjustments
let s:Win = {}

" This mess controls indication of the active window and cursor line by only setting 
" relativenumber in the active window, and highlighting the cursor line in all
" windows. This is simple to do in Vim 8.2 and later, but more complicated
" in earlier versions because the cursorline option always highlights the text
" line. This messes up the highlighting for quickfix and loclist windows'
" selected items. This first version of the function, which runs in Vim <8.2,
" will enable cursorline everywhere except for loclist and quickfix windows
" where the cursor is on top of the list item that was last selected.
" Unfortunately this causes the line number not to be highlighted for such
" windows. Such is life in pre-8.2.
" Another unfortunate shortcoming in pre-8.2 is that highlighting the cursor
" line in inactive windows causes signs' highlighting to be blocked for those
" lines. I don't know any solution for this
if !exists('&cursorlineopt')
    function! IndicateActiveWindow(cmdwin)
        if empty(s:Win)
            return
        endif
        let winids = wince_state#GetWinidsByCurrentTab()
        for winid in winids
            " Every window gets relativenumber off. This will be undone later
            " for the active window
            call setwinvar(s:Win.id2win(winid), '&relativenumber', 0)

            " If there is a command window, then it must be the current one.
            " Treat it as such and don't try to check if it's a location or
            " quickfix window - those checks would break. And also return
            " false since this is a command window.
            if a:cmdwin
                call setwinvar(s:Win.id2win(winid), '&cursorline', 1)
                continue
            endif
    
            " If this is a location or quickfix window, find out which line is
            " selected
            let idxline = -1
            if !s:Win.legacy
                if !empty(wince_loclist#ToIdentify(winid))
                    let idxline = get(getloclist(s:Win.id2win(winid),{'idx':0}),'idx',-1)
                elseif !empty(wince_quickfix#ToIdentify(winid))
                    let idxline = get(getqflist({'idx':0}),'idx',-1)
                endif
            endif
    
            if idxline > -1
                let curwinid = s:Win.getid()
                call wince_state#MoveCursorToWinidSilently(winid)
                let locline = line('.')
                call wince_state#MoveCursorToWinidSilently(curwinid)
                " If this is a location or quickfix window and the cursor is
                " on top of the selected line, do not highlight
                if idxline ==# locline
                    call setwinvar(s:Win.id2win(winid), '&cursorline', 0)
                " Highlight if the cursor is not on top of the selected line
                else
                    call setwinvar(s:Win.id2win(winid), '&cursorline', 1)
                endif
            " Highlight if this is not a location or quickfix window
            else
                call setwinvar(s:Win.id2win(winid), '&cursorline', 1)
            endif
        endfor
    
        " The current window gets relativenumber on and cursorline off. In Vim
        " <8.2, relativenumber causes the line number to get highlighted
        let winid = wince_state#GetCursorWinId()
        call setwinvar(s:Win.id2win(winid), '&relativenumber', 1)
        call setwinvar(s:Win.id2win(winid), '&cursorline', 0)
    endfunction
else
    " This is the code for Vim >=8.2
    function! IndicateActiveWindow(cmdwin)
        let winids = wince_state#GetWinidsByCurrentTab()
        " Every window gets relativenumber off and cursorline on
        for winid in winids
            call setwinvar(s:Win.id2win(winid), '&relativenumber', 0)
            call setwinvar(s:Win.id2win(winid), '&cursorline', 1)
        endfor
    
        " Except the current window, which gets relativenumber on
        let winid = wince_state#GetCursorWinId()
        call setwinvar(s:Win.id2win(winid), '&relativenumber', 1)
    endfunction

    " cursorline only highlights the line number. This way, it won't conflict
    " with selected quickfix/location items or even signs.
    set cursorlineopt=number
endif
function! IndicateActiveWindowNoCmdWin()
    call IndicateActiveWindow(0)
endfunction

" Registering post-user-operation callbacks fails if wince isn't installed,
" which is the case while plugins are still installing. So register them in a
" CursorHold autocmd that subsequently uninstalls itself
function! s:TryUseDeps()
    if !exists('g:wince_version')
        return 0
    endif
    if !exists('g:jeremy_cosmetic_deps')
        let g:jeremy_cosmetic_deps = 1
        let s:Win = jer_win#WinFunctions()
        call jer_chc#Register(function('IndicateActiveWindow'), [0], 0, 90, 1, 0, 1)
        call wince_user#AddPostUserOperationCallback(function('IndicateActiveWindowNoCmdWin'))
    endif
    return 1
endfunction
if !s:TryUseDeps()
    augroup CosmeticDeps
        autocmd!
        autocmd CursorHold * if s:TryUseDeps()
       \                   |     augroup CosmeticDeps
       \                   |         autocmd!
       \                   |     augroup END
       \                   |     augroup! CosmeticDeps
       \                   | endif
    augroup END
endif

" Do one call here on startup so that we don't have to wait until the first
" CursorHold event
call IndicateActiveWindow(0)

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
    autocmd CmdWinEnter * call IndicateActiveWindow(1)
augroup END

" Show the sign column only if there are signs
set signcolumn=auto

" Highlight search results everywhere
set hlsearch
set incsearch

" Use my colour scheme
colorscheme jeremy
