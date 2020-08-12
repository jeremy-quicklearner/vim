" Custom window-related commands
" See window.vim
" This file defines several custom commands that call user operations

" TODO: Test WinOnly
" TODO: Test WinDecreaseHeight
" TODO: Test WinDecreaseWidth
" TODO: Test WinEqualize
" TODO: Test WinExchange
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
    call EchomLog('window-commands', 'debug', 'SanitizeRange ', a:cmdname, ', [', a:range, ',', a:count, ',', a:defaultcount, ']')
    if a:range ==# 0
        call EchomLog('window-commands', 'verbose', 'Using default count ', a:defaultcount)
        return a:defaultcount
    endif

    if a:range ==# 1
        call EchomLog('window-commands', 'verbose', 'Using given count ', a:count)
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
                     \ dowithoutsubwins,
                     \ relyonresolver)
    call EchomLog('window-commands', 'info', 'WinCmdRunCmd ' . a:cmdname . ', ' . a:wincmd . ', [' . a:range . ',' . a:count . ',' . a:defaultcount . ',' . a:preservecursor . ',' . a:ifuberwindonothing . ',' . a:ifsubwingotosupwin . ',' . a:dowithoutuberwins . ',' . a:dowithoutsubwins . ',' . a:relyonresolver . ']')
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
                         \ a:dowithoutsubwins,
                         \ a:relyonresolver)
endfunction

function! WinCmdRunSpecialCmd(cmdname, range, count, handler)
    call EchomLog('window-commands', 'info', 'WinCmdRunSpecialCmd ', a:cmdname, ', [', a:range, ',', a:count, '], ', a:handler)
    try
        let opcount = s:SanitizeRange(a:cmdname, a:range, a:count, '')
        let Handler = function(a:handler)

        call Handler(opcount)
    catch /.*/
        call EchomLog('window-commands', 'debug', v:throwpoint)
        call EchomLog('window-commands', 'warning', v:exception)
        return
    endtry
endfunction

function! WinCmdDefineCmd(cmdname, wincmd, defaultcount,
                        \ preservecursor,
                        \ ifuberwindonothing, ifsubwingotosupwin,
                        \ dowithoutuberwins, dowithoutsubwins,
                        \ relyonresolver)
    call EchomLog('window-commands', 'config', 'Command: ', a:cmdname)
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
   \        a:dowithoutsubwins . ',' .
   \        a:relyonresolver . ')'
endfunction

function! WinCmdDefineSpecialCmd(cmdname, handler)
    call EchomLog('window-commands', 'config', 'Special command: ', a:cmdname)
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

" If WinResizeHorizontal and WinResizeVertical must run wincmd _ and
" wincmd | with uberwins closed, they could change the uberwins's sizes and cause
" the resolver to later close and reopen the uberwins. RestoreMaxDimensionsByWinid
" would then mess up all the supwins' sizes, so the user's intent would be
" lost. So WinResizeHorizontal and WinResizeVertical must run without
" uberwins.
" The user invokes WinResizeHorizontal and WinResizeVertical while looking at
" a layout with uberwins, and supplies counts accordingly. However, when
" wincmd _ and wincmd \| run, the closed uberwins may have given their screen
" space to the supwin being resized. So the counts need to be normalized by
" the supwin's change in dimension across the uberwins closing.
" WinCommonDoWithout* shouldn't have to do the normalizing because these are
" the only two commands that require it. So they have a custom implementation.
call WinCmdDefineSpecialCmd('WinResizeHorizontal', 'WinResizeHorizontal')
call WinCmdDefineSpecialCmd('WinResizeVertical',   'WinResizeVertical')

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
\   'WinReverseGoNext',
\   'WinReverseRotate',
\   'WinRotate'
\]
" TODO: Make this list as small as possible
let s:cmdsThatRelyOnResolver = [
\   'WinMoveToNewTab',
\]

for cmdname in keys(s:allNonSpecialCmds)
    call WinCmdDefineCmd(
   \    cmdname, s:allNonSpecialCmds[cmdname], '',
   \    index(s:cmdsWithPreserveCursorPos,  cmdname) >= 0,
   \    index(s:cmdsWithUberwinNop,         cmdname) >= 0,
   \    index(s:cmdsWithSubwinToSupwin,     cmdname) >= 0,
   \    index(s:cmdsWithoutUberwins,        cmdname) >= 0,
   \    index(s:cmdsWithoutSubwins,         cmdname) >= 0,
   \    index(s:cmdsThatRelyOnResolver,     cmdname) >= 0
   \)
endfor
