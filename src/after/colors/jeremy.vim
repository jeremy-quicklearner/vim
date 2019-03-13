" My colour scheme

highlight clear
if exists("syntax_on")
    syntax reset
endif

set background=dark
let g:colors_name="jeremy"

" Editor stuff

" The tab line
highlight TabLine        ctermfg=Black     ctermbg=White
highlight TabLineFill    ctermfg=White     ctermbg=Black
highlight TabLineSel     ctermfg=Black     ctermbg=Green
highlight Title          ctermfg=White     ctermbg=Black

" Status line colour for windows - The active one is green and the others
" are white
highlight StatusLine       ctermfg=Green   ctermbg=Black
highlight StatusLineTerm   ctermfg=Black   ctermbg=Green
highlight StatusLineNC     ctermfg=White   ctermbg=Black
highlight StatusLineTermNC ctermfg=Black   ctermbg=White
highlight VertSplit        ctermfg=White   ctermbg=Black

" Line numbers are green but the cursor line number is red
highlight LineNr           ctermfg=Green   ctermbg=Black
highlight CursorLineNr     ctermfg=Black   ctermbg=Red

" Cursor-related stuff is red so it stands out
highlight Cursor           ctermfg=Red     ctermbg=Red
highlight CursorLine       ctermfg=Red     ctermbg=Black
highlight CursorColumn     ctermfg=Red     ctermbg=Red
highlight WildMenu         ctermfg=Black   ctermbg=Red
highlight MatchParen       ctermfg=Red     ctermbg=Black
highlight Visual           ctermfg=Red     ctermbg=Black

" Error-type stuff is red so it stands out
highlight ErrorMsg         ctermfg=Red     ctermbg=Black
highlight WarningMsg       ctermfg=Black   ctermbg=Red
highlight SpellBad         ctermfg=Red     ctermbg=Black
highlight SpellCap         ctermfg=Red     ctermbg=Black
highlight SpellLocal       ctermfg=Red     ctermbg=Black
highlight SpellRare        ctermfg=Red     ctermbg=Black

" Search-related stuff is yellow so it stands out, but not as much as the cursor
highlight IncSearch        ctermfg=Black   ctermbg=Yellow
highlight Search           ctermfg=Black   ctermbg=Yellow

" The Pmenu (Autocompletion menu) is Cyan
highlight Pmenu            ctermfg=Black   ctermbg=Cyan
highlight PmenuSel         ctermfg=White   ctermbg=Black
highlight PmenuSbar        ctermfg=Red     ctermbg=Black
highlight PmenuThumb       ctermfg=Red     ctermbg=White

" Diff stuff - self-explanatory
highlight DiffAdd          ctermfg=Green   ctermbg=Black
highlight DiffChange       ctermfg=Yellow  ctermbg=Black
highlight DiffDelete       ctermfg=Red     ctermbg=Black
highlight DiffText         ctermfg=White   ctermbg=Black

highlight Directory        ctermfg=Blue    ctermbg=Black
highlight ModeMsg          ctermfg=White   ctermbg=Black
highlight MoreMsg          ctermfg=White   ctermbg=Black

" Other types of text
highlight NonText          ctermfg=Magenta ctermbg=Black
highlight Normal           ctermfg=White   ctermbg=Black

" Off-limits columns to the right are green
highlight ColorColumn      ctermfg=White   ctermbg=Green

" I don't know what these are so they're red until I find them
highlight Conceal          ctermfg=Red     ctermbg=Red
highlight Folded           ctermfg=Red     ctermbg=Red
highlight FoldColumn       ctermfg=Red     ctermbg=Red
highlight SignColumn       ctermfg=Red     ctermbg=Red
highlight Question         ctermfg=Red     ctermbg=Red

" Syntax Highlighting

" Comments are green because green doesn't call out for attention
highlight Comment          ctermfg=Green   ctermbg=Black

" Errors and Todos are red because red calls out for attention
highlight Error            ctermfg=Black   ctermbg=Red
highlight Todo             ctermfg=Red     ctermbg=Black

" Anything to do with the preprocessor is blue
highlight Macro            ctermfg=Blue    ctermbg=Black
highlight PreCondit        ctermfg=Blue    ctermbg=Black
highlight PreProc          ctermfg=Blue    ctermbg=Black
highlight Define           ctermfg=Blue    ctermbg=Black

" Literals are blue
highlight Boolean          ctermfg=Blue    ctermbg=Black
highlight Character        ctermfg=Blue    ctermbg=Black
highlight Float            ctermfg=Blue    ctermbg=Black
highlight Number           ctermfg=Blue    ctermbg=Black
highlight String           ctermfg=Blue    ctermbg=Black
" But special characters in them aren't
highlight Special          ctermfg=Magenta ctermbg=Black
highlight SpecialChar      ctermfg=Magenta ctermbg=Black
highlight SpecialKey       ctermfg=Magenta ctermbg=Black

" Keywords from the language syntax are cyan
highlight Conditional      ctermfg=Cyan    ctermbg=Black
highlight Constant         ctermfg=Cyan    ctermbg=Black
highlight Exception        ctermfg=Cyan    ctermbg=Black
highlight Include          ctermfg=Cyan    ctermbg=Black
highlight Repeat           ctermfg=Cyan    ctermbg=Black
highlight Statement        ctermfg=Cyan    ctermbg=Black
highlight StorageClass     ctermfg=Cyan    ctermbg=Black
highlight Structure        ctermfg=Cyan    ctermbg=Black
highlight Typedef          ctermfg=Cyan    ctermbg=Black

" Meaningful single characters are magenta
highlight Delimiter        ctermfg=Magenta ctermbg=Black
highlight Operator         ctermfg=Magenta ctermbg=Black

" Names are white
highlight Function         ctermfg=White   ctermbg=Black
highlight Identifier       ctermfg=White   ctermbg=Black
highlight Label            ctermfg=White   ctermbg=Black
highlight Type             ctermfg=White   ctermbg=Black

" Anything I haven't seen yet is red, so I can find it easily and recolour it
highlight Debug            ctermfg=Red     ctermbg=Red
highlight Keyword          ctermfg=Red     ctermbg=Red
highlight SpecialComment   ctermfg=Red     ctermbg=Red
highlight Tag              ctermfg=Red     ctermbg=Red
highlight Underlined       ctermfg=Red     ctermbg=Red
highlight Ignore           ctermfg=Red     ctermbg=Red
