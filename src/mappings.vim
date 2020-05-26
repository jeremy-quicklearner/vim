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
noremap <c-w><left> <nop>
noremap <c-w><down> <nop>
noremap <c-w><up> <nop>
noremap <c-w><right> <nop>

" Use Ctrl-h|j|k|l for window movement from normal mode
nnoremap <silent> <c-h> :<c-u>execute WinMappingProcessCounts(1) . 'WinGoLeft'<cr>
nnoremap <silent> <c-j> :<c-u>execute WinMappingProcessCounts(1) . 'WinGoDown'<cr>
nnoremap <silent> <c-k> :<c-u>execute WinMappingProcessCounts(1) . 'WinGoUp'<cr>
nnoremap <silent> <c-l> :<c-u>execute WinMappingProcessCounts(1) . 'WinGoRight'<cr>

" Use Ctrl-W z to set dimensions both vertically and horizontally
function! WinZoom(count)
    execute a:count . 'WinResizeHorizontal'
    execute a:count . 'WinResizeVertical'
endfunction
nmap <silent> <c-w>z :<c-u>call WinZoom(WinMappingProcessCounts(1))<cr>
vmap <silent> <c-w>z :<c-u>call WinZoom(WinMappingProcessCounts(1))<cr>


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

" Colour and uncolour the column under the cursor
nnoremap <silent> <leader>c :execute("setlocal colorcolumn=" . &colorcolumn . "," . col("."))<cr>
nnoremap <silent> <leader>C :execute("set colorcolumn=" . substitute(&colorcolumn . " ", "," . col(".") . '\(\D\)', '\1', "g"))<cr>

" Switch line numbers on and off
nnoremap <silent> <leader>n :set number!<cr>:set relativenumber!<cr>

