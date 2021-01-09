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
nnoremap <silent> <c-h> :<c-u>execute wince_map#ProcessCounts(1) . 'WinceGoLeft'<cr>
nnoremap <silent> <c-j> :<c-u>execute wince_map#ProcessCounts(1) . 'WinceGoDown'<cr>
nnoremap <silent> <c-k> :<c-u>execute wince_map#ProcessCounts(1) . 'WinceGoUp'<cr>
nnoremap <silent> <c-l> :<c-u>execute wince_map#ProcessCounts(1) . 'WinceGoRight'<cr>

" Use Ctrl-W z to set dimensions both vertically and horizontally
function! WinZoom(count)
    call wince_user#ResizeCurrentSupwin(a:count, a:count, 0)
endfunction
nmap <silent> <c-w>z :<c-u>call WinZoom(wince_map#ProcessCounts(1))<cr>
vmap <silent> <c-w>z :<c-u>call WinZoom(wince_map#ProcessCounts(1))<cr>

" Wince matches Vim's default behaviour by treating z<cr> differently
" from <c-w>_, but I'd rather z<cr> act the same way as <c-w>_
nnoremap <silent> z<cr> :<c-u>execute wince_map#ProcessCounts(1) . 'WinceResizeHorizontal'<cr>
vnoremap <silent> z<cr> :<c-u>execute wince_map#ProcessCounts(1) . 'WinceResizeHorizontal'<cr>

" Jersuite log commands
nnoremap <leader>jl :<c-u>JerLog<cr>
nnoremap <leader>jc :<c-u>JerLogClear<cr>

" Peek at entries in quickfix and location lists
nnoremap <expr> <space> &buftype ==# 'quickfix' ? "zz\<cr>zz\<c-w>\<c-p>" : "\<space>"

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

