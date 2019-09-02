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

" Flash the cursor line
nnoremap <silent> <c-f> :Flash<cr>
tnoremap <silent> <c-f> <c-\><c-n>:Flash<cr>i

" Switch line numbers on and off
nnoremap <silent> <leader>n :set number!<cr>:set relativenumber!<cr>

" Peek at entries in quickfix lists
nnoremap <expr> <space> &buftype ==# 'quickfix' ? "\<cr>\<c-w>\<c-p>" : "\<cr>"

" Clear the quickfix list
nnoremap <silent> <leader>cc :cexpr []<cr>

" Clear location lists
nnoremap <silent> <leader>lc :lexpr []<cr>

" Invoke the :Tops command
nnoremap <silent> <leader>t :Tops<cr>

" Place signs from src/miscellaneous on the current line
nnoremap <silent> <leader>sr :call PlaceJeremySigns("explicit", "red", [line(".")]) <cr>
nnoremap <silent> <leader>sg :call PlaceJeremySigns("explicit", "green", [line(".")]) <cr>
nnoremap <silent> <leader>sy :call PlaceJeremySigns("explicit", "yellow", [line(".")]) <cr>
nnoremap <silent> <leader>sb :call PlaceJeremySigns("explicit", "blue", [line(".")]) <cr>
nnoremap <silent> <leader>sm :call PlaceJeremySigns("explicit", "magenta", [line(".")]) <cr>
nnoremap <silent> <leader>sc :call PlaceJeremySigns("explicit", "cyan", [line(".")]) <cr>
nnoremap <silent> <leader>sw :call PlaceJeremySigns("explicit", "white", [line(".")]) <cr>

" Place signs from src/miscellaneous on visually selected lines
vnoremap <silent> <leader>sr <esc>:call PlaceJeremySigns(visualmode(), "red", [])<cr>
vnoremap <silent> <leader>sg <esc>:call PlaceJeremySigns(visualmode(), "green", [])<cr>
vnoremap <silent> <leader>sy <esc>:call PlaceJeremySigns(visualmode(), "yellow", [])<cr>
vnoremap <silent> <leader>sb <esc>:call PlaceJeremySigns(visualmode(), "blue", [])<cr>
vnoremap <silent> <leader>sm <esc>:call PlaceJeremySigns(visualmode(), "magenta", [])<cr>
vnoremap <silent> <leader>sc <esc>:call PlaceJeremySigns(visualmode(), "cyan", [])<cr>
vnoremap <silent> <leader>sw <esc>:call PlaceJeremySigns(visualmode(), "white", [])<cr>

" Unplace the signs from src/miscellaneous on the current line
nnoremap <silent> <leader>S :call UnplaceJeremySigns("explicit", [line(".")]) <cr>

" Place signs from src/miscellaneous on visually selected lines
vnoremap <silent> <leader>S <esc>:call UnplaceJeremySigns(visualmode(), [])<cr>

" Set the foldmethod to indent, then manual
nnoremap <silent> <leader>z :set foldmethod=indent<cr>:set foldmethod=manual<cr>

" Colour and uncolour the column under the cursor
nnoremap <silent> <leader>c :execute("setlocal colorcolumn=" . &colorcolumn . "," . col("."))<cr>
nnoremap <silent> <leader>C :execute("set colorcolumn=" . substitute(&colorcolumn . " ", "," . col(".") . '\(\D\)', '\1', "g"))<cr>
