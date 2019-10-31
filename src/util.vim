" Common Utilities

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

" CursorHold callback infrastructure
" Calling this function with (c, d) will cause c(d) to be called on the
" next CursorHold event 
" c must be a funcref, d can be anything
function! RegisterCursorHoldCallback(callback, data)
    "TODO: Validate params
    call add(t:cursorHoldCallbacks, {
   \    'callback': a:callback,
   \    'data': a:data,
   \})
endfunction

" Run the registered callbacks
function! RunCursorHoldCallbacks()
    for callback in t:cursorHoldCallbacks
        call callback.callback(callback.data)
    endfor
    let t:cursorHoldCallbacks = []
endfunction

augroup CursorHoldCallbacks
    autocmd!
    " Every tab gets its own set of callbacks
    autocmd VimEnter,TabNew * let t:cursorHoldCallbacks = []
    
    " The callbacks run on the CursorHold event
    autocmd CursorHold * call RunCursorHoldCallbacks()
augroup END
