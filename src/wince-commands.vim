" Wince Commands
" See wince.vim
" TODO: Ensure all commands behave similarly to their native counterparts when
"       invoked from visual mode
" TODO: Thoroughly test every command
let s:Log = jer_log#LogFunctions('wince-commands')


function! s:SanitizeRange(cmdname, range, count, defaultcount)
    call s:Log.DBG('SanitizeRange ', a:cmdname, ', [', a:range, ',', a:count, ',', a:defaultcount, ']')
    if a:range ==# 0
        call s:Log.VRB('Using default count ', a:defaultcount)
        return a:defaultcount
    endif

    if a:range ==# 1
        call s:Log.VRB('Using given count ', a:count)
        return a:count
    endif
     
    if a:range ==# 2
        throw 'Range not allowed for ' . a:cmdname
    endif

    throw 'Invalid <range> ' . a:range
endfunction

function! WinceCmdRunCmd(cmdname, wincmd, range, count, startmode,
                       \ defaultcount,
                       \ preservecursor,
                       \ ifuberwindonothing,
                       \ ifsubwingotosupwin,
                       \ dowithoutuberwins,
                       \ dowithoutsubwins,
                       \ relyonresolver)
    call s:Log.INF('WinceCmdRunCmd ' . a:cmdname . ', ' . a:wincmd . ', [' . a:range . ',' . a:count . ',' . string(a:startmode) . ',' . a:defaultcount . ',' . a:preservecursor . ',' . a:ifuberwindonothing . ',' . a:ifsubwingotosupwin . ',' . a:dowithoutuberwins . ',' . a:dowithoutsubwins . ',' . a:relyonresolver . ']')
    try
        let opcount = s:SanitizeRange(a:cmdname, a:range, a:count, a:defaultcount)
    catch /.*/
        call s:Log.ERR(v:exception)
        return a:startmode
    endtry

    return WinceDoCmdWithFlags(a:wincmd, opcount, a:startmode,
                           \ a:preservecursor,
                           \ a:ifuberwindonothing,
                           \ a:ifsubwingotosupwin,
                           \ a:dowithoutuberwins,
                           \ a:dowithoutsubwins,
                           \ a:relyonresolver)
endfunction

function! WinceCmdRunSpecialCmd(cmdname, range, count, startmode, handler)
    call s:Log.INF('WinceCmdRunSpecialCmd ', a:cmdname, ', [', a:range, ',', a:count, ',', a:startmode, '], ', a:handler)
    try
        let opcount = s:SanitizeRange(a:cmdname, a:range, a:count, '')
        let Handler = function(a:handler)

        return Handler(opcount, a:startmode)
    catch /.*/
        call s:Log.DBG(v:throwpoint)
        call s:Log.WRN(v:exception)
        return a:startmode
    endtry
endfunction

function! WinceCmdDefineCmd(cmdname, wincmd, defaultcount,
                          \ preservecursor,
                          \ ifuberwindonothing, ifsubwingotosupwin,
                          \ dowithoutuberwins, dowithoutsubwins,
                          \ relyonresolver)
    call s:Log.DBG('Command: ', a:cmdname)
    execute 'command! -nargs=? -range=0 -complete=command ' . a:cmdname .
   \        ' call jer_mode#Detect("<args>") | '
   \        'call jer_mode#ForcePreserve(WinceCmdRunCmd(' .
   \        '"' . a:cmdname . '",' .
   \        '"' . a:wincmd . '",' .
   \        '<range>,<count>,' .
   \        'jer_mode#Retrieve(),' .
   \        '"' . a:defaultcount . '",' .
   \        a:preservecursor . ',' .
   \        a:ifuberwindonothing . ',' .
   \        a:ifsubwingotosupwin . ',' .
   \        a:dowithoutuberwins . ',' .
   \        a:dowithoutsubwins . ',' .
   \        a:relyonresolver . ')) | ' .
   \        'call jer_mode#Restore()'
endfunction

function! WinceCmdDefineSpecialCmd(cmdname, handler)
    call s:Log.DBG('Special command: ', a:cmdname)
    execute 'command! -nargs=? -range=0 -complete=command ' . a:cmdname .
   \        ' call jer_mode#Detect("<args>") | ' .
   \        'call jer_mode#ForcePreserve(WinceCmdRunSpecialCmd(' .
   \        '"' . a:cmdname . '",' .
   \        '<range>,<count>,' .
   \        'jer_mode#Retrieve(),' .
   \        '"' . a:handler . '")) | ' .
   \        'call jer_mode#Restore()'
endfunction

" Exchanging supwins is special because if the operation is invoked from a
" subwin, the cursor should be restored to the corresponding subwin of the
" exchanged window
call WinceCmdDefineSpecialCmd('WinceExchange','WinceExchange')

