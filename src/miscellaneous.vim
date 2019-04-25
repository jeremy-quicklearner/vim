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
