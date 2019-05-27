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

" Automatically open the quickfix window after populating the quickfix list
autocmd QuickFixCmdPost [^Ll]* nested cwindow
" Automatically open the location window after populating the location list
autocmd QuickFixCmdPost [Ll]* nested lwindow

" Signs for colouring lines and highlight groups for each one
sign define jeremyred text=() texthl=SignJeremyRed linehl=SignJeremyRed
highlight SignJeremyRed ctermfg=Black ctermbg=Red
sign define jeremygreen text=() texthl=SignJeremyGreen linehl=SignJeremyGreen
highlight SignJeremyGreen ctermfg=Black ctermbg=Green
sign define jeremyyellow text=() texthl=SignJeremyYellow linehl=SignJeremyYellow
highlight SignJeremyYellow ctermfg=Black ctermbg=Yellow
sign define jeremyblue text=() texthl=SignJeremyBlue linehl=SignJeremyBlue
highlight SignJeremyBlue ctermfg=Black ctermbg=Blue
sign define jeremymagenta text=() texthl=SignJeremyMagenta linehl=SignJeremyMagenta
highlight SignJeremyMagenta ctermfg=Black ctermbg=Magenta
sign define jeremycyan text=() texthl=SignJeremyCyan linehl=SignJeremyCyan
highlight SignJeremyCyan ctermfg=Black ctermbg=Cyan
sign define jeremywhite text=() texthl=SignJeremyWhite linehl=SignJeremyWhite
highlight SignJeremyWhite ctermfg=Black ctermbg=White

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
