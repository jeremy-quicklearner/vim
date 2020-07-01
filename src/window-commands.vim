" Custom window-related commands
" See window.vim
" This file defines several custom commands that call user operations

" TODO: Test WinGoDown
" TODO: Test WinGoFirst
" TODO: Test WinGoLast
" TODO: Test WinGoLeft
" TODO: Test WinGoNext
" TODO: Test WinGoRight
" TODO: Test WinGoUp
" TODO: Test WinGotoPrevious
" TODO: Test WinIncreaseHeight
" TODO: Test WinIncreaseWidth
" TODO: Test WinMoveToBottomEdge
" TODO: Test WinMoveToLeftEdge
" TODO: Test WinMoveToNewTab
" TODO: Test WinMoveToRightEdge
" TODO: Test WinMoveToTopEdge
" TODO: Test WinResizeHorizontal
" TODO: Test WinResizeVertical
" TODO: Test WinReverseGoNext
" TODO: Test WinReverseRotate
" TODO: Test WinRotate

function! s:SanitizeRange(cmdname, range, count, defaultcount)
    call EchomLog('window-commands', 'debug', 'SanitizeRange ' . a:cmdname . ', [' . a:range . ',' . a:count . ',' . a:defaultcount . ']')
    if a:range ==# 0
        call EchomLog('window-commands', 'verbose', 'Using default count ' . a:defaultcount)
        return a:defaultcount
    endif

    if a:range ==# 1
        call EchomLog('window-commands', 'verbose', 'Using given count ' . a:count)
        return a:count
    endif
     
    if a:range ==# 2
        throw 'Range not allowed for ' . a:cmdname
    endif

    throw 'Invalid <range> ' . a:range
endfunction

function! WinCmdRunCmd(cmdname, wincmd, range, count,
                     \ defaultcount,
                     \ preservecursor,
                     \ ifuberwindonothing,
                     \ ifsubwingotosupwin,
                     \ dowithoutuberwins,
                     \ dowithoutsubwins)
    call EchomLog('window-commands', 'info', 'WinCmdRunCmd ' . a:cmdname . ', ' . a:wincmd . ', [' . a:range . ',' . a:count . ',' . a:defaultcount . ',' . a:preservecursor . ',' . a:ifuberwindonothing . ',' . a:ifsubwingotosupwin . ',' . a:dowithoutuberwins . ',' / a:dowithoutsubwins . ']')
    try
        let opcount = s:SanitizeRange(a:cmdname, a:range, a:count, a:defaultcount)
    catch /.*/
        call EchomLog('window-commands', 'error', v:exception)
        return
    endtry

    call WinDoCmdWithFlags(a:wincmd, opcount, 
                         \ a:preservecursor,
                         \ a:ifuberwindonothing,
                         \ a:ifsubwingotosupwin,
                         \ a:dowithoutuberwins,
                         \ a:dowithoutsubwins)
endfunction

function! WinCmdRunSpecialCmd(cmdname, range, count, handler)
    call EchomLog('window-commands', 'info', 'WinCmdRunSpecialCmd ' . a:cmdname . ', [' . a:range . ',' . a:count . '], ' . a:handler)
    try
        let opcount = s:SanitizeRange(a:cmdname, a:range, a:count, '')
        let Handler = function(a:handler)

        call Handler(opcount)
    catch /.*/
        call EchomLog('window-commands', 'warning', v:exception)
        return
    endtry
endfunction

function! WinCmdDefineCmd(cmdname, wincmd, defaultcount,
                        \ preservecursor,
                        \ ifuberwindonothing, ifsubwingotosupwin,
                        \ dowithoutuberwins, dowithoutsubwins)
    call EchomLog('window-commands', 'config', 'Command: ' . a:cmdname)
    execute 'command! -nargs=0 -range=0 -complete=command ' . a:cmdname .
   \        ' call WinCmdRunCmd(' .
   \        '"' . a:cmdname . '",' .
   \        '"' . a:wincmd . '",' .
   \        '<range>,<count>,' .
   \        '"' . a:defaultcount . '",' .
   \        a:preservecursor . ',' .
   \        a:ifuberwindonothing . ',' .
   \        a:ifsubwingotosupwin . ',' .
   \        a:dowithoutuberwins . ',' .
   \        a:dowithoutsubwins . ')'
endfunction

function! WinCmdDefineSpecialCmd(cmdname, handler)
    call EchomLog('window-commands', 'config', 'Special command: ' . a:cmdname)
    execute 'command! -nargs=0 -range=0 -complete=command ' . a:cmdname .
   \        ' call WinCmdRunSpecialCmd(' .
   \        '"' . a:cmdname . '",' .
   \        '<range>,<count>,' .
   \        '"' . a:handler . '")'
endfunction

" Exchanging supwins is special because if the operation is invoked from a
" subwin, the cursor should be restored to the corresponding subwin of the
" exchanged window
call WinCmdDefineSpecialCmd('WinExchange','WinExchange')

" Going to the previous window requires special accounting in the user
" operations because window engine code is always moving the cursor all over
" the place and Vim's internal 'previous window' means nothing to the user
call WinCmdDefineSpecialCmd('WinGotoPrevious','WinGotoPrevious')

