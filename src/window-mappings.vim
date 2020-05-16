" Window operation mappings
" See window.vim
" This file remaps every Vim Ctrl-W command that doesn't play well with the
" window engine, to a custom command that does play well with the window
" engine.

" Map a command of the form <c-w><cmd> to run an Ex command with a count
function! s:MapCmd(cmd, exCmd, allow0, mapinnormalmode, mapinvisualmode, mapininsertmode, mapinterminalmode)
    if a:allow0
        let countstr = 'v:count'
    else
        let countstr = 'max([v:count,1])'
    endif
    if a:mapinnormalmode
        execute 'nnoremap <silent> <c-w>' . a:cmd . ' :<c-u>execute(' . countstr . ' . "' . a:exCmd . '")<cr>'
    endif
    if a:mapinvisualmode
        execute 'vnoremap <silent> <c-w>' . a:cmd . ' :<c-u>execute(' . countstr . ' . "' . a:exCmd . '")<cr>'
    endif
    if a:mapininsertmode
        execute 'inoremap <silent> <c-w>' . a:cmd . ' <esc>:<c-u>execute(' . countstr . ' . "' . a:exCmd . '")<cr>i'
    endif
    if a:mapinterminalmode
        execute 'tnoremap <silent> <c-w>' . a:cmd . ' <c-w>:<c-u>execute(' . countstr . ' . "' . a:exCmd . '")<cr>'
    endif
endfunction

" Create an Ex command and mappings that run a Ctrl-W command with flags
function! WinMappingMapCmd(cmds, exCmdName, defaultcount, allow0,
                         \ preservecursor,
                         \ ifuberwindonothing, ifsubwingotosupwin,
                         \ dowithoutuberwins, dowithoutsubwins,
                         \ mapinnormalmode, mapinvisualmode,
                         \ mapininsertmode, mapinterminalmode)
    " Create command
    execute 'command! -nargs=0 -count=' . a:defaultcount . ' -complete=command ' .
   \        a:exCmdName . ' call WinDoCmdWithFlags("' .
   \        a:cmds[0] . '",' .
   \        '<count>,' .
   \        a:preservecursor . ',' .
   \        a:ifuberwindonothing . ',' .
   \        a:ifsubwingotosupwin . ',' .
   \        a:dowithoutuberwins . ',' .
   \        a:dowithoutsubwins . ')'

    " Create mappings
    for cmd in a:cmds
        call s:MapCmd(cmd, a:exCmdName, a:allow0, a:mapinnormalmode, a:mapinvisualmode, a:mapininsertmode, a:mapinterminalmode)
    endfor
endfunction

" Some window commands require special treatment beyond what the flags in
" WinDoCmdWithFlags can provide, so use custom user operations for those
function! WinMappingMapSpecialCmd(cmds, exCmdName, defaultcount, allow0, handler,
                                \ mapinnormalmode, mapinvisualmode,
                                \ mapininsertmode, mapinterminalmode)
    " Create command
    execute 'command! -nargs=0 -count=' . a:defaultcount . ' -complete=command ' .
   \        a:exCmdName . ' call ' . a:handler . '(<count>)'
    " Create mappings
    for cmd in a:cmds
        call s:MapCmd(cmd, a:exCmdName, a:allow0, a:mapinnormalmode, a:mapinvisualmode, a:mapininsertmode, a:mapinterminalmode)
    endfor
endfunction

" This <expr> mapping maps <c-w>{nr}{cmd} to {nr}<c-w>{cmd}, recursively so
" that all the other mappings defined in this file apply as well
function! WinMappingParseInfixCount()
    let input = ''
    while input =~# '^\d*$'
        let input .= nr2char(getchar())
    endwhile
    return input[:-2] . "\<c-w>" . input[-1:-1]
endfunction
map <expr> <c-w> WinMappingParseInfixCount()

" z{nr}<cr> is the only alias of a <c-w> command that does not start with <c-w>
function! WinMappingParseZNrCr()
    let input = ''
    while input =~# '^\d*$'
        let input .= nr2char(getchar())
    endwhile
    if input[-1:-1] !=# "\<cr>"
       return ''
    endif
    return input[:-2] . "\<c-w>_"
endfunction
nmap <expr> z WinMappingParseZNrCr()
vmap <expr> z WinMappingParseZNrCr()

" Special-treatment command mappings

" Movement commands are special because they need to skip over subwins and
" afterimage/deafterimage
call WinMappingMapSpecialCmd(['h','<left>','<c-h>','<bs>'],'WinGoLeft',          1,0,'WinGoLeft',                       1,1,0,1)
call WinMappingMapSpecialCmd(['j','<down>','<c-j>'],       'WinGoDown',          1,0,'WinGoDown',                       1,1,0,1)
call WinMappingMapSpecialCmd(['k','<up>','<c-k>'],         'WinGoUp',            1,0,'WinGoUp',                         1,1,0,1)
call WinMappingMapSpecialCmd(['l','<right>','<c-l>'],      'WinGoRight',         1,0,'WinGoRight',                      1,1,0,1)
call WinMappingMapSpecialCmd(['_'],                        'WinResizeHorizontal',0,1,'WinResizeCurrentSupwinHorizontal',1,1,0,1)
call WinMappingMapSpecialCmd(['\|'],                       'WinResizeVertical',  0,1,'WinResizeCurrentSupwinVertical',  1,1,0,1)
call WinMappingMapSpecialCmd(['p','<c-p>'],                'WinGotoPrevious',    1,1,'WinGotoPrevious',                 1,1,0,1)

