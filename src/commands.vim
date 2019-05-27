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

   " Place a cursorflash sign
   execute "sign place " . line('.') . " line=" . line('.') .  " name=cursorflash buffer=" . bufnr("%")

   " Flash twice more
   for i in range(1, 2)
      " Delay so the cursorflash sign sticks around for a bit
      sleep 150m

      " Unplace the cursorflash sign
      execute "sign unplace " . line('.') . " buffer=" . bufnr("%")

      " Delay so the cursorflash sign sticks around for a bit
      sleep 150m

      " Place a cursorflash sign
      execute "sign place " . line('.') . " line=" . line('.') .  " name=cursorflash buffer=" . bufnr("%")
   endfor

   " Delay so the cursorflash sign sticks around for a bit
   sleep 150m

   " Unplace the cursorflash sign
   execute "sign unplace " . line('.') . " buffer=" . bufnr("%")
endfunction
command! -nargs=0 -complete=command Flash call FlashCursorLine("")
