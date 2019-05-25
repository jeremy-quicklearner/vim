" Custom commands

" https://vim.fandom.com/wiki/Windo_and_restore_current_window
" Just like windo, but restore the current window when done.
function! WinDo(command)
   let currwin=winnr()
   execute 'windo ' . a:command
   execute currwin . 'wincmd w'
endfunction
command! -nargs=+ -complete=command Windo call WinDo(<q-args>)

" Just like WinDo, but disable all autocommands for super fast
" processing.
command! -nargs=+ -complete=command Windofast noautocmd call WinDo(<q-args>)

" Just like bufdo, but restore the current buffer when done.
function! BufDo(command)
   let currBuff=bufnr("%")
   execute 'bufdo ' . a:command
   execute 'buffer ' . currBuff
endfunction
command! -nargs=+ -complete=command Bufdo call BufDo(<q-args>)

" Flash the cursor line
function! FlashCursorLine(command)
   " Store the cursor line's colour
   let cursorLineColour = execute('highlight CursorLine')
   let clcCtermfg = matchstr(cursorLineColour, 'ctermfg=\zs\S*')
   let clcCtermbg = matchstr(cursorLineColour, 'ctermbg=\zs\S*')
 
   " Toggle the CursorLine in every window, so only the current one has it
   Windofast set cursorline!

   " Set the cursor line's colour to red
   highlight CursorLine ctermfg=Red ctermbg=Red cterm=none

   " Redraw so the new colour shows up
   redraw

   " Flash twice more
   for i in range(1, 2)
      " Delay so the new colour sticks around for a bit
      sleep 100m

      " Set the cursor line's colour to black
      highlight CursorLine ctermfg=none ctermbg=none cterm=none

      " Redraw so the new colour shows up
      redraw

      " Delay so the new colour sticks around for a bit
      sleep 100m

      " Set the cursor line's colour to red
      highlight CursorLine ctermfg=Red ctermbg=Red cterm=none

      " Redraw so the new colour shows up
      redraw

   endfor

   " Delay so the new colour sticks around for a bit
   sleep 100m

   " Restore the cursor line's colour
   call execute('highlight CursorLine' 
      \ . ' ctermfg=' . clcCtermfg
      \ . ' ctermbg=' . clcCtermbg)
 
   " Toggle the CursorLine in every window, so only the current one doesn't
   " have it
   Windofast set cursorline!
endfunction
command! -nargs=0 -complete=command Flash call FlashCursorLine("")