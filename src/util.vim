" Common Utilities

" mapleaders are set here because they must be accessible from other scripts
let mapleader = "-"
let maplocalleader = "-"

" A simple logging system
" TODO: Move this to a plugin so that it's accessible to the window engine
" when it becomes a plugin too
" Critical: With its current configuration, Vim will never function correctly
"           ever again unless something is fixed
" Error:    Something is wrong and it's probably going to cause trouble until
"           Vim is restarted
" Warning:  Something is wrong but it probably won't cause any trouble
" Config:   Information about plugin configurations
" Info:     An alert about some change in Vim's state
" Debug:    Low-level information that isn't of interest to users
" Verbose:  Very low-level information that isn't of interest to anyone except
"           determined developers
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
if !exists('g:j_buflog')
    let g:j_buflog = bufnr('j_buflog', 1)
endif
if !exists('g:j_buflog_lines')
    let g:j_buflog_lines = 0
endif
function! s:MaybeStartBuflog()
    if !bufloaded(g:j_buflog)
        return
    endif
    call setbufvar(g:j_buflog, '&buftype', 'nofile')
    call setbufvar(g:j_buflog, '&swapfile', 0)
    call setbufvar(g:j_buflog, '&filetype', 'buflog')
    call setbufvar(g:j_buflog, '&bufhidden', 'hide')
    call setbufvar(g:j_buflog, '&buflisted', 1)
    try
        silent if !setbufline(g:j_buflog, 1, '[INF][buflog] Log start')
            let g:j_buflog_lines = 1
        endif
    catch /.*/
    endtry
endfunction
function! MaybeFlushBuflogQueue()
    if !g:j_buflog_lines
        call s:MaybeStartBuflog()
    endif
    if !g:j_buflog_lines
        return
    endif
    while !empty(g:j_buflog_queue)
        try
            silent if setbufline(g:j_buflog, g:j_buflog_lines + 1, g:j_buflog_queue[0])
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
    for linenr in range(g:j_buflog_lines + 1)
        silent call setbufline(g:j_buflog, linenr, '')
    endfor
    silent call setbufline(g:j_buflog, 1, '[INF][buflog] Log cleared')
    let g:j_buflog_lines = 1
endfunction
" TODO: Rename this function
function! EchomLog(facility, loglevel, ...)
    if index(g:j_loglevels, a:loglevel) <# 0
        throw 'Invalid log level ' . a:loglevel
    endif
    let currentbufloglevel = get(g:j_loglevel, a:facility, {'buf':'verbose'}).buf
    let currentmsgloglevel = get(g:j_loglevel, a:facility, {'msg':'verbose'}).msg
    let logstr = ''
    if index(g:j_loglevels, a:loglevel) <=# index(g:j_loglevels, currentbufloglevel)
        let logstr = '[' . g:j_loglevel_data[a:loglevel].prefix . '][' . a:facility . '] ' . join(a:000, '')
        call add(g:j_buflog_queue, logstr)
        call MaybeFlushBuflogQueue()
    endif
    if index(g:j_loglevels, a:loglevel) <=# index(g:j_loglevels, currentmsgloglevel)
        if empty(logstr)
            let logstr = '[' . g:j_loglevel_data[a:loglevel].prefix . '][' . a:facility . '] ' . join(a:000, '')
        endif
        execute 'echohl ' . g:j_loglevel_data[a:loglevel].hl
        echom logstr
        " TODO? go back to the previous echohl instead of None
        "       - Apparently there is no way to read the current echohl, so
        "         this is impossible
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
command! -nargs=+ -complete=command Bufdo call BufDo(<q-args>, '')

" Just like tabdo, but restore the current buffer when done.
function! TabDo(command, range)
    let curtabnr = tabpagenr()
    execute a:range . 'tabdo ' . a:command
    execute curtabnr . 'tabnext'
endfunction
command! -nargs=+ -complete=command Tabdo call TabDo(<q-args>, '')

" Make sure the current window has a variable defined in it
function! MaybeLet(name, default)
    if !exists('w:' . name)
        execute 'let w:' . name . ' = ' . default
    endif
endfunction

" Make sure every window has a variable defined for it
function! WinDoMaybeLet(name, default)
   for winnr in range(1, winnr('$'))
      if getwinvar(winnr, a:name, '$N$U$L$L$') ==# '$N$U$L$L$' 
         call setwinvar(winnr, a:name, a:default)
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
" TODO: Move this to a plugin so it can be used by the window engine when it
" becomes a plugin
call SetLogLevel('cursorhold-callback', 'config', 'warning')
let s:callbacksRunning = 0

" Self-explanatory
function! EnsureCallbackListsExist()
    if !exists('g:cursorHoldCallbacks')
        let g:cursorHoldCallbacks = []
    endif
    if !exists('t:cursorHoldCallbacks')
        let t:cursorHoldCallbacks = []
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
" Callbacks with a false inCmdWin flag will not run while the command-line
" window is open.
" If global is truthy, the callback will execute even if the user switches to
" another tab before the next CursorHold event. Otherwise, the callback will
" run on the next CursorHold event that triggers in the current tab
function! RegisterCursorHoldCallback(callback, data, cascade, priority, permanent, inCmdWin, global)
    if type(a:callback) != v:t_func
        throw 'CursorHold Callback ' . string(a:callback) . ' is not a function'
    endif
    if type(a:data) != v:t_list
        throw 'Data ' . string(a:data) . ' for CursorHold Callback ' . string(a:callback) . 'is not a list'
    endif
    if type(a:cascade) != v:t_number
        throw 'Cascade flag ' . string(a:cascade) . ' for CursorHold Callback ' . string(a:callback) . 'is not a number'
    endif
    if type(a:priority) != v:t_number
        throw 'Priority ' . string(a:priority) . ' for CursorHold Callback ' . string(a:callback) . 'is not a number'
    endif
    if type(a:permanent) != v:t_number
        throw 'Permanent flag ' . string(a:permanent) . ' for CursorHold Callback ' . string(a:callback) . 'is not a number'
    endif
    if type(a:inCmdWin) != v:t_number
        throw 'Even-in-command-window flag ' . string(a:inCmdWin) . ' for CursorHold Callback ' . string(a:callback) . 'is not a number'
    endif
    if type(a:global) != v:t_number
        throw 'Global flag ' . string(a:global) . ' for CursorHold Callback ' . string(a:callback) . 'is not a number'
    endif
    if s:callbacksRunning
       throw 'Cannot register a CursorHold callback as part of running a different CursorHold callback'
    endif
    if a:permanent && a:global
        call EchomLog('cursorhold-callback', 'config', 'Permanent Global CursorHold Callback: ', string(a:callback))
    else
        call EchomLog('cursorhold-callback', 'info', 'Register CursorHold Callback: ', string(a:callback))
    endif
    call EnsureCallbackListsExist()
    if a:global
        call add(g:cursorHoldCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent,
       \    'cascade': a:cascade,
       \    'inCmdWin': a:inCmdWin
       \})
    else
        call add(t:cursorHoldCallbacks, {
       \    'callback': a:callback,
       \    'data': a:data,
       \    'priority': a:priority,
       \    'permanent': a:permanent,
       \    'cascade': a:cascade,
       \    'inCmdWin': a:inCmdWin
       \})
    endif
endfunction

" Run the registered callbacks
function! RunCursorHoldCallbacks()
    call EchomLog('cursorhold-callback', 'info', 'Running CursorHold non-cascading callbacks')

    call EnsureCallbackListsExist()

    let callbacks = g:cursorHoldCallbacks + t:cursorHoldCallbacks

    call sort(callbacks, function('ComparePriorities'))
    for callback in callbacks
        if s:inCmdWin && !callback.inCmdWin
            continue
        endif
        call EchomLog('cursorhold-callback', 'info', 'Running CursorHold Callback ', string(callback.callback))
        if callback.cascade
            call call(callback.callback, callback.data)
        else
            noautocmd call call(callback.callback, callback.data)
        endif
    endfor

    let newCallbacks = []
    for callback in g:cursorHoldCallbacks
        if callback.permanent || (s:inCmdWin && !callback.inCmdWin)
            call add(newCallbacks, callback)
        endif
    endfor
    let g:cursorHoldCallbacks = newCallbacks

    let newCallbacks = []
    for callback in t:cursorHoldCallbacks
        if callback.permanent || (s:inCmdWin && !callback.inCmdWin)
            call add(newCallbacks, callback)
        endif
    endfor
    let t:cursorHoldCallbacks = newCallbacks
endfunction

function! HandleTerminalEnter()
    " If we aren't in terminal mode, then the terminal was opened
    " elsewhere and the CursorHold event will still fire. Do nothing.
    if mode() !=# 't'
        return
    endif

    call EchomLog('cursorhold-callback', 'debug', 'Terminal in terminal-job mode detected in current window. Force-running CursorHold Callbacks.')
    call RunCursorHoldCallbacks()
endfunction

augroup CursorHoldCallbacks
    autocmd!
    " Detect when the command window is open
    autocmd CmdWinEnter * let s:inCmdWin = 1
    autocmd CmdWinLeave,VimEnter * let s:inCmdWin = 0

    " The callbacks run on the CursorHold event
    autocmd CursorHold * nested call RunCursorHoldCallbacks()

    " The CursorHold autocmd doesn't run in active terminal windows, so
    " force-run them whenever the cursor enters a terminal window
    autocmd TerminalOpen,WinEnter * nested call HandleTerminalEnter()
augroup END

" Flush the buflog queue at the end of every CursorHold event
if !exists('g:j_buflog_chc')
    let g:j_buflog_chc = 1
    call RegisterCursorHoldCallback(function('MaybeFlushBuflogQueue'), [], 0, 1000, 1, 1, 1)
endif