" Command mappings
" Window commands that aren't in this list will not be remapped
let s:allNonSpecialCmds = {
\   'WinEqualize':        ['='], 'WinRotate':          ['r','<c-r>'],
\   'WinReverseRotate':   ['R'], 'WinExchange':        ['x','<c-x>'],
\   'WinMoveToLeftEdge':  ['H'], 'WinModeToBottomEdge':['J'],
\   'WinMoveToTopEdge':   ['K'], 'WinMoveToRightEdge': ['L'],
\   'WinMoveToNewTab':    ['T'], 'WinIncreaseHeight':  ['+'],
\   'WinDecreaseHeight':  ['-'], 'WinDecreaseWidth':   ['<'],
\   'WinIncreaseWidth':   ['>'], 'WinGoNext':          ['w','<c-w>'],
\   'WinReverseGoNext':   ['W'], 'WinGoFirst':         ['t'],
\   'WinGoLast':          ['b'], 'WinCloseOthers':     ['o','<c-o>'] }
let s:cmdsWithDefaultCount0 = []
let s:cmdsWithAllow0 = []
let s:cmdsWithPreserveCursorPos = [
\   'WinEqualize',         'WinRotate',
\   'WinReverseRotate',    'WinMoveToLeftEdge',
\   'WinModeToBottomEdge', 'WinMoveToTopEdge',
\   'WinMoveToRightEdge',  'WinIncreaseHeight',
\   'WinDecreaseHeight',   'WinDecreaseWidth',
\   'WinIncreaseWidth',    'WinCloseOthers' ]
let s:cmdsWithUberwinNop = [
\   'WinRotate',           'WinReverseRotate',
\   'WinExchange',         'WinMoveToLeftEdge',
\   'WinModeToBottomEdge', 'WinMoveToTopEdge',
\   'WinMoveToRightEdge',  'WinMoveToNewTab',
\   'WinIncreaseHeight',   'WinDecreaseHeight',
\   'WinDecreaseWidth',    'WinIncreaseWidth',
\   'WinGoNext',           'WinReverseGoNext',
\   'WinGoLast',           'WinCloseOthers' ]
let s:cmdsWithSubwinToSupwin = [
\   'WinEqualize',       'WinRotate',
\   'WinReverseRotate',  'WinExchange',
\   'WinMoveToLeftEdge', 'WinModeToBottomEdge',
\   'WinMoveToTopEdge',  'WinMoveToRightEdge',
\   'WinMoveToNewTab',   'WinIncreaseHeight',
\   'WinDecreaseHeight', 'WinDecreaseWidth',
\   'WinIncreaseWidth',  'WinGoNext',
\   'WinReverseGoNext',  'WinGoFirst',
\   'WinGoLast',         'WinCloseOthers' ]
let s:cmdsWithoutUberwins = [
\   'WinRotate',         'WinExchange',
\   'WinModeToLeftEdge', 'WinModeToBottomEdge',
\   'WinModeToTopEdge',  'WinModeToRightEdge',
\   'WinGoNext',         'WinReverseRotate',
\   'WinReverseGoNext',  'WinGoFirst',
\   'WinGoLast' ]
let s:cmdsWithoutSubwins = [
\   'WinIncreaseHeight',   'WinDecreaseHeight',
\   'WinDecreaseWidth',    'WinIncreaseWidth',
\   'WinEqualize',         'WinRotate',
\   'WinExchange',         'WinModeToLeftEdge',
\   'WinModeToBottomEdge', 'WinModeToTopEdge',
\   'WinModeToRightEdge',  'WinGoNext',
\   'WinReverseRotate',    'WinReverseGoNext',
\   'WinGoFirst',          'WinGoLast' ]
let s:cmdsWithNormalModeMapping = keys(s:allNonSpecialCmds)
let s:cmdsWithVisualModeMapping = keys(s:allNonSpecialCmds)
let s:cmdsWithInsertModeMapping = []
let s:cmdsWithTerminalModeMapping = keys(s:allNonSpecialCmds)

for cmdName in keys(s:allNonSpecialCmds)
    call WinMappingMapCmd(
   \    s:allNonSpecialCmds[cmdName], cmdName,
   \    index(s:cmdsWithDefaultCount0,       cmdName) >=# 0,
   \    index(s:cmdsWithAllow0,              cmdName) >=# 0,
   \    index(s:cmdsWithPreserveCursorPos,   cmdName) >=# 0,
   \    index(s:cmdsWithUberwinNop,          cmdName) >=# 0,
   \    index(s:cmdsWithSubwinToSupwin,      cmdName) >=# 0,
   \    index(s:cmdsWithoutUberwins,         cmdName) >=# 0,
   \    index(s:cmdsWithoutSubwins,          cmdName) >=# 0,
   \    index(s:cmdsWithNormalModeMapping,   cmdName) >=# 0,
   \    index(s:cmdsWithVisualModeMapping,   cmdName) >=# 0,
   \    index(s:cmdsWithInsertModeMapping,   cmdName) >=# 0,
   \    index(s:cmdsWithTerminalModeMapping, cmdName) >=# 0
   \)
endfor
