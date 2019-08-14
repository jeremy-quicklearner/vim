" Custom commands

" https://vim.fandom.com/wiki/Windo_and_restore_current_window
" Just like windo, but restore the current window when done.
function! WinDo(command)
    let currwin=winnr()
    execute 'windo ' . a:command
    execute currwin . 'wincmd w'
endfunction
command! -nargs=+ -complete=command Windo call WinDo(<q-args>)

" Just like WinDo, but disable all autocommands for super fast
" processing.
command! -nargs=+ -complete=command Windofast noautocmd call WinDo(<q-args>)

" Just like bufdo, but restore the current buffer when done.
function! BufDo(command)
    let currBuff=bufnr("%")
    execute 'bufdo ' . a:command
    execute 'buffer ' . currBuff
endfunction
command! -nargs=+ -complete=command Bufdo call BufDo(<q-args>)

" Flash the cursor line
function! FlashCursorLine(command)

    " Get a list of the signs in the current buffer
    let signs = execute("sign place buffer=" . bufnr('%'))

    " If there are no signs already, stop the signcolumn from appearing
    if len(split(signs)) < 4
        setlocal signcolumn=no
    endif

    " If the current line is folded, flash multiple lines
    if foldclosed(line('.')) >= 0
        let lines = [line('.') - 1, line('.'), line('.')+1]
    else
        let lines = [line('.')]
    endif

    " We will use the current line number as our sign ID. If it is taken,
    " remember what sign it is
    let unplaceCmds=['', '', '']
    for idx in range(len(lines))
        let unplaceCmds[idx] = "sign unplace " . lines[idx] . " buffer=" . bufnr("%")
        for signline in split(signs, '\n')
            if signline =~# '^\s*line=\d*\s*id=' . lines[idx] . '\s*name=.*$'
                let oldSign = split(split(signline)[2], '=')[1]
                let unplaceCmds[idx] = "sign place " . lines[idx] . " line=" . lines[idx] . " name=" . oldSign . " buffer=" . bufnr('%')
            endif
        endfor
    endfor

    " Place a cursorflash sign
    for idx in range(len(lines))
        execute "sign place " . lines[idx] . " line=" . lines[idx] . " name=cursorflash buffer=" . bufnr("%")
    endfor
    redraw

    " Flash twice more
    for i in range(1, 2)
        " Delay so the cursorflash sign sticks around for a bit
        sleep 150m

        " Unplace the cursorflash sign
        for idx in range(len(lines))
            execute unplaceCmds[idx]
        endfor
        redraw

        " Delay so the cursorflash sign sticks around for a bit
        sleep 150m

        " Place a cursorflash sign
        for idx in range(len(lines))
            execute "sign place " . lines[idx] . " line=" . lines[idx] .  " name=cursorflash buffer=" . bufnr("%")
        endfor
        redraw
    endfor

    " Delay so the cursorflash sign sticks around for a bit
    sleep 150m

    " Unplace the cursorflash sign
    for idx in range(len(lines))
        execute unplaceCmds[idx]
    endfor
    redraw

    " If we stopped the signcolumn from appearing, stop... stopping it.
    if len(split(execute("sign place buffer=" . bufnr('%')))) < 4
        setlocal signcolumn=auto
    endif
endfunction
command! -nargs=0 -complete=command Flash call FlashCursorLine("")

let s:refLocIsRunning = 0
" Close all location windows that aren't in focus. Open the location window
" for the current window
function! RefreshLocationLists(command)
    " This function will be called from a nested autocmd. Guard against
    " recursion.
    if s:refLocIsRunning
        return
    endif
    let s:refLocIsRunning = 1
    " By default, no window is immune
    let immuneWinid = -1

    " If the current window isn't a location window but has a location window open,
    " that location window is immune
    if !getwininfo(win_getid())[0]['loclist'] && get(getloclist(0, {'winid':0}), 'winid', 0)
        let immuneWinid = getloclist(0, {'winid':0})['winid']
    endif

    " If the current window is a location window with a parent window open
    " it's immune
    if getwininfo(win_getid())[0]['loclist']
        let currentWinid = win_getid()
        for winnum in range(1, winnr('$'))
            if winnum != winnr() && get(getloclist(winnum, {'winid':0}), 'winid', 0) == currentWinid
                let immuneWinid = currentWinid
            endif
        endfor
    endif

    " Get a list of all location windows' winids, except the immune one
    let locWinids = []
    for winnum in range(1, winnr('$'))
        let winid = win_getid(winnum)
        if getwininfo(winid)[0]['loclist'] && winid != immuneWinid
            call add(locWinids, winid)
        endif
    endfor

    " Close all those location windows
    for locWinid in locWinids
        execute win_id2win(locWinid) . 'wincmd q'
    endfor

    " If the current window isn't a location window but has a location list,
    " open its location window and then jump back
    if len(getloclist(0)) && &ft !=# 'qf'
        lopen
        wincmd p
    endif
    
    let s:refLocIsRunning = 0

endfunction
command! -nargs=0 -complete=command Refloc call RefreshLocationLists("")
