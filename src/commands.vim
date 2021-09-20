" Custom commands

" Flash the cursor line
sign define cursorflash text=-> texthl=Cursor linehl=Cursor

function! FlashCursorLine(command)

    " Get a list of the signs in the current buffer
    let signs = execute("sign place buffer=" . bufnr('%'))

    " If there are no signs already, stop the signcolumn from appearing
    if len(split(signs)) < 4
        setlocal signcolumn=no
    endif

    " If the current line is folded, flash multiple lines
    if foldclosed(line('.')) >= 0
        let lines = []
        if line('.') !=# 1
            call add(lines, foldclosed(line('.')) - 1)
        endif
        call add(lines, line('.'))
        if line('.') !=# line('$')
            call add(lines, foldclosedend(line('.')) + 1)
        endif
    else
        let lines = [line('.')]
    endif

    " We will use the current line number as our sign ID. If it is taken,
    " remember what sign it is
    let unplaceCmds=['', '', '']
    for idx in range(len(lines))
        let unplaceCmds[idx] = "sign unplace " . lines[idx] .
                              \" buffer=" . bufnr("%")
        for signline in split(signs, '\n')
            if signline =~# '^\s*line=\d*\s*id=' . lines[idx] . '\s*name=.*$'
                let oldSign = split(split(signline)[2], '=')[1]
                let unplaceCmds[idx] = "sign place " . lines[idx] . 
                                      \" line=" . lines[idx] .
                                      \" name=" . oldSign .
                                      \" buffer=" . bufnr('%')
            endif
        endfor
    endfor

    " Place a cursorflash sign
    for idx in range(len(lines))
        execute "sign place " . lines[idx] .
               \" line=" . lines[idx] .
               \" name=cursorflash buffer=" . bufnr("%")
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
            execute "sign place " . lines[idx] .
                   \" line=" . lines[idx] .
                   \" name=cursorflash buffer=" . bufnr("%")
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
command! -nargs=0 Flash call FlashCursorLine("")
nnoremap <silent> <c-f> :Flash<cr>
vnoremap <silent> <c-f> <esc>:Flash<cr>gv
inoremap <silent> <c-f> <esc>:Flash<cr>a
if exists('tnoremap')
    tnoremap <silent> <c-f> <c-\><c-n>:Flash<cr>i
endif


" Show the block heirarchy surrounding the current line
function! EchomBlockTops(command)
    " Start at the current line
    let l = line('.')
    let blocklines = []

    " Go up until a non-whitespace line is found
    while l > 0 && match(getline(l), "^\s*$") !=# -1
        let l -= 1
    endwhile
    let startl = l

    " If we moved up, record the line we started at
    if l !=# line('.')
        call add(blocklines, [line('.'), getline(line('.'))])
    endif

    " Examine each line going up from the current line until we reach one with
    " 0 indent or the top of the file. If this is the least indented line so
    " far, record it and its line number
    let minindent = indent(l)
    call add(blocklines, [l, getline(l)])
    while l > 0 
        if match(getline(l), "^\s*$") !=# -1
            let l -= 1
            continue
        endif
        if indent(l) ==# 0
            break
        endif
        if indent(l) < indent(l + 1) && indent(l) < minindent
           call add(blocklines, [l, getline(l)])
           let minindent = indent(l)
        endif
        let l -= 1
    endwhile

    " If we recorded lines, also record the top line
    if l !=# startl
       call add(blocklines, [l, getline(l)])
    endif

    " Figure out the length of the highest line number we recorded
    let maxnumlen = 3
    if len(string(blocklines[0][0])) > maxnumlen
        let maxnumlen = len(string(blocklines[0][0]))
    endif

    " Print the recorded lines
    let llprev = [-1, 'NOT A REAL LINE']
    for ll in reverse(blocklines)
        " If this line isn't right under the last one we printed, print dots
        " to indicate the skip
        if llprev[0] >= 0 && llprev[0] < ll[0] - 1
            execute 'let toprint = printf("%' . string(maxnumlen) .
                   \'S|%' . string(indent(ll[0]) + 3) . 'S", "...", "...")'
            echom toprint
        endif

        " Print the line and its line number
        execute 'let toprint = printf("%' . maxnumlen . 'd|%s", ll[0], ll[1])'
        echom toprint
        let llprev = ll
    endfor
endfunction
command! -nargs=0 Tops call EchomBlockTops("")
nnoremap <silent> <leader>t :Tops<cr>
