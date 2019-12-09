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
nnoremap <c-e> 2<c-e>
nnoremap <c-y> 2<c-y>
vnoremap <c-e> 2<c-e>
vnoremap <c-y> 2<c-y>
inoremap <c-e> <esc>2<c-e>a
inoremap <c-y> <esc>2<c-y>a

" Editing and Sourcing .vimrc
nnoremap <leader>ve :vsplit $MYVIMRC<cr>
nnoremap <leader>vs :source $MYVIMRC<cr>

" Window maximizing (like in tmux)
nnoremap <silent> <c-w>z :let t:qfwinHidden=1<cr>:cclose<cr>:call CloseAllLocWins()<cr><c-w>\|<c-w>_
vnoremap <silent> <c-w>z :let t:qfwinHidden=1<cr>:cclose<cr>:call CloseAllLocWins()<cr><c-w>\|<c-w>_
tnoremap <silent> <c-w>z :let t:qfwinHidden=1<cr>:cclose<cr>:call CloseAllLocWins()<cr><c-w>\|<c-w>_

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

" Set the foldmethod to indent, then manual
nnoremap <silent> <leader>z :set foldmethod=indent<cr>:set foldmethod=manual<cr>

" Peek at entries in quickfix and location lists
nnoremap <expr> <space> &buftype ==# 'quickfix' ? "zz\<cr>zz\<c-w>\<c-p>" : "\<cr>"

" Colour and uncolour the column under the cursor
nnoremap <silent> <leader>c :execute("setlocal colorcolumn=" . &colorcolumn . "," . col("."))<cr>
nnoremap <silent> <leader>C :execute("set colorcolumn=" . substitute(&colorcolumn . " ", "," . col(".") . '\(\D\)', '\1', "g"))<cr>

" Switch line numbers on and off
nnoremap <silent> <leader>n :set number!<cr>:set relativenumber!<cr>
