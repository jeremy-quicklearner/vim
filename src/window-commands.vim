" Custom window-related commands
" See window.vim
" This file defines several custom commands that call user operations

" TODO: Test WinCloseOthers
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
    if a:range ==# 0
        return a:defaultcount
    endif

    if a:range ==# 1
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
    try
        let opcount = s:SanitizeRange(a:cmdname, a:range, a:count, a:defaultcount)
    catch /.*/
        echohl ErrorMsg | echom v:exception | echohl None
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
    try
        let opcount = s:SanitizeRange(a:cmdname, a:range, a:count, '')
        let Handler = function(a:handler)

        call Handler(opcount)
    catch /.*/
        echohl ErrorMsg | echom v:exception | echohl None
        return
    endtry
endfunction

function! WinCmdDefineCmd(cmdname, wincmd, defaultcount,
                        \ preservecursor,
                        \ ifuberwindonothing, ifsubwingotosupwin,
                        \ dowithoutuberwins, dowithoutsubwins)
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
    execute 'command! -nargs=0 -range=0 -complete=command ' . a:cmdname .
   \        ' call WinCmdRunSpecialCmd(' .
   \        '"' . a:cmdname . '",' .
   \        '<range>,<count>,' .
   \        '"' . a:handler . '")'
endfunction

" Going to the previous window requires special accounting in the user
" operations because window engine code is always moving the cursor all over
" the place and Vim's internal 'previous window' means nothing to the user
call WinCmdDefineSpecialCmd('WinGotoPrevious','WinGotoPrevious')

" Movement commands are special because if the starting point is an uberwin,
" using DoWithoutUberwins would change the starting point to be the first
" supwin. But DoWithoutUberwins would be necessary because we don't want to
" move to Uberwins. So use custom logic.
call WinCmdDefineSpecialCmd('WinGoLeft',  'WinGoLeft' )
call WinCmdDefineSpecialCmd('WinGoDown',  'WinGoDown' )
call WinCmdDefineSpecialCmd('WinGoUp',    'WinGoUp'   )
call WinCmdDefineSpecialCmd('WinGoRight', 'WinGoRight')

let s:allNonSpecialCmds = {
\   'WinCloseOthers':     'o',
\   'WinDecreaseHeight':  '-',
\   'WinDecreaseWidth':   '<',
\   'WinEqualize':        '=',
\   'WinExchange':        'x',
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
\   'WinCloseOthers',
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
\   'WinCloseOthers',
\   'WinDecreaseHeight',
\   'WinDecreaseWidth',
\   'WinExchange',
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
\   'WinCloseOthers',
\   'WinDecreaseHeight',
\   'WinDecreaseWidth',
\   'WinExchange',
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
\   'WinExchange',
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
\   'WinExchange',
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
