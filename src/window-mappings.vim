" Window operation mappings
" See window.vim

" Create an Ex command and mappings that run a Ctrl-W command with flags
function! WinMappingMapCmd(cmds, exCmdName,
                         \ preservecursor,
                         \ ifuberwindonothing, ifsubwingotosupwin,
                         \ dowithoutuberwins, dowithoutsubwins,
                         \ mapinnormalmode, mapinvisualmode,
                         \ mapininsertmode, mapinterminalmode)
    " Create command
    execute 'command! -nargs=0 -count=1 -complete=command ' .
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
        if a:mapinnormalmode
            execute 'nnoremap <silent> <c-w>' . cmd . ' :' . a:exCmdName . '<cr>'
        endif
        if a:mapinvisualmode
            execute 'vnoremap <silent> <c-w>' . cmd . ' :' . a:exCmdName . '<cr>'
        endif
        if a:mapininsertmode
            execute 'inoremap <silent> <c-w>' . cmd . ' :' . a:exCmdName . '<cr>'
        endif
        if a:mapinterminalmode
            execute 'tnoremap <silent> <c-w>' . cmd . ' <c-w>:' . a:exCmdName . '<cr>'
        endif
    endfor
endfunction

" Some window commands require special treatment beyond what the flags in
" WinDoCmdWithFlags can provide, so use custom user operations for those
function! WinMappingMapSpecialCmd(cmds, exCmdName, handler,
                             \ mapinnormalmode, mapinvisualmode,
                             \ mapininsertmode, mapinterminalmode)
    " Create command
    execute 'command! -nargs=0 -complete=command ' .
   \        a:exCmdName . ' call ' . a:handler . '()'
    " Create mappings
    for cmd in a:cmds
        if a:mapinnormalmode
            execute 'nnoremap <silent> <c-w>' . cmd . ' :' . a:exCmdName . '<cr>'
        endif
        if a:mapinvisualmode
            execute 'vnoremap <silent> <c-w>' . cmd . ' :' . a:exCmdName . '<cr>'
        endif
        if a:mapininsertmode
            execute 'inoremap <silent> <c-w>' . cmd . ' :' . a:exCmdName . '<cr>'
        endif
        if a:mapinterminalmode
            execute 'tnoremap <silent> <c-w>' . cmd . ' <c-w>:' . a:exCmdName . '<cr>'
        endif
    endfor
endfunction

" Special-treatment command mappings

" Movement commands are special because they need to skip over subwins and
" afterimage/deafterimage
call WinMappingMapSpecialCmd(['h','<left>','<c-h>','<bs>'],'WinGoLeft',          'WinGoLeft',                       1,1,0,1)
call WinMappingMapSpecialCmd(['j','<down>','<c-j>'],       'WinGoDown',          'WinGoDown',                       1,1,0,1)
call WinMappingMapSpecialCmd(['k','<up>','<c-k>'],         'WinGoUp',            'WinGoUp',                         1,1,0,1)
call WinMappingMapSpecialCmd(['l','<right>','<c-h>'],      'WinGoRight',         'WinGoRight',                      1,1,0,1)
call WinMappingMapSpecialCmd(['\|'],                       'WinExpandHorizontal','WinExpandCurrentSupwinHorizontal',1,1,0,1)
call WinMappingMapSpecialCmd(['_'],                        'WinExpandVertical',  'WinExpandCurrentSupwinVertical',  1,1,0,1)
call WinMappingMapSpecialCmd(['p','<c-p>'],                'WinGotoPrevious',    'WinGotoPrevious',                 1,1,0,1)

function! WinMappingGotoPreview()
    call WinGotoUberwin('preview', 'preview')
endfunction
call WinMappingMapSpecialCmd(['P'],                        'WinGotoPreview',     'WinMappingGotoPreview',           1,1,0,1)

