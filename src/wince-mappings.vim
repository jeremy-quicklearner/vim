" Wince Mappings
" See window.vim
" This file remaps every Vim Ctrl-W command that doesn't play well with the
" window engine to one of the custom commands from wince-commands.vim.
" I did my best to cover all of them. If any slipped through, please let me
" know!
" TODO: Ensure all mappings behave similarly to their native counterparts when
"       invoked from visual mode
" TODO: Thoroughly test every mapping

if !exists('g:wince_disable_mappings')
    let g:wince_disable_mappings = 0
endif

" This function is a helper for group definitions which want to define
" mappings for adding, removing, showing, hiding, and jumping to their groups
function! WinceMappingMapUserOp(lhs, rhs)
    call EchomLog('wince-mappings', 'config', 'Map ', a:lhs, ' to ', a:rhs)
    execute 'nnoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinceStateDetectMode("n")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>'
    execute 'xnoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinceStateDetectMode("v")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>'
    execute 'snoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinceStateDetectMode("s")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>'
    execute 'tnoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinceStateDetectMode("t")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>'
endfunction

" Process v:count and v:count1 into a single count
function! WinceMappingProcessCounts(allow0)
    call EchomLog('wince-mappings', 'debug', 'WinceMappingProcessCounts ' , a:allow0)
    " v:count and v:count1 default to different values when no count is
    " provided
    if v:count !=# v:count1
        call EchomLog('wince-mappings', 'debug', 'Count not set')
        return ''
    endif

    if !a:allow0 && v:count <= 0
        call EchomLog('wince-mappings', 'debug', 'Count 0 not allowed. Substituting 1.')
        return 1
    endif

    return v:count
endfunction

" Stop here if mappings are disabled
if g:wince_disable_mappings
    call EchomLog('wince-mappings', 'config', 'Mappings disabled')
    finish
endif

" Map a command of the form <c-w><cmd> to run an Ex command with a count
function! s:DefineMappings(cmd, exCmd, allow0, mapinnormalmode, mapinvisualmode, mapinselectmode, mapinterminalmode)
    call EchomLog('wince-mappings', 'debug', 'DefineMappings ', a:cmd, ', ', a:exCmd, ', [', a:allow0, ',', a:mapinnormalmode, ',', a:mapinvisualmode, ',', a:mapinselectmode, ',', a:mapinterminalmode, ']')
    if a:mapinnormalmode
        execute 'nnoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinceStateDetectMode(\"n\")<cr><c-w>:<c-u>execute " . WinceMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>"'
    endif
    if a:mapinvisualmode
        execute 'xnoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinceStateDetectMode(\"v\")<cr><c-w>:<c-u>execute " . WinceMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>"'
    endif
    if a:mapinselectmode
        execute 'snoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinceStateDetectMode(\"s\")<cr><c-w>:<c-u>execute " . WinceMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>"'
    endif
    if a:mapinterminalmode
        execute 'tnoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinceStateDetectMode(\"t\")<cr><c-w>:<c-u>execute " . WinceMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinceStateRestoreMode()<cr>"'
    endif
endfunction

" Create an Ex command and mappings that run a Ctrl-W command with flags
function! WinceMappingMapCmd(cmds, exCmdName, allow0,
                         \ mapinnormalmode, mapinvisualmode, mapinselectmode,
                         \ mapinterminalmode)
    call EchomLog('wince-mappings', 'config', 'Map ', a:cmds, ' to ', a:exCmdName)
    for cmd in a:cmds
        call s:DefineMappings(cmd, a:exCmdName, a:allow0, a:mapinnormalmode, a:mapinvisualmode, a:mapinselectmode, a:mapinterminalmode)
    endfor
endfunction

" This tower of hacks maps <c-w>{nr}{cmd} to {nr}<c-w>{cmd} and z{nr}<cr>
" to {nr}z<cr>. This can't be done with v:count because {nr} doesn't come first.
" We must parse the characters ourselves.

