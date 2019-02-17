" Cosmetic adjustments

" Rulers
set ruler

" Line numbers
set number
set numberwidth=4

" Use relative line numbers, but only in the active window
augroup ActiveWindow
    autocmd!
    autocmd WinEnter * set relativenumber
    autocmd WinLeave * set norelativenumber
augroup END

" Terminal colours
set t_Co=8
set t_Sb=[4%dm
set t_Sf=[3%dm

" Status line colour
highlight StatusLine ctermfg=blue
highlight StatusLineNC ctermfg=white
highlight StatusLineTerm ctermbg=blue ctermfg=black
highlight StatusLineTermNC ctermbg=white ctermfg=black

" For code, colour all columns after column 80
" TODO: Clean this up
highlight ColorColumn ctermbg=yellow
au BufReadPost,BufNewFile *.vim,*.h,*.c,*.cpp,*.py,*.sh let &colorcolumn=join(range(86,999),",")

" Highlight search results everywhere
set hlsearch
set incsearch

" Syntax highlighting
syntax enable

highlight ColorColumn ctermfg=White ctermbg=Black
highlight Conceal ctermfg=White ctermbg=Black
highlight Cursor ctermfg=White ctermbg=Black
highlight CursorIM ctermfg=White ctermbg=Black
highlight CursorColumn ctermfg=White ctermbg=Black
highlight CursorLine ctermfg=White ctermbg=Black
highlight Directory ctermfg=White ctermbg=Black
highlight DiffAdd ctermfg=White ctermbg=Black
highlight DiffChange ctermfg=White ctermbg=Black
highlight DiffDelete ctermfg=White ctermbg=Black
highlight DiffText ctermfg=White ctermbg=Black
highlight ErrorMsg ctermfg=White ctermbg=Black
highlight VertSplit ctermfg=White ctermbg=Black
highlight Folded ctermfg=White ctermbg=Black
highlight FoldColumn ctermfg=White ctermbg=Black
highlight SignColumn ctermfg=White ctermbg=Black
highlight IncSearch ctermfg=White ctermbg=Black
highlight LineNr ctermfg=White ctermbg=Black
highlight MatchParen ctermfg=White ctermbg=Black
highlight ModeMsg ctermfg=White ctermbg=Black
highlight MoreMsg ctermfg=White ctermbg=Black
highlight NonText ctermfg=White ctermbg=Black
highlight Normal ctermfg=White ctermbg=Black
highlight Pmenu ctermfg=White ctermbg=Black
highlight PmenuSel ctermfg=White ctermbg=Black
highlight PmenuSbar ctermfg=White ctermbg=Black
highlight PmenuThumb ctermfg=White ctermbg=Black
highlight Question ctermfg=White ctermbg=Black
highlight Search ctermfg=White ctermbg=Black
highlight SpecialKey ctermfg=White ctermbg=Black
highlight SpellBad ctermfg=White ctermbg=Black
highlight SpellCap ctermfg=White ctermbg=Black
highlight SpellLocal ctermfg=White ctermbg=Black
highlight SpellRare ctermfg=White ctermbg=Black
highlight StatusLine ctermfg=White ctermbg=Black
highlight StatusLineNC ctermfg=White ctermbg=Black
highlight TabLine ctermfg=White ctermbg=Black
highlight TabLineFill ctermfg=White ctermbg=Black
highlight TabLineSel ctermfg=White ctermbg=Black
highlight Title ctermfg=White ctermbg=Black
highlight Visual ctermfg=White ctermbg=Black
highlight VisualNOS ctermfg=White ctermbg=Black
highlight WarningMsg ctermfg=White ctermbg=Black
highlight WildMenu ctermfg=White ctermbg=Black

highlight Comment ctermfg=Green ctermbg=Black
highlight Constant ctermfg=White ctermbg=Black
highlight String ctermfg=White ctermbg=Black
highlight Character ctermfg=White ctermbg=Black
highlight Number ctermfg=White ctermbg=Black
highlight Boolean ctermfg=White ctermbg=Black
highlight Float ctermfg=White ctermbg=Black
highlight Identifier ctermfg=White ctermbg=Black
highlight Function ctermfg=White ctermbg=Black
highlight Statement ctermfg=White ctermbg=Black
highlight Conditional ctermfg=White ctermbg=Black
highlight Repeat ctermfg=White ctermbg=Black
highlight Label ctermfg=White ctermbg=Black
highlight Operator ctermfg=White ctermbg=Black
highlight Keyword ctermfg=White ctermbg=Black
highlight Exception ctermfg=White ctermbg=Black
highlight PreProc ctermfg=White ctermbg=Black
highlight Include ctermfg=White ctermbg=Black
highlight Define ctermfg=White ctermbg=Black
highlight Macro ctermfg=White ctermbg=Black
highlight PreCondit ctermfg=White ctermbg=Black
highlight Type ctermfg=White ctermbg=Black
highlight StorageClass ctermfg=White ctermbg=Black
highlight Structure ctermfg=White ctermbg=Black
highlight Typedef ctermfg=White ctermbg=Black
highlight Special ctermfg=White ctermbg=Black
highlight SpecialChar ctermfg=White ctermbg=Black
highlight Tag ctermfg=White ctermbg=Black
highlight Delimiter ctermfg=White ctermbg=Black
highlight SpecialComment ctermfg=White ctermbg=Black
highlight Debug ctermfg=White ctermbg=Black
highlight Underlined ctermfg=White ctermbg=Black
highlight Ignore ctermfg=White ctermbg=Black
highlight Error ctermfg=White ctermbg=Black
highlight Todo ctermfg=White ctermbg=Black
