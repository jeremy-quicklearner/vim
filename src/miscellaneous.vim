" Miscellaneous configurations

" Allow backspacing everything from insert mode
set bs=indent,eol,start

" Tab-complete rules
set wildmode=longest,list,full
set wildmenu

" Keep 50 lines of ex command history
set history=50

" The default updatetime of 4000 is too slow for me. CursorHold callbacks need
" to happen quickly
set updatetime=100

" Don't show the welcome message
set shortmess=I

" There's a security vulnerability in the modelines feature, so disable it
set nomodeline
