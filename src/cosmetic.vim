" Cosmetic adjustments

" This mess controls indication of the active window and cursor line by only
" setting relativenumber in the active window, and highlighting the cursor line
" in all windows. This is simple to do in Vim 8.2 and later, but more
" complicated in earlier versions because the cursorline option always
" highlights the text line. This messes up the highlighting for quickfix and
" loclist windows'selected items. This first version of the function, which
" runs in Vim <8.2, will enable cursorline everywhere except for loclist and
" quickfix windows where the cursor is on top of the list item that was last
" selected. Unfortunately this causes the line number not to be highlighted for
" such windows. Such is life in pre-8.2.
" Another unfortunate shortcoming in pre-8.2 is that highlighting the cursor
" line in inactive windows causes signs' highlighting to be blocked for those
" lines. I don't know any solution for this
if !exists('&cursorlineopt')
    function! IndicateActiveWindow(cmdwin)
        for winnr in range(1, winnr('$'))
            " Every window gets relativenumber off. This will be undone later
            " for the active window
            call setwinvar(winnr, '&relativenumber', 0)

            " If there is a command window, then it must be the current one
            " and we can't leave it. So skip the quickfix/loclist check below.
            if a:cmdwin
                continue
            endif
    
            " If this is a location or quickfix window, find out which line is
            " selected
            let idxline = 0
            if getwinvar(winnr, '&l:filetype') ==# 'qf'
                let idxline = get(getloclist(winnr,{'idx':0}),'idx',0)
                if idxline ==# 0
                    let idxline = get(getqflist({'idx':0}),'idx',0)
                endif
            endif
    
            if idxline ># 0
                let curwinnr = winnr()
                silent noautocmd execute winnr . 'wincmd w'
                let locline = line('.')
                silent noautocmd execute curwinnr . 'wincmd w'
                " If this is a location or quickfix window and the cursor is
                " on top of the selected line, do not highlight
                if idxline ==# locline
                    call setwinvar(winnr, '&cursorline', 0)
                " Highlight if the cursor is not on top of the selected line
                else
                    call setwinvar(winnr, '&cursorline', 1)
                endif
            " Highlight if this is not a location or quickfix window
            else
                call setwinvar(winnr, '&cursorline', 1)
            endif
        endfor
    
        " The current window gets relativenumber on and cursorline off. In Vim
        " <8.2, relativenumber causes the line number to get highlighted
        let winnr = winnr()
        call setwinvar(winnr, '&relativenumber', 1)
        call setwinvar(winnr, '&cursorline', 0)
    endfunction
else
    " This is the code for Vim >=8.2
    function! IndicateActiveWindow(cmdwin)
        " Every window gets relativenumber off and cursorline on
        for winnr in range(1, winnr('$'))
            call setwinvar(winnr, '&relativenumber', 0)
            call setwinvar(winnr, '&cursorline', 1)
        endfor
    
        " Except the current window, which gets relativenumber on
        call setwinvar(winnr(), '&relativenumber', 1)
    endfunction

    " cursorline only highlights the line number. This way, it won't conflict
    " with selected quickfix/location items or even signs.
    set cursorlineopt=number
endif
function! IndicateActiveWindowNoCmdWin()
    call IndicateActiveWindow(0)
endfunction

" Registering post-user-operation callbacks fails if jersuite-core isn't
" installed, which is the case while plugins are still installing. So register
" them in a Post-Event autocmd that subsequently uninstalls itself
function! s:TryUseDeps()
    if !exists('g:jersuite_core_version')
        return 0
    endif
    if !exists('g:jeremy_cosmetic_deps')
        let g:jeremy_cosmetic_deps = 1
        call jer_pec#Register(function('IndicateActiveWindow'), [0], 0, 90, 1, 0, 1)
        call wince_user#AddPostUserOperationCallback(function('IndicateActiveWindowNoCmdWin'))
    endif
    return 1
endfunction
function! RemoveCosDepGroup()
    if s:TryUseDeps()
        augroup CosmeticDeps
            autocmd!
        augroup END
        if has('patch-7.4.2300')
            augroup! CosmeticDeps
        endif
    endif
endfunction
if !s:TryUseDeps()
    augroup CosmeticDeps
        autocmd!
        if exists('##SafeStateAgain') && exists('*state') &&
       \   !g:jersuite_forcecursorholdforpostevent
            autocmd SafeState * call RemoveCosDepGroup()
        else
            autocmd CursorHold * call RemoveCosDepGroup()
        endif
    augroup END
endif
call IndicateActiveWindowNoCmdWin()

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
if exists('+signcolumn')
    set signcolumn=auto
endif

" Highlight search results everywhere
set hlsearch
set incsearch

" Use my colour scheme
colorscheme jeremy