" Command mappings
" Window commands that aren't in this list will not be remapped
let s:allNonSpecialCmds = {
\   'WinEqualize':        ['='], 'WinRotate':        ['r','<c-r>'],
\   'WinReverseRotate':   ['R'], 'WinExchange':      ['x','<c-x>'],
\   'WinMoveToLeftEdge':  ['H'],
\   'WinModeToBottomEdge':['J'], 'WinMoveToTopEdge': ['K'],
\   'WinMoveToRightEdge': ['L'], 'WinMoveToNewTab':  ['T'],
\   'WinIncreaseHeight':  ['+'],
\   'WinDecreaseHeight':  ['-'], 'WinDecreaseWidth': ['<'],
\   'WinIncreaseWidth':   ['>'], 'WinGoNext':        ['w','<c-w>'],
\   'WinReverseGoNext':   ['W'], 'WinGoFirst':       ['t'],
\   'WinGoLast':          ['b'], 'WinCloseOthers':   ['o','<c-o>'] }
let s:cmdsWithPreserveCursorPos = [
\   'WinEqualize',         'WinRotate',
\   'WinReverseRotate',    'WinMoveToLeftEdge',
\   'WinModeToBottomEdge', 'WinMoveToTopEdge',
\   'WinMoveToRightEdge',  'WinIncreaseHeight',
\   'WinDecreaseHeight',   'WinDecreaseWidth',
\   'WinIncreaseWidth',    'WinCloseOthers' ]
let s:cmdsWithUberwinNop = [
\   'WinRotate',         'WinReverseRotate',
\   'WinExchange',
\   'WinMoveToLeftEdge', 'WinModeToBottomEdge',
\   'WinMoveToTopEdge',  'WinMoveToRightEdge',
\   'WinMoveToNewTab',
\   'WinIncreaseHeight', 'WinDecreaseHeight',
\   'WinDecreaseWidth',  'WinIncreaseWidth',
\   'WinGoNext',         'WinReverseGoNext',
\   'WinGoLast', 'WinCloseOthers' ]
let s:cmdsWithSubwinToSupwin = [
\   'WinEqualize', 'WinRotate',
\   'WinReverseRotate', 'WinExchange',
\   'WinMoveToLeftEdge',
\   'WinModeToBottomEdge', 'WinMoveToTopEdge',
\   'WinMoveToRightEdge', 'WinMoveToNewTab',
\   'WinIncreaseHeight',
\   'WinDecreaseHeight', 'WinDecreaseWidth',
\   'WinIncreaseWidth', 'WinGoNext',
\   'WinReverseGoNext', 'WinGoFirst',
\   'WinGoLast', 'WinCloseOthers' ]
let s:cmdsWithoutUberwins = [
\   'WinEqualize',       'WinRotate',
\   'WinExchange',
\   'WinModeToLeftEdge', 'WinModeToBottomEdge',
\   'WinModeToTopEdge',  'WinModeToRightEdge',
\   'WinGoNext',         'WinReverseRotate',
\   'WinReverseGoNext',  'WinGoFirst',
\   'WinGoLast' ]
let s:cmdsWithoutSubwins = [
\   'WinIncreaseHeight', 'WinDecreaseHeight',
\   'WinDecreaseWidth',  'WinIncreaseWidth',
\   'WinEqualize',       'WinRotate',
\   'WinExchange',
\   'WinModeToLeftEdge', 'WinModeToBottomEdge',
\   'WinModeToTopEdge',  'WinModeToRightEdge',
\   'WinGoNext',         'WinReverseRotate',
\   'WinReverseGoNext',  'WinGoFirst',
\   'WinGoLast' ]
let s:cmdsWithNormalModeMapping = keys(s:allNonSpecialCmds)
let s:cmdsWithVisualModeMapping = keys(s:allNonSpecialCmds)
let s:cmdsWithInsertModeMapping = []
let s:cmdsWithTerminalModeMapping = keys(s:allNonSpecialCmds)

for cmdName in keys(s:allNonSpecialCmds)
    call WinMappingMapCmd(
   \    s:allNonSpecialCmds[cmdName], cmdName,
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