" WinOnly is special because if it isn't, its counted version can land in a
" subwin and close all other windows (including the subwin's supwin) leaving
" the subwin dangling, which will cause the resolver to exit the tab
call WinCmdDefineSpecialCmd('WinOnly', 'WinOnly')

" Movement commands are special because if the starting point is an uberwin,
" using DoWithoutUberwins would change the starting point to be the first
" supwin. But DoWithoutUberwins would be necessary because we don't want to
" move to Uberwins. So use custom logic.
call WinCmdDefineSpecialCmd('WinGoLeft',  'WinGoLeft' )
call WinCmdDefineSpecialCmd('WinGoDown',  'WinGoDown' )
call WinCmdDefineSpecialCmd('WinGoUp',    'WinGoUp'   )
call WinCmdDefineSpecialCmd('WinGoRight', 'WinGoRight')

let s:allNonSpecialCmds = {
\   'WinDecreaseHeight':  '-',
\   'WinDecreaseWidth':   '<',
\   'WinEqualize':        '=',
\   'WinGoFirst':         't',
\   'WinGoLast':          'b',
\   'WinGoNext':          'w',
\   'WinIncreaseHeight':  '+',
\   'WinIncreaseWidth':   '>',
\   'WinMoveToBottomEdge':'J',
\   'WinMoveToLeftEdge':  'H',
\   'WinMoveToNewTab':    'T',
\   'WinMoveToRightEdge': 'L',
\   'WinMoveToTopEdge':   'K',
\   'WinResizeHorizontal':'_',
\   'WinResizeVertical':  '|',
\   'WinReverseGoNext':   'W',
\   'WinReverseRotate':   'R',
\   'WinRotate':          'r'
\} 
let s:cmdsWithPreserveCursorPos = [
\   'WinDecreaseHeight',
\   'WinDecreaseWidth',
\   'WinEqualize',
\   'WinIncreaseHeight',
\   'WinIncreaseWidth',
\   'WinMoveToBottomEdge',
\   'WinMoveToLeftEdge',
\   'WinMoveToRightEdge',
\   'WinMoveToTopEdge',
\   'WinResizeHorizontal',
\   'WinResizeVertical',
\   'WinReverseRotate',
\   'WinRotate'
\]
let s:cmdsWithUberwinNop = [
\   'WinDecreaseHeight',
\   'WinDecreaseWidth',
\   'WinGoLast',
\   'WinGoNext',
\   'WinIncreaseHeight',
\   'WinIncreaseWidth',
\   'WinMoveToBottomEdge',
\   'WinMoveToLeftEdge',
\   'WinMoveToNewTab',
\   'WinMoveToRightEdge',
\   'WinMoveToTopEdge',
\   'WinResizeHorizontal',
\   'WinResizeVertical',
\   'WinReverseGoNext',
\   'WinReverseRotate',
\   'WinRotate'
\]
let s:cmdsWithSubwinToSupwin = [
\   'WinDecreaseHeight',
\   'WinDecreaseWidth',
\   'WinGoFirst',
\   'WinGoLast',
\   'WinGoNext',
\   'WinIncreaseHeight',
\   'WinIncreaseWidth',
\   'WinMoveToBottomEdge',
\   'WinMoveToLeftEdge',
\   'WinMoveToNewTab',
\   'WinMoveToRightEdge',
\   'WinMoveToTopEdge',
\   'WinReverseGoNext',
\   'WinReverseRotate',
\   'WinRotate'
\]
let s:cmdsWithoutUberwins = [
\   'WinGoFirst',
\   'WinGoLast',
\   'WinGoNext',
\   'WinMoveToBottomEdge',
\   'WinMoveToLeftEdge',
\   'WinMoveToRightEdge',
\   'WinMoveToTopEdge',
\   'WinReverseGoNext',
\   'WinReverseRotate',
\   'WinRotate'
\]
let s:cmdsWithoutSubwins = [
\   'WinDecreaseHeight',
\   'WinDecreaseWidth',
\   'WinEqualize',
\   'WinGoFirst',
\   'WinGoLast',
\   'WinGoNext',
\   'WinIncreaseHeight',
\   'WinIncreaseWidth',
\   'WinMoveToBottomEdge',
\   'WinMoveToLeftEdge',
\   'WinMoveToRightEdge',
\   'WinMoveToTopEdge',
\   'WinResizeHorizontal',
\   'WinResizeVertical',
\   'WinReverseGoNext',
\   'WinReverseRotate',
\   'WinRotate'
\]

for cmdname in keys(s:allNonSpecialCmds)
    call WinCmdDefineCmd(
   \    cmdname, s:allNonSpecialCmds[cmdname], '',
   \    index(s:cmdsWithPreserveCursorPos,  cmdname) >= 0,
   \    index(s:cmdsWithUberwinNop,         cmdname) >= 0,
   \    index(s:cmdsWithSubwinToSupwin,     cmdname) >= 0,
   \    index(s:cmdsWithoutUberwins,        cmdname) >= 0,
   \    index(s:cmdsWithoutSubwins,         cmdname) >= 0
   \)
endfor
