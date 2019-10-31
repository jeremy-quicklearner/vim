" Sign manipulation

" Signs for colouring lines
sign define jeremyred     text=() texthl=SignJeremyRed     linehl=SignJeremyRed
sign define jeremygreen   text=() texthl=SignJeremyGreen   linehl=SignJeremyGreen
sign define jeremyyellow  text=() texthl=SignJeremyYellow  linehl=SignJeremyYellow
sign define jeremyblue    text=() texthl=SignJeremyBlue    linehl=SignJeremyBlue
sign define jeremymagenta text=() texthl=SignJeremyMagenta linehl=SignJeremyMagenta
sign define jeremycyan    text=() texthl=SignJeremyCyan    linehl=SignJeremyCyan
sign define jeremywhite   text=() texthl=SignJeremyWhite   linehl=SignJeremyWhite

" Place one of the above signs on a set of lines
function! PlaceJeremySigns(type, color, rawlines)
    if a:type == 'V' || a:type == "v" || a:type == ""
        let [lStart, cStart] = getpos("'<")[1:2]
        let [lEnd, cEnd] = getpos("'>")[1:2]
        let lines = range(lStart, lEnd)
    elseif a:type == 'explicit'
        let lines = a:rawlines
    else
        echom "PLACEJEREMYSIGNS BROKE"
    endif

    for line in lines
        execute "sign place " . line . " line=" . line .  " name=jeremy" . a:color . " buffer=" . bufnr("%")
    endfor
endfunction

" Unplace one of the above signs on a set of lines
function! UnplaceJeremySigns(type, rawlines)
    if a:type == 'V' || a:type == "v" || a:type == ""
        let [lStart, cStart] = getpos("'<")[1:2]
        let [lEnd, cEnd] = getpos("'>")[1:2]
        let lines = range(lStart, lEnd)
    elseif a:type == 'explicit'
        let lines = a:rawlines
    else
        echom "UNPLACEJEREMYSIGNS BROKE"
    endif

    " Get a list of the signs in the current buffer
    let signs = execute("sign place buffer=" . bufnr('%'))

    for line in lines
        " If there's a sign on the current line whose name starts with jeremy,
        " unplace it
        let unplaceCmd = "sign unplace " . line('.') . " buffer=" . bufnr("%")
        for signline in split(signs, '\n')
            if signline =~# '^\s*line=\d*\s*id=\S*\s*name=jeremy.*$'
                execute "sign unplace " . line . " buffer=" . bufnr("%")
            endif
        endfor
    endfor
endfunction

" Place signs on the current line
nnoremap <silent> <leader>sr :call PlaceJeremySigns("explicit", "red", [line(".")]) <cr>
nnoremap <silent> <leader>sg :call PlaceJeremySigns("explicit", "green", [line(".")]) <cr>
nnoremap <silent> <leader>sy :call PlaceJeremySigns("explicit", "yellow", [line(".")]) <cr>
nnoremap <silent> <leader>sb :call PlaceJeremySigns("explicit", "blue", [line(".")]) <cr>
nnoremap <silent> <leader>sm :call PlaceJeremySigns("explicit", "magenta", [line(".")]) <cr>
nnoremap <silent> <leader>sc :call PlaceJeremySigns("explicit", "cyan", [line(".")]) <cr>
nnoremap <silent> <leader>sw :call PlaceJeremySigns("explicit", "white", [line(".")]) <cr>

" Place signs on visually selected lines
vnoremap <silent> <leader>sr <esc>:call PlaceJeremySigns(visualmode(), "red", [])<cr>
vnoremap <silent> <leader>sg <esc>:call PlaceJeremySigns(visualmode(), "green", [])<cr>
vnoremap <silent> <leader>sy <esc>:call PlaceJeremySigns(visualmode(), "yellow", [])<cr>
vnoremap <silent> <leader>sb <esc>:call PlaceJeremySigns(visualmode(), "blue", [])<cr>
vnoremap <silent> <leader>sm <esc>:call PlaceJeremySigns(visualmode(), "magenta", [])<cr>
vnoremap <silent> <leader>sc <esc>:call PlaceJeremySigns(visualmode(), "cyan", [])<cr>
vnoremap <silent> <leader>sw <esc>:call PlaceJeremySigns(visualmode(), "white", [])<cr>

" Unplace signs on the current line
nnoremap <silent> <leader>S :call UnplaceJeremySigns("explicit", [line(".")]) <cr>

" Unplace signs on visually selected lines
vnoremap <silent> <leader>S <esc>:call UnplaceJeremySigns(visualmode(), [])<cr>

