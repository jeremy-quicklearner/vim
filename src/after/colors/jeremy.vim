" My colour scheme

highlight clear
if exists("syntax_on")
    syntax reset
endif

set background=dark
let g:colors_name="jeremy"

" Editor stuff

" The tab line
highlight TabLine           ctermfg=Black   ctermbg=White   cterm=none
highlight TabLineFill       ctermfg=White   ctermbg=Black   cterm=none
highlight TabLineSel        ctermfg=Black   ctermbg=Green   cterm=none
highlight Title             ctermfg=White   ctermbg=Black   cterm=none

" Status line colour for windows
highlight StatusLine        ctermfg=White   ctermbg=Black   cterm=none
highlight StatusLineTerm    ctermfg=White   ctermbg=Black   cterm=none
highlight StatusLineNC      ctermfg=White   ctermbg=White   cterm=none
highlight StatusLineTermNC  ctermfg=White   ctermbg=Black   cterm=none
highlight VertSplit         ctermfg=Black   ctermbg=White   cterm=none

" Line numbers are green 
highlight LineNr            ctermfg=Green   ctermbg=Black   cterm=none
highlight CursorLineNr      ctermfg=Black   ctermbg=Green   cterm=none

" Cursor-related stuff is red so it stands out
highlight Cursor            ctermfg=Black   ctermbg=Red     cterm=none
highlight CursorColumn      ctermfg=Red     ctermbg=Red     cterm=none
highlight WildMenu          ctermfg=Black   ctermbg=Red     cterm=none
highlight Visual            ctermfg=Black   ctermbg=Red     cterm=none

" Except stuff that persists in inactive windows, which is yellow
highlight MatchParen        ctermfg=Black   ctermbg=Yellow  cterm=none

" I enable the cursorline in inactive windows. Not colouring it makes the
" screen less busy. The CursorLineNr is still highlighted, so you can tell at
" a glance where the CursorLine is.
highlight CursorLine        ctermfg=none    ctermbg=none    cterm=none

" Error-type stuff is red so it stands out
highlight ErrorMsg          ctermfg=Red     ctermbg=Black   cterm=none
highlight WarningMsg        ctermfg=Black   ctermbg=Red     cterm=none
highlight Question          ctermfg=Black   ctermbg=Red     cterm=none
highlight SpellBad          ctermfg=Red     ctermbg=Black   cterm=none
highlight SpellCap          ctermfg=Red     ctermbg=Black   cterm=none
highlight SpellLocal        ctermfg=Red     ctermbg=Black   cterm=none
highlight SpellRare         ctermfg=Red     ctermbg=Black   cterm=none

" Search-related stuff is yellow so it stands out, but not as much as the cursor
highlight IncSearch         ctermfg=Black   ctermbg=Yellow  cterm=none
highlight Search            ctermfg=Black   ctermbg=Yellow  cterm=none
highlight QuickFixLine      ctermfg=Yellow  ctermbg=Black   cterm=none

" Folding-related stuff is yellow so it stands out, but not as much as the cursor
highlight Folded            ctermfg=Yellow  ctermbg=Black   cterm=none
highlight FoldColumn        ctermfg=Yellow  ctermbg=Black   cterm=none

" Sign-related stuff is all case-by-case
highlight SignColumn        ctermfg=Red     ctermbg=Black   cterm=none
highlight Sign              ctermfg=Red     ctermbg=Red     cterm=none
highlight SignJeremyRed     ctermfg=Black   ctermbg=Red     cterm=none
highlight SignJeremyGreen   ctermfg=Black   ctermbg=Green   cterm=none
highlight SignJeremyYellow  ctermfg=Black   ctermbg=Yellow  cterm=none
highlight SignJeremyBlue    ctermfg=Black   ctermbg=Blue    cterm=none
highlight SignJeremyMagenta ctermfg=Black   ctermbg=Magenta cterm=none
highlight SignJeremyCyan    ctermfg=Black   ctermbg=Cyan    cterm=none
highlight SignJeremyWhite   ctermfg=Black   ctermbg=White   cterm=none

" The Pmenu (Autocompletion menu) is Cyan
highlight Pmenu             ctermfg=Black   ctermbg=Cyan    cterm=none
highlight PmenuSel          ctermfg=White   ctermbg=Black   cterm=none
highlight PmenuSbar         ctermfg=Red     ctermbg=Black   cterm=none
highlight PmenuThumb        ctermfg=Red     ctermbg=White   cterm=none

