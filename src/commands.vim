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

   " Get a list of the signs in the current buffer
   let signs = execute("sign place buffer=" . bufnr('%'))

   " If there are no signs already, stop the signcolumn from appearing
   if len(split(signs)) < 4
      setlocal signcolumn=no
   endif

   " We will use the current line number as our sign ID. If it is taken,
   " remember what sign it is
   let unplaceCmd = "sign unplace " . line('.') . " buffer=" . bufnr("%")
   for signline in split(signs, '\n')
      if signline =~# '^\s*line=\d*\s*id=' . line('.') . '\s*name=.*$'
         let oldSign = split(split(signline)[2], '=')[1]
         let unplaceCmd = "sign place " . line('.') . " line=" . line('.') . " name=" . oldSign . " buffer=" . bufnr('%')
      endif
   endfor

   " Place a cursorflash sign
   execute "sign place " . line('.') . " line=" . line('.') . " name=cursorflash buffer=" . bufnr("%")
   redraw

   " Flash twice more
   for i in range(1, 2)
      " Delay so the cursorflash sign sticks around for a bit
      sleep 150m

      " Unplace the cursorflash sign
      execute unplaceCmd
      redraw

      " Delay so the cursorflash sign sticks around for a bit
      sleep 150m

      " Place a cursorflash sign
      execute "sign place " . line('.') . " line=" . line('.') .  " name=cursorflash buffer=" . bufnr("%")
      redraw
   endfor

   " Delay so the cursorflash sign sticks around for a bit
   sleep 150m

   " Unplace the cursorflash sign
   execute unplaceCmd
   redraw
 
   " If we stopped the signcolumn from appearing, stop... stopping it.
   if len(split(execute("sign place buffer=" . bufnr('%')))) < 4
      setlocal signcolumn=auto
   endif
endfunction
command! -nargs=0 -complete=command Flash call FlashCursorLine("")
