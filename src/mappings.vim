" mappings
let mapleader = "-"
let maplocalleader = "-"

" Biting the bullet
inoremap <left> <nop>
inoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>
noremap <up> <nop>
noremap <down> <nop>

" Editing and Sourcing .vimrc
nnoremap <leader>ve :vsplit $MYVIMRC<cr>
nnoremap <leader>vs :source $MYVIMRC<cr>

" Window maximizing (like in tmux)
nnoremap <c-w>z <c-w>_<c-w>\|
vnoremap <c-w>z <c-w>_<c-w>\|

nnoremap <leader>= <c-w>+
vnoremap <leader>= <c-w>+

nnoremap <leader>- <c-w>-
vnoremap <leader>- <c-w>-

" Source current file
nnoremap <leader>% :w<cr>:source %<cr>

" Surround words with things
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
nnoremap <leader>( viw<esc>a)<esc>bi(<esc>lel
nnoremap <leader>[ viw<esc>a]<esc>bi[<esc>lel
nnoremap <leader>{ viw<esc>a}<esc>bi{<esc>lel
nnoremap <leader>< viw<esc>a><esc>bi<<esc>lel

nnoremap <leader>) viw<esc>a(<esc>bi)<esc>lel
nnoremap <leader>] viw<esc>a[<esc>bi)<esc>lel
nnoremap <leader>} viw<esc>a{<esc>bi}<esc>lel
nnoremap <leader>> viw<esc>a<<esc>bi><esc>lel

" Surround visual selections with things
vnoremap <leader>' <esc>`>a'<esc>`<i'<esc>
vnoremap <leader>" <esc>`>a"<esc>`<i"<esc>
vnoremap <leader>( <esc>`>a)<esc>`<i(<esc>
vnoremap <leader>[ <esc>`>a]<esc>`<i[<esc>
vnoremap <leader>{ <esc>`>a}<esc>`<i{<esc>
vnoremap <leader>< <esc>`>a><esc>`<i<<esc>
vnoremap <leader><space> <esc>`>a<space><esc>`<i<space><esc>

vnoremap <leader>) <esc>`>a(<esc>`<i)<esc>
vnoremap <leader>] <esc>`>a[<esc>`<i]<esc>
vnoremap <leader>} <esc>`>a{<esc>`<i}<esc>
vnoremap <leader>> <esc>`>a<<esc>`<i><esc>

" Flash the cursor line
nnoremap <leader>f :Flash<cr>

" Switch line numbers on and off
nnoremap <leader>n :set number!<cr>:set relativenumber!<cr>

" Peek at entries in quickfix lists
nnoremap <expr> <space> &buftype ==# 'quickfix' ? "\<cr>\<c-w>\<c-p>" : "\<cr>"

" Peek at and jump to quickfix entries in new windows
nnoremap <expr> <leader><cr> &buftype==# 'quickfix' ? "\<c-w>\<cr>\<c-w>L" : "\<cr>"
nnoremap <expr> <leader><space> &buftype==# 'quickfix' ? "\<c-w>\<cr>\<c-w>L<c-w><c-p>" : "\<cr>"

" Place and unplace the 'jeremy' sign on the current line
nnoremap <leader>s :call sign_place(0, "", "jeremy", "%", {'priority':100,'lnum':'.'})<cr>
nnoremap <leader>S :sign unplace<cr>