" Diff stuff - self-explanatory
highlight DiffAdd           ctermfg=Green   ctermbg=Black   cterm=none
highlight DiffChange        ctermfg=Yellow  ctermbg=Black   cterm=none
highlight DiffDelete        ctermfg=Red     ctermbg=Black   cterm=none
highlight DiffText          ctermfg=White   ctermbg=Black   cterm=none

highlight Directory         ctermfg=Blue    ctermbg=Black   cterm=none
highlight ModeMsg           ctermfg=White   ctermbg=Black   cterm=none
highlight MoreMsg           ctermfg=White   ctermbg=Black   cterm=none

" Other types of text
highlight NonText           ctermfg=Magenta ctermbg=Black   cterm=none
highlight Normal            ctermfg=White   ctermbg=Black   cterm=none

" Off-limits columns to the right are green
highlight ColorColumn       ctermfg=Black   ctermbg=Green   cterm=none

" I don't know what these are so they're red until I find them
highlight Conceal           ctermfg=Red     ctermbg=Red     cterm=none

" Syntax Highlighting

" Comments are green because green doesn't call out for attention
highlight Comment           ctermfg=Green   ctermbg=Black   cterm=none

" Errors and Todos are red because red calls out for attention
highlight Error             ctermfg=Black   ctermbg=Red     cterm=none
highlight Todo              ctermfg=Red     ctermbg=Black   cterm=none

" Anything to do with the preprocessor is blue
highlight Macro             ctermfg=Blue    ctermbg=Black   cterm=none
highlight PreCondit         ctermfg=Blue    ctermbg=Black   cterm=none
highlight PreProc           ctermfg=Blue    ctermbg=Black   cterm=none
highlight Define            ctermfg=Blue    ctermbg=Black   cterm=none

" Literals are blue
highlight Boolean           ctermfg=Blue    ctermbg=Black   cterm=none
highlight Character         ctermfg=Blue    ctermbg=Black   cterm=none
highlight Float             ctermfg=Blue    ctermbg=Black   cterm=none
highlight Number            ctermfg=Blue    ctermbg=Black   cterm=none
highlight String            ctermfg=Blue    ctermbg=Black   cterm=none
" But special characters in them aren't
highlight Special           ctermfg=Magenta ctermbg=Black   cterm=none
highlight SpecialChar       ctermfg=Magenta ctermbg=Black   cterm=none
highlight SpecialKey        ctermfg=Magenta ctermbg=Black   cterm=none

" Keywords from the language syntax are cyan
highlight Conditional       ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Constant          ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Exception         ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Include           ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Repeat            ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Statement         ctermfg=Cyan    ctermbg=Black   cterm=none
highlight StorageClass      ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Structure         ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Typedef           ctermfg=Cyan    ctermbg=Black   cterm=none
highlight Keyword           ctermfg=Cyan    ctermbg=Black   cterm=none

" Meaningful single characters are magenta
highlight Delimiter         ctermfg=Magenta ctermbg=Black   cterm=none
highlight Operator          ctermfg=Magenta ctermbg=Black   cterm=none

" Names are white
highlight Function          ctermfg=White   ctermbg=Black   cterm=none
highlight Identifier        ctermfg=White   ctermbg=Black   cterm=none
highlight Label             ctermfg=White   ctermbg=Black   cterm=none
highlight Type              ctermfg=White   ctermbg=Black   cterm=none

" For the status line
highlight User1             ctermbg=White   ctermfg=Black   cterm=none
highlight User2             ctermbg=Red     ctermfg=Black   cterm=none
highlight User3             ctermbg=Green   ctermfg=Black   cterm=none
highlight User4             ctermbg=Yellow  ctermfg=Black   cterm=none

highlight User5             ctermbg=Black   ctermfg=White   cterm=none
highlight User6             ctermbg=Black   ctermfg=Red     cterm=none
highlight User7             ctermbg=Black   ctermfg=Green   cterm=none
highlight User8             ctermbg=Black   ctermfg=Yellow  cterm=none

highlight User9             ctermbg=Red     ctermfg=Red     cterm=none

" Anything I haven't seen yet is red, so I can find it easily and recolour it
highlight Debug             ctermfg=Red     ctermbg=Red     cterm=none
highlight SpecialComment    ctermfg=Red     ctermbg=Red     cterm=none
highlight Tag               ctermfg=Red     ctermbg=Red     cterm=none
highlight Underlined        ctermfg=Red     ctermbg=Red     cterm=none
highlight Ignore            ctermfg=Red     ctermbg=Red     cterm=none
