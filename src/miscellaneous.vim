" Miscellaneous configurations

" Allow backspacing everything from insert mode
set bs=indent,eol,start

" Tab-complete rules
set wildmode=longest,list,full
set wildmenu

" Keep 100 lines of ex command history
set history=50

" Allow closing follds that are just one line long
set foldminlines=0

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

augroup Misc
    autocmd!

    " If a session is loaded while the current window has a location list, that
    " location list will be added to every window from the session. So remove it.
    " TODO: Move this to some kind of session management plugin if I ever
    "       write one
    autocmd SessionLoadPost * call jer_util#WinDo('', 'lexpr []')
augroup END

