" Common Utilities

" mapleaders are set here because they must be accessible from other scripts
let mapleader = "-"
let maplocalleader = "-"

" https://vim.fandom.com/wiki/Windo_and_restore_current_window
" Just like windo, but restore the current window when done.
function! WinDo(command, range)
    let currwin=winnr()
    execute a:range . 'windo ' . a:command
    execute currwin . 'wincmd w'
endfunction
command! -nargs=+ -complete=command Windo call WinDo(<q-args>, '')

" Just like WinDo, but disable all autocommands for super fast
" processing.
command! -nargs=+ -complete=command Windofast noautocmd call WinDo(<q-args>, '')

" Just like bufdo, but restore the current buffer when done.
function! BufDo(command, range)
    let currBuff=bufnr("%")
    execute a:range . 'bufdo ' . a:command
    execute 'buffer ' . currBuff
endfunction
command! -nargs=+ -complete=command Bufdo call BufDo(<q-args>)

" Make sure the current window has a variable defined in it
function! MaybeLet(name, default)
    if !exists('w:' . name)
        execute 'let w:' . name . ' = ' . default
    endif
endfunction

" Make sure every window has a variable defined for it
function! WinDoMaybeLet(name, default)
   for winnum in range(1, winnr('$'))
      if getwinvar(winnum, a:name, '$N$U$L$L$') ==# '$N$U$L$L$' 
         call setwinvar(winnum, a:name, a:default)
      endif
   endfor
endfunction

" CursorHold callback infrastructure

" Self-explanatory
function! EnsureCallbackListsExist()
    if !exists('t:cursorHoldCallbacks')
        let t:cursorHoldCallbacks = []
    endif
    if !exists('t:cursorHoldCascadingCallbacks')
        let t:cursorHoldCascadingCallbacks = []
    endif
endfunction

" Lambda for priority sorting
function! ComparePriorities(callback1, callback2)
    return a:callback1.priority - a:callback2.priority
endfunction

" Calling this function will cause callback(data) to be called on the
" next CursorHold event 
" callback must be a funcref, data can be anything. If cascade is truthy,
" autocommands can execute as side effects of the function.
" This effect cascades to side effects of those autocommands and so on.
" Callbacks with lower priority value go first
" The callback will only called once, on the next CursorHold event, unless
" permanent is true. In that case, the callback will be called for every
" CursorHold event from now on
function! RegisterCursorHoldCallback(callback, data, cascade, priority, permanent)
    "TODO: Validate params
    call EnsureCallbackListsExist()
    if a:cascade
        call add(t:cursorHoldCascadingCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent
       \})
        call sort(t:cursorHoldCascadingCallbacks, function('ComparePriorities'))
    else
        call add(t:cursorHoldCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent
       \})
        call sort(t:cursorHoldCascadingCallbacks, function('ComparePriorities'))
    endif
endfunction

" Run the registered callbacks
function! RunCursorHoldCallbacks()
    call EnsureCallbackListsExist()

    let newCallbacks = []
    for callback in t:cursorHoldCallbacks
        call callback.callback(callback.data)
        if callback.permanent
            call add(newCallbacks, callback)
        endif
    endfor

    let t:cursorHoldCallbacks = newCallbacks
endfunction

function! RunCursorHoldCascadingCallbacks()
    call EnsureCallbackListsExist()

    let newCallbacks = []
    for callback in t:cursorHoldCascadingCallbacks
        call callback.callback(callback.data)
        if callback.permanent
            call add(newCallbacks, callback)
        endif
    endfor

    let t:cursorHoldCascadingCallbacks = newCallbacks
endfunction

function! HandleTerminalEnter()
    " If we aren't in terminal mode, then the terminal was opened
    " elsewhere and the CursorHold event will still fire. Do nothing.
    if mode() !=# 't'
        return
    endif

    " Enter terminal-normal mode
    call feedkeys("\<c-\>\<c-n>")

    " Register a callback that goes back to terminal-job mode
    call RegisterCursorHoldCallback(function('feedkeys'), 'i', 0, 100, 0)
endfunction

augroup CursorHoldCallbacks
    autocmd!
    " The callbacks run on the CursorHold event
    autocmd CursorHold * nested call RunCursorHoldCascadingCallbacks()
    autocmd CursorHold * call RunCursorHoldCallbacks()

    " The CursorHold autocmd doesn't run in active terminal windows. When a
    " terminal is opened or entered go to terminal-normal mode so the event
    " will be called.
    " Then register a callback to go back to terminal-job mode. Use a very low
    " priority so all the other callbacks will have their chance to run before
    " going back to terminal-job mode.
    autocmd TerminalOpen,WinEnter * call HandleTerminalEnter()
augroup END