" Going to the previous window requires special accounting in the user
" operations because window engine code is always moving the cursor all over
" the place and Vim's internal 'previous window' means nothing to the user
call WinceCmdDefineSpecialCmd('WinceGotoPrevious','WinceGotoPrevious')

" WinceOnly is special because if it isn't, its counted version can land in a
" subwin and close all other windows (including the subwin's supwin) leaving
" the subwin dangling, which will cause the resolver to exit the tab
call WinceCmdDefineSpecialCmd('WinceOnly', 'WinceOnly')

" If WinceResizeHorizontal and WinceResizeVertical ran run wincmd _ and wincmd | with
" uberwins open, they could change the uberwins' sizes and cause the resolver to
" later close and reopen the uberwins. RestoreMaxDimensionsByWinid
" would then mess up all the supwins' sizes, so the user's intent would be
" lost. So WinceResizeHorizontal and WinceResizeVertical must run without
" uberwins.
" The user invokes WinceResizeHorizontal and WinceResizeVertical while looking at
" a layout with uberwins, and supplies counts accordingly. However, when
" wincmd _ and wincmd | run, the closed uberwins may have given their screen
" space to the supwin being resized. So the counts need to be normalized by
" the supwin's change in dimension across the uberwins closing.
" WinCommonDoWithout* shouldn't have to do the normalizing because these are
" the only two commands that require it. So they have a custom implementation.
call WinceCmdDefineSpecialCmd('WinceResizeVertical',             'WinceResizeVertical')
call WinceCmdDefineSpecialCmd('WinceResizeHorizontal',           'WinceResizeHorizontal')
" This command exists because the default behaviour of z<cr> (a nop) is
" different from the default behaviour of <c-w>_
call WinceCmdDefineSpecialCmd('WinceResizeHorizontalDefaultNop', 'WinceResizeHorizontalDefaultNop')

" Movement commands are special because if the starting point is an uberwin,
" using DoWithoutUberwins would change the starting point to be the first
" supwin. But DoWithoutUberwins would be necessary because we don't want to
" move to Uberwins. So use custom logic.
call WinceCmdDefineSpecialCmd('WinceGoLeft',  'WinceGoLeft' )
call WinceCmdDefineSpecialCmd('WinceGoDown',  'WinceGoDown' )
call WinceCmdDefineSpecialCmd('WinceGoUp',    'WinceGoUp'   )
call WinceCmdDefineSpecialCmd('WinceGoRight', 'WinceGoRight')

