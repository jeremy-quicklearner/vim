" mappings

" Biting the bullet
inoremap <left> <nop>
inoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>
noremap <up> <nop>
noremap <down> <nop>

" Faster scrolling
vnoremap <c-e> 2<c-e>
vnoremap <c-y> 2<c-y>
nnoremap <c-e> 2<c-e>
nnoremap <c-y> 2<c-y>

" Editing and Sourcing .vimrc
nnoremap <leader>ve :vsplit $MYVIMRC<cr>
nnoremap <leader>vs :source $MYVIMRC<cr>

" Window maximizing (like in tmux)
nnoremap <c-w>z <c-w>_<c-w>\|
vnoremap <c-w>z <c-w>_<c-w>\|
tnoremap <c-w>z <c-w>_<c-w>\|

" Window navigation with Ctrl
nnoremap <c-h> <c-w>h
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-l> <c-w>l

" Window resizing
nnoremap <leader>= <c-w>+
vnoremap <leader>= <c-w>+

nnoremap <leader>- <c-w>-
vnoremap <leader>- <c-w>-

nnoremap <leader>o <c-w>>
vnoremap <leader>o <c-w>>

nnoremap <leader>p <c-w><
vnoremap <leader>p <c-w><

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

" Switch line numbers on and off
nnoremap <silent> <leader>n :set number!<cr>:set relativenumber!<cr>

" Set the foldmethod to indent, then manual
nnoremap <silent> <leader>z :set foldmethod=indent<cr>:set foldmethod=manual<cr>

" Colour and uncolour the column under the cursor
nnoremap <silent> <leader>c :execute("setlocal colorcolumn=" . &colorcolumn . "," . col("."))<cr>
nnoremap <silent> <leader>C :execute("set colorcolumn=" . substitute(&colorcolumn . " ", "," . col(".") . '\(\D\)', '\1', "g"))<cr>
