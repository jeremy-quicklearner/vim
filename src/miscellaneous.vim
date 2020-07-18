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

" Use a small ttimeoutlen to return to normal mode faster
" Keep timeoutlen at 1000 so that mappings still work when using escape
" sequences
set timeoutlen=1000 ttimeoutlen=10

" Don't show the welcome message
set shortmess=I

" There's a security vulnerability in the modelines feature, so disable it
set nomodeline
