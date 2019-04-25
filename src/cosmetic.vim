" Cosmetic adjustments

" For code, colour columns 80 and 81
" TODO: Clean this up
" TODO: Don't colour the columns in quickfix windows
augroup ColumnLimit
    autocmd!
    autocmd BufReadPost,BufNewFile,BufWinEnter *.vim,*.h,*.c,*.cpp,*.py,*.sh
        \ let &colorcolumn="81,82"
augroup END

" Setup the status line, parametrized by colour
function! SetStatusLine(c1,c2,c3,c4)
   " Always show the status line
   setlocal laststatus=2
   set statusline=""
   " Buffer type
   execute('setlocal statusline+=%' . a:c3 . '*\ %y')
   " Buffer state
   execute('setlocal statusline+=%' . a:c4 . '*%r')
   execute('setlocal statusline+=%' . a:c4 . '*%m')
   " Filename
   execute('setlocal statusline+=%' . a:c1 . '*\ %f\ ')
   " Argument status
   execute('setlocal statusline+=%' . a:c4 . '*%a%' . a:c1 . '*')
   " Long space
   setlocal statusline+=%=
   " Current line / Total lines (% of file)
   execute('setlocal statusline+=%' . a:c3 . '*\ %l')
   setlocal statusline+=/
   setlocal statusline+=%L
   setlocal statusline+=(
   setlocal statusline+=%p
   setlocal statusline+=%%)\ 
endfunction
function! SetStatusLineGeneral()
   if &buftype ==# 'terminal'
       call SetStatusLine(5,6,7,8)
   else
       call SetStatusLine(1,2,3,4)
   endif
endfunction

augroup StatusLine
   autocmd!
   " Use different colours for terminal windows
   autocmd BufWinEnter * call SetStatusLineGeneral()
augroup END

" Indicate the active window
augroup ActiveWindow
    autocmd!

    " Relative numbers
    autocmd BufWinEnter * set relativenumber
    autocmd WinEnter * set relativenumber
    autocmd WinLeave * set norelativenumber

    " No cursor line
    autocmd BufWinEnter * set nocursorline
    autocmd WinEnter * set nocursorline
    autocmd WinLeave * set cursorline
augroup END


" Line numbers
augroup LineNumbers
    autocmd!
    autocmd BufWinEnter * set number
    autocmd BufWinEnter * set numberwidth=4
augroup END

" Fold column
set foldcolumn=1

" Highlight search results everywhere
set hlsearch
set incsearch

" Use my colour scheme
colorscheme jeremy