let s:allNonSpecialCmds = {
\   'WinceDecreaseHeight':   '-',
\   'WinceDecreaseWidth':    '<',
\   'WinceEqualize':         '=',
\   'WinceGoFirst':          't',
\   'WinceGoLast':           'b',
\   'WinceGoNext':           'w',
\   'WinceIncreaseHeight':   '+',
\   'WinceIncreaseWidth':    '>',
\   'WinceMoveToBottomEdge': 'J',
\   'WinceMoveToLeftEdge':   'H',
\   'WinceMoveToNewTab':     'T',
\   'WinceMoveToRightEdge':  'L',
\   'WinceMoveToTopEdge':    'K',
\   'WinceReverseGoNext':    'W',
\   'WinceReverseRotate':    'R',
\   'WinceRotate':           'r',
\   'WinceSplitHorizontal':  's',
\   'WinceSplitVertical':    'v',
\   'WinceSplitNew':         'n',
\   'WinceSplitAlternate':   '^',
\   'WinceQuit':             'q',
\   'WinceClose':            'c',
\   'WinceGotoPreview':      'P',
\   'WinceSplitTag':         ']',
\   'WinceSplitTagSelect':   'g]',
\   'WinceSplitTagJump':     'g<c-]>',
\   'WinceSplitFilename':    'f',
\   'WinceSplitFilenameLine':'F',
\   'WincePreviewClose':     'z',
\   'WincePreviewTag':       '}',
\   'WincePreviewTagJump':   'g}',
\   'WinceSplitSearchWord':  'i',
\   'WinceSplitSearchMacro': 'd'
\} 
let s:cmdsThatPreserveCursorPos = [
\   'WinceDecreaseHeight',
\   'WinceDecreaseWidth',
\   'WinceEqualize',
\   'WinceIncreaseHeight',
\   'WinceIncreaseWidth',
\   'WinceMoveToBottomEdge',
\   'WinceMoveToLeftEdge',
\   'WinceMoveToRightEdge',
\   'WinceMoveToTopEdge',
\   'WinceReverseRotate',
\   'WinceRotate',
\   'WincePreviewClose'
\]
let s:cmdsWithUberwinNop = [
\   'WinceDecreaseHeight',
\   'WinceDecreaseWidth',
\   'WinceGoLast',
\   'WinceGoNext',
\   'WinceIncreaseHeight',
\   'WinceIncreaseWidth',
\   'WinceMoveToBottomEdge',
\   'WinceMoveToLeftEdge',
\   'WinceMoveToNewTab',
\   'WinceMoveToRightEdge',
\   'WinceMoveToTopEdge',
\   'WinceReverseGoNext',
\   'WinceReverseRotate',
\   'WinceRotate',
\   'WinceSplitHorizontal',
\   'WinceSplitVertical',
\   'WinceSplitNew',
\   'WinceSplitAlternate',
\   'WinceSplitTag',
\   'WinceSplitTagSelect',
\   'WinceSplitTagJump',
\   'WinceSplitFilename',
\   'WinceSplitFilenameLine',
\   'WinceSplitSearchWord',
\   'WinceSplitSearchMacro'
\]
let s:cmdsWithSubwinToSupwin = [
\   'WinceDecreaseHeight',
\   'WinceDecreaseWidth',
\   'WinceGoFirst',
\   'WinceGoLast',
\   'WinceGoNext',
\   'WinceIncreaseHeight',
\   'WinceIncreaseWidth',
\   'WinceMoveToBottomEdge',
\   'WinceMoveToLeftEdge',
\   'WinceMoveToNewTab',
\   'WinceMoveToRightEdge',
\   'WinceMoveToTopEdge',
\   'WinceReverseGoNext',
\   'WinceReverseRotate',
\   'WinceRotate',
\   'WinceSplitHorizontal',
\   'WinceSplitVertical',
\   'WinceSplitNew',
\   'WinceSplitAlternate',
\   'WinceSplitTag',
\   'WinceSplitTagSelect',
\   'WinceSplitTagJump',
\   'WinceSplitFilename',
\   'WinceSplitFilenameLine',
\   'WinceSplitSearchWord',
\   'WinceSplitSearchMacro'
\]
let s:cmdsWithoutUberwins = [
\   'WinceDecreaseHeight',
\   'WinceDecreaseWidth',
\   'WinceGoFirst',
\   'WinceGoLast',
\   'WinceGoNext',
\   'WinceIncreaseHeight',
\   'WinceIncreaseWidth',
\   'WinceMoveToBottomEdge',
\   'WinceMoveToLeftEdge',
\   'WinceMoveToRightEdge',
\   'WinceMoveToTopEdge',
\   'WinceReverseGoNext',
\   'WinceReverseRotate',
\   'WinceRotate'
\]
let s:cmdsWithoutSubwins = [
\   'WinceDecreaseHeight',
\   'WinceDecreaseWidth',
\   'WinceEqualize',
\   'WinceGoFirst',
\   'WinceGoLast',
\   'WinceGoNext',
\   'WinceIncreaseHeight',
\   'WinceIncreaseWidth',
\   'WinceMoveToBottomEdge',
\   'WinceMoveToLeftEdge',
\   'WinceMoveToNewTab',
\   'WinceMoveToRightEdge',
\   'WinceMoveToTopEdge',
\   'WinceReverseGoNext',
\   'WinceReverseRotate',
\   'WinceRotate',
\   'WinceSplitHorizontal',
\   'WinceSplitVertical',
\   'WinceSplitNew',
\   'WinceSplitAlternate',
\   'WinceSplitTag',
\   'WinceSplitTagSelect',
\   'WinceSplitTagJump',
\   'WinceSplitFilename',
\   'WinceSplitFilenameLine',
\   'WinceSplitSearchWord',
\   'WinceSplitSearchMacro'
\]

" Commands in this list are the ones that WinceDoCmdWithFlags isn't
" smart enough to handle, but the resolver is smart enough for
let s:cmdsThatRelyOnResolver = [
\   'WinceMoveToNewTab',
\   'WinceSplitHorizontal',
\   'WinceSplitVertical',
\   'WinceSplitNew',
\   'WinceSplitAlternate',
\   'WinceQuit',
\   'WinceClose',
\   'WinceGotoPreview',
\   'WinceSplitTag',
\   'WinceSplitTagSelect',
\   'WinceSplitTagJump',
\   'WinceSplitFilename',
\   'WinceSplitFilenameLine',
\   'WincePreviewClose',
\   'WincePreviewTag',
\   'WincePreviewTagJump',
\   'WinceSplitSearchWord',
\   'WinceSplitSearchMacro'
\]

for cmdname in keys(s:allNonSpecialCmds)
    call WinceCmdDefineCmd(
   \    cmdname, s:allNonSpecialCmds[cmdname], '',
   \    index(s:cmdsThatPreserveCursorPos,  cmdname) >= 0,
   \    index(s:cmdsWithUberwinNop,         cmdname) >= 0,
   \    index(s:cmdsWithSubwinToSupwin,     cmdname) >= 0,
   \    index(s:cmdsWithoutUberwins,        cmdname) >= 0,
   \    index(s:cmdsWithoutSubwins,         cmdname) >= 0,
   \    index(s:cmdsThatRelyOnResolver,     cmdname) >= 0
   \)
endfor
