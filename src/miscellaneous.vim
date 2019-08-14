" Miscellaneous configurations

" Allow backspacing everything from insert mode
set bs=indent,eol,start

" Auto-indent
set autoindent
set expandtab

" Tab-complete rules
set wildmode=longest,list,full
set wildmenu

" Keep 50 lines of ex command history
set history=50

" Refresh the location lists if we need to
function! MaybeRefloc()
    if t:refloc
        let t:refloc = 0
        Refloc
    endif
endfunction

augroup QuickFix
    " Automatically open the quickfix window after populating the quickfix list
    autocmd QuickFixCmdPost [^Ll]* nested cwindow
    " Automatically open the location window after populating the location list
    autocmd QuickFixCmdPost [Ll]* nested lwindow

    " Refresh the location lists after leaving a window
    autocmd VimEnter * let t:refloc = 1
    autocmd TabNew * let t:refloc = 1
    autocmd WinLeave * let t:refloc = 1
    autocmd CursorHold * nested call MaybeRefloc()

    " Always open the quickfix window across the whole width of the screen
    autocmd FileType qf
                \  if !getwininfo(win_getid())[0]['loclist']
                \|     wincmd J
                \| endif
augroup END

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

" A sign for marking the cursor position
sign define cursorflash text=-> texthl=Cursor linehl=Cursor

" The default updatetime of 4000 is too slow for me
set updatetime=100

" Don't show the welcome message
set shortmess=I

" There's a security vulnerability in the modelines feature, so disable it
set nomodeline