" These top-level mappings are just on the first character and first digit of
" {nr}. 0 Is ommitted because Vim's default behaviour on <c-w>0 and z0 is
" already a nop
for idx in range(1,9)
    execute 'nnoremap <silent> <c-w>' . idx . ' <c-w>:<c-u>call WinceStateDetectMode("n")<cr><c-w>:<c-u>call WinceMappingScanW(' . idx . ')<cr>'
    execute 'xnoremap <silent> <c-w>' . idx . ' <c-w>:<c-u>call WinceStateDetectMode("v")<cr><c-w>:<c-u>call WinceMappingScanW(' . idx . ')<cr>'
    " There is no snoremap for <c-w> because no <c-w> commands can be run from
    " select mode

    execute 'nnoremap <silent> z' . idx . ' <c-w>:<c-u>call WinceStateDetectMode("n")<cr><c-w>:<c-u>call WinceMappingScanZ(' . idx . ')<cr>'
    execute 'xnoremap <silent> z' . idx . ' <c-w>:<c-u>call WinceStateDetectMode("v")<cr><c-w>:<c-u>call WinceMappingScanZ(' . idx . ')<cr>'
    execute 'snoremap <silent> z' . idx . ' <c-w>:<c-u>call WinceStateDetectMode("s")<cr><c-w>:<c-u>call WinceMappingScanZ(' . idx . ')<cr>'
endfor

" Tracks the characters typed so far
let s:sofar = ''

" These functions call WinceMappingScan() which will read more characters.
function! WinceMappingScanW(firstdigit)
    call EchomLog('wince-mappings', 'debug', 'WinceMappingScanW ', a:firstdigit)
    let s:sofar = "\<c-w>" . a:firstdigit
    call WinceMappingScan()
endfunction
function! WinceMappingScanZ(firstdigit)
    call EchomLog('wince-mappings', 'debug', 'WinceMappingScanZ ', a:firstdigit)
    let s:sofar = "z" . a:firstdigit
    call WinceMappingScan()
endfunction

" These two mappings contain <plug>, so the user will never invoke them.
" They both start with <plug>WinMappingParse, so they are ambiguous.
" WinceMappingScan exploits Vim's behaviour with ambiguous mappings - more on
" this below
map <silent> <plug>WinMappingParse :call WinceMappingScan()<cr>
map <silent> <plug>WinMappingParse<plug> <nop>

" This function scans for (and records) new characters typed by the user
" and checks if the user is partway through typing one of
" <c-w>{nr}{cmd} or z{nr}<cr>.
"
" If the user is partway through typing such a command, it uses feedkeys() to
" setup an invocation of the first of the ambiguous mappings above. Vim will
" wait a while due to the ambiguity (during which characters can be typed by
" the user) and then run the mapping which calls this function again. So the
" function runs over and over reading one character at a time.
"
" If the user is not partway through typing such a command (either because
" they've finished typing it or because they typed a character that isn't in
" the command), stop feedkeys'ing the ambiguous mapping and pass the
" characters typed so far to s:RunInfixCmd.
function! WinceMappingScan()
    " If no characters at all have been typed, something is wrong.
    if empty(s:sofar)
        throw 'WinceMappingScan() on empty s:sofar'
    endif

    " If no characters are available now, setup another call.
    if !getchar(1)
        call EchomLog('wince-mappings', 'verbose', 'WinceMappingScan sees no new characters')
        call WinceStateRestoreMode()
        call feedkeys("\<plug>WinMappingParse")
        return
    endif

    " A character is available. Read it.
    let s:sofar .= nr2char(getchar())
    call EchomLog('wince-mappings', 'debug', 'WinceMappingScan captured ', s:sofar)
    " If it was a number, setup another call because there may be more
    " characters
    if s:sofar[1:] =~# '^\d*$'
        call EchomLog('wince-mappings', 'debug', 'Not finished scanning yet')
        call WinceStateRestoreMode()
        call feedkeys("\<plug>WinMappingParse")
        return
    endif

    " It wasn't a number. We're done.
    call s:RunInfixCmd(s:sofar)

    " Clear the read characters for next time
    let s:sofar = ''
endfunction

" Given a command with an infixed count, use feedkeys to run it but with the
" count prefixed instead of infixed. If there is a non-hacky mapping that uses
" v:count, it will be triggered.
function! s:RunInfixCmd(cmd)
    if index(["\<c-w>", 'z'], a:cmd[0]) <# 0
        throw 's:RunInfixCmd on invalid command ' . a:cmd
    endif
    call EchomLog('wince-mappings', 'info', 'RunInfixCmd ', a:cmd, ' -> ', a:cmd[1:-2], a:cmd[0], a:cmd[-1:-1])
    call WinceStateRestoreMode()
    call feedkeys(a:cmd[1:-2] . a:cmd[0] . a:cmd[-1:-1])
endfunction

" The tower of hacks ends here

