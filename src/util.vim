" Common Utilities

" mapleaders are set here because they must be accessible from other scripts
let mapleader = "-"
let maplocalleader = "-"

" A simple logging system
" TODO: Move this to a plugin so that it's accessible to the window engine
" when it becomes a plugin too
let g:j_loglevels = [
\   'critical',
\   'error',
\   'warning',
\   'config',
\   'info',
\   'debug',
\   'verbose'
\]
let g:j_loglevel_data = {
\   'critical':{'hl':'ErrorMsg',  'prefix':'CRT'},
\   'error':   {'hl':'ErrorMsg',  'prefix':'ERR'},
\   'warning': {'hl':'WarningMsg','prefix':'WRN'},
\   'config':  {'hl':'WarningMsg','prefix':'CNF'},
\   'info':    {'hl':'Normal',    'prefix':'INF'},
\   'debug':   {'hl':'Normal',    'prefix':'DBG'},
\   'verbose': {'hl':'Normal',    'prefix':'VRB'}
\}
if !exists('g:j_loglevel')
    let g:j_loglevel = {}
endif
if !exists('g:j_buflog_queue')
    let g:j_buflog_queue = []
endif
if !exists('g:j_buflog_lines')
    let g:j_buflog_lines = 0
endif
function! s:MaybeStartBuflog()
    let g:j_buflog = bufnr('j_buflog', 1)
    call setbufvar(g:j_buflog, '&buftype', 'nofile')
    call setbufvar(g:j_buflog, '&buflisted', 1)
    try
        if !setbufline(g:j_buflog, 1, '[INF][buflog] Log start')
            let g:j_buflog_lines = 1
        endif
    catch /.*/
    endtry
endfunction
function! s:MaybeFlushBuflogQueue()
    if !g:j_buflog_lines
        call s:MaybeStartBuflog()
    endif
    if !g:j_buflog_lines
        return
    endif
    while !empty(g:j_buflog_queue)
        try
            if setbufline(g:j_buflog, g:j_buflog_lines + 1, g:j_buflog_queue[0])
                break
            endif
        catch /.*/
            break
        endtry
        let g:j_buflog_lines += 1
        call remove(g:j_buflog_queue, 0)
    endwhile
endfunction

function! SetLogLevel(facility, bufloglevel, msgloglevel)
    if index(g:j_loglevels, a:bufloglevel) <# 0
        throw 'Invalid log level ' . a:bufloglevel
    endif
    if index(g:j_loglevels, a:msgloglevel) <# 0
        throw 'Invalid log level ' . a:msgloglevel
    endif
    let g:j_loglevel[a:facility] = {'buf':a:bufloglevel,'msg':a:msgloglevel}
    call add(g:j_buflog_queue, '[CNF][buflog] Loglevels for ' . a:facility . ' facility set to ' . a:bufloglevel . ' and ' . a:msgloglevel)
endfunction
function! ClearBufLog()
    if !g:j_buflog_lines
        return
    endif
    for linenr in range(g:j_buflog_lines)
        call setbufline(g:j_buflog, linenr, '')
    endfor
    call setbufline(g:j_buflog, 1, '[INF][buflog] Log cleared')
    let g:j_buflog_lines = 1
endfunction
function! EchomLog(facility, loglevel, msg)
    if index(g:j_loglevels, a:loglevel) <# 0
        throw 'Invalid log level ' . a:loglevel
    endif
    let currentbufloglevel = get(g:j_loglevel, a:facility, {'buf':'verbose'}).buf
    let currentmsgloglevel = get(g:j_loglevel, a:facility, {'msg':'verbose'}).msg
    let logstr = '[' . g:j_loglevel_data[a:loglevel].prefix . '][' . a:facility . '] ' . a:msg
    if index(g:j_loglevels, a:loglevel) <=# index(g:j_loglevels, currentbufloglevel)
        call add(g:j_buflog_queue, logstr)
        call s:MaybeFlushBuflogQueue()
    endif
    if index(g:j_loglevels, a:loglevel) <=# index(g:j_loglevels, currentmsgloglevel)
        execute 'echohl ' . g:j_loglevel_data[a:loglevel].hl
        echom logstr
        " TODO: go back to the previous echohl instead of None
        echohl None
    endif