" Command mappings
let s:allCmds = {
\   'WinceOnly':                      ['<c-w>o','<c-w><c-o>'    ],
\   'WinceDecreaseHeight':            ['<c-w>-'                 ],
\   'WinceDecreaseWidth':             ['<c-w><'                 ],
\   'WinceEqualize':                  ['<c-w>='                 ],
\   'WinceExchange':                  ['<c-w>x','<c-w><c-x>'    ],
\   'WinceGoDown':                    ['<c-w>j','<c-w><down>'   ],
\   'WinceGoFirst':                   ['<c-w>t','<c-w><c-t>'    ],
\   'WinceGoLast':                    ['<c-w>b','<c-w><c-b>'    ],
\   'WinceGoLeft':                    ['<c-w>h','<c-w><left>'   ],
\   'WinceGoNext':                    ['<c-w>w','<c-w><c-w>'    ],
\   'WinceGoRight':                   ['<c-w>l','<c-w><right>'  ],
\   'WinceGoUp':                      ['<c-w>k','<c-w><up>'     ],
\   'WinceGotoPrevious':              ['<c-w>p','<c-w><c-p>'    ],
\   'WinceIncreaseHeight':            ['<c-w>+'                 ],
\   'WinceIncreaseWidth':             ['<c-w>>'                 ],
\   'WinceMoveToBottomEdge':          ['<c-w>J'                 ],
\   'WinceMoveToLeftEdge':            ['<c-w>H'                 ],
\   'WinceMoveToNewTab':              ['<c-w>T'                 ],
\   'WinceMoveToRightEdge':           ['<c-w>L'                 ],
\   'WinceMoveToTopEdge':             ['<c-w>K'                 ],
\   'WinceResizeHorizontal':          ['<c-w>_','<c-w><c-_>'    ],
\   'WinceResizeHorizontalDefaultNop':['z<cr>'                  ],
\   'WinceResizeVertical':            ['<c-w>\|'                ],
\   'WinceReverseGoNext':             ['<c-w>W'                 ],
\   'WinceReverseRotate':             ['<c-w>R'                 ],
\   'WinceRotate':                    ['<c-w>r','<c-w><c-r>'    ],
\   'WinceSplitHorizontal':           ['<c-w>s','<c-w>S','<c-s>'],
\   'WinceSplitVertical':             ['<c-w>v','<c-w><c-v>'    ],
\   'WinceSplitNew':                  ['<c-w>n','<c-w><c-n>'    ],
\   'WinceSplitAlternate':            ['<c-w>^','<c-w><c-^>'    ],
\   'WinceQuit':                      ['<c-w>q','<c-w><c-q>'    ],
\   'WinceClose':                     ['<c-w>c'                 ],
\   'WinceGotoPreview':               ['<c-w>P'                 ],
\   'WinceSplitTag':                  ['<c-w>]','<c-w><c-]>'    ],
\   'WinceSplitTagSelect':            ['<c-w>g]',               ],
\   'WinceSplitTagJump':              ['<c-w>g<c-]>',           ],
\   'WinceSplitFilename':             ['<c-w>f','<c-w><c-f>'    ],
\   'WinceSplitFilenameLine':         ['<c-w>F',                ],
\   'WincePreviewClose':              ['<c-w>z','<c-w><c-z>'    ],
\   'WincePreviewTag':                ['<c-w>}'                 ],
\   'WincePreviewTagJump':            ['<c-w>g}'                ],
\   'WinceSplitSearchWord':           ['<c-w>i','<c-w><c-i>'    ],
\   'WinceSplitSearchMacro':          ['<c-w>d','<c-w><c-d>'    ]
\}

let s:cmdsWithAllow0 = [
\   'WinceExchange',
\   'WinceGotoPrevious',
\   'WinceResizeHorizontal',
\   'WinceResizeVertical'
\]


let s:cmdsWithNormalModeMapping = keys(s:allCmds)
let s:cmdsWithVisualModeMapping = keys(s:allCmds)
" This matches Vim's native behaviour. Sticks out like a sore thumb, dooesn't
" it?
let s:cmdsWithSelectModeMapping = ['WinceResizeHorizontalDefuaultNop']
let s:cmdsWithTerminalModeMapping = keys(s:allCmds)

for cmdname in keys(s:allCmds)
    call WinceMappingMapCmd(
   \    s:allCmds[cmdname], cmdname,
   \    index(s:cmdsWithAllow0,              cmdname) >=# 0,
   \    index(s:cmdsWithNormalModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithVisualModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithSelectModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithTerminalModeMapping, cmdname) >=# 0
   \)
endfor

" Special case: WinceGoLeft needs to be mapped to <bs>, but not in terminal mode
call WinceMappingMapCmd(['<bs>'], 'WinceGoLeft', 0, 1, 1, 1, 0)