endfunction

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

" Add escape characters to a string so that it doesn't trigger any
" evaluation when passed to the value of the statusline or tabline options
function! SanitizeForStatusLine(arg, str)
    let retstr = a:str

    let retstr = substitute(retstr, ' ', '\ ', 'g')
    let retstr = substitute(retstr, '-', '\-', 'g')
    let retstr = substitute(retstr, '%', '%%', 'g')

    return retstr
endfunction

" CursorHold callback infrastructure
let s:callbacksRunning = 0

" Self-explanatory
function! EnsureCallbackListsExist()
    if !exists('g:cursorHoldCallbacks')
        let g:cursorHoldCallbacks = []
    endif
    if !exists('g:cursorHoldCascadingCallbacks')
        let g:cursorHoldCascadingCallbacks = []
    endif
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
" If global is truthy, the callback will execute even if the user switches to
" another tab before the next CursorHold event. Otherwise, the callback will
" run on the next CursorHold event that triggers in the current tab
function! RegisterCursorHoldCallback(callback, data, cascade, priority, permanent, global)
    "TODO: Validate params
    if s:callbacksRunning
       throw 'Cannot register a CursorHold callback as part of running a different CursorHold callback'
    endif
    call EnsureCallbackListsExist()
    if a:cascade && a:global
        call add(g:cursorHoldCascadingCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent
       \})
    elseif !a:cascade && a:global
        call add(g:cursorHoldCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent
       \})
    elseif a:cascade && !a:global
        call add(t:cursorHoldCascadingCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent
       \})
    elseif !a:cascade && !a:global
        call add(t:cursorHoldCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent
       \})
    else
        throw "Control should never reach here"
    endif
endfunction

" Run the registered callbacks
function! RunCursorHoldCallbacks(cascading)
    call EnsureCallbackListsExist()

    if a:cascading
        let callbacks = g:cursorHoldCascadingCallbacks + t:cursorHoldCascadingCallbacks
    else
        let callbacks = g:cursorHoldCallbacks + t:cursorHoldCallbacks
    endif

    call sort(callbacks, function('ComparePriorities'))
    for callback in callbacks
        call callback.callback(callback.data)
    endfor

    if a:cascading
        let newCallbacks = []
        for callback in g:cursorHoldCascadingCallbacks
            if callback.permanent
                call add(newCallbacks, callback)
            endif
        endfor
        let g:cursorHoldCascadingCallbacks = newCallbacks

        let newCallbacks = []
        for callback in t:cursorHoldCascadingCallbacks
            if callback.permanent
                call add(newCallbacks, callback)
            endif
        endfor
        let t:cursorHoldCascadingCallbacks = newCallbacks
    else
        let newCallbacks = []
        for callback in g:cursorHoldCallbacks
            if callback.permanent
                call add(newCallbacks, callback)
            endif
        endfor
        let g:cursorHoldCallbacks = newCallbacks

        let newCallbacks = []
        for callback in t:cursorHoldCallbacks
            if callback.permanent
                call add(newCallbacks, callback)
            endif
        endfor
        let t:cursorHoldCallbacks = newCallbacks
    endif
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
    " TODO: Fix the bug where extra I's get inserted if the same shell is open
    " in two windows
    call RegisterCursorHoldCallback(function('feedkeys'), 'i', 0, 100, 0, 0)
endfunction

augroup CursorHoldCallbacks
    autocmd!
    " The callbacks run on the CursorHold event
    autocmd CursorHold * nested call RunCursorHoldCallbacks(1)
    autocmd CursorHold * call RunCursorHoldCallbacks(0)

    " The CursorHold autocmd doesn't run in active terminal windows. When a
    " terminal is opened or entered go to terminal-normal mode so the event
    " will be called.
    " Then register a callback to go back to terminal-job mode. Use a very low
    " priority so all the other callbacks will have their chance to run before
    " going back to terminal-job mode.
    autocmd TerminalOpen,WinEnter * call HandleTerminalEnter()
augroup END
