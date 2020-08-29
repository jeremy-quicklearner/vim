" Window operation mappings
" See window.vim
" This file remaps every Vim Ctrl-W command that doesn't play well with the
" window engine to one of the custom commands from window-commands.vim

" TODO: Ensure all mappings behave similarly to their native counterparts when
"       invoked from visual mode
" TODO: Thoroughly test every mapping

" This function is a helper for group definitions which want to define
" mappings for adding, removing, showing, hiding, and jumping to their groups
function! WinMappingMapUserOp(lhs, rhs)
    call EchomLog('window-mappings', 'config', 'Map ', a:lhs, ' to ', a:rhs)
    execute 'nnoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinStateDetectMode("n")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>'
    execute 'xnoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinStateDetectMode("v")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>'
    execute 'snoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinStateDetectMode("s")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>'
    execute 'tnoremap <silent> ' . a:lhs . ' <c-w>:<c-u>call WinStateDetectMode("t")<cr><c-w>:<c-u>' . a:rhs . '<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>'
endfunction

" Process v:count and v:count1 into a single count
function! WinMappingProcessCounts(allow0)
    call EchomLog('window-mappings', 'debug', 'WinMappingProcessCounts ' , a:allow0)
    " v:count and v:count1 default to different values when no count is
    " provided
    if v:count !=# v:count1
        call EchomLog('window-mappings', 'debug', 'Count not set')
        return ''
    endif

    if !a:allow0 && v:count <= 0
        call EchomLog('window-mappings', 'debug', 'Count 0 not allowed. Substituting 1.')
        return 1
    endif

    return v:count
endfunction

" Map a command of the form <c-w><cmd> to run an Ex command with a count
function! s:DefineMappings(cmd, exCmd, allow0, mapinnormalmode, mapinvisualmode, mapinselectmode, mapinterminalmode)
    call EchomLog('window-mappings', 'debug', 'DefineMappings ', a:cmd, ', ', a:exCmd, ', [', a:allow0, ',', a:mapinnormalmode, ',', a:mapinvisualmode, ',', a:mapinselectmode, ',', a:mapinterminalmode, ']')
    if a:mapinnormalmode
        execute 'nnoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinStateDetectMode(\"n\")<cr><c-w>:<c-u>execute " . WinMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>"'
    endif
    if a:mapinvisualmode
        execute 'xnoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinStateDetectMode(\"v\")<cr><c-w>:<c-u>execute " . WinMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>"'
    endif
    if a:mapinselectmode
        execute 'snoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinStateDetectMode(\"s\")<cr><c-w>:<c-u>execute " . WinMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>"'
    endif
    if a:mapinterminalmode
        execute 'tnoremap <expr> <silent> ' . a:cmd . ' "<c-w>:<c-u>call WinStateDetectMode(\"t\")<cr><c-w>:<c-u>execute " . WinMappingProcessCounts(' . a:allow0 . ') . "\"' . a:exCmd . '\"<cr><c-w>:<c-u>call WinStateRestoreMode()<cr>"'
    endif
endfunction

" Create an Ex command and mappings that run a Ctrl-W command with flags
function! WinMappingMapCmd(cmds, exCmdName, allow0,
                         \ mapinnormalmode, mapinvisualmode, mapinselectmode,
                         \ mapinterminalmode)
    call EchomLog('window-mappings', 'config', 'Map ', a:cmds, ' to ', a:exCmdName)
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
    execute 'nnoremap <silent> <c-w>' . idx . ' <c-w>:<c-u>call WinStateDetectMode("n")<cr><c-w>:<c-u>call WinMappingScanW(' . idx . ')<cr>'
    execute 'xnoremap <silent> <c-w>' . idx . ' <c-w>:<c-u>call WinStateDetectMode("v")<cr><c-w>:<c-u>call WinMappingScanW(' . idx . ')<cr>'
    " There is no snoremap for <c-w> because no <c-w> commands can be run from
    " select mode

    execute 'nnoremap <silent> z' . idx . ' <c-w>:<c-u>call WinStateDetectMode("n")<cr><c-w>:<c-u>call WinMappingScanZ(' . idx . ')<cr>'
    execute 'xnoremap <silent> z' . idx . ' <c-w>:<c-u>call WinStateDetectMode("v")<cr><c-w>:<c-u>call WinMappingScanZ(' . idx . ')<cr>'
    execute 'snoremap <silent> z' . idx . ' <c-w>:<c-u>call WinStateDetectMode("s")<cr><c-w>:<c-u>call WinMappingScanZ(' . idx . ')<cr>'
endfor

" Tracks the characters typed so far
let s:sofar = ''

" These functions call WinMappingScan() which will read more characters.
function! WinMappingScanW(firstdigit)
    call EchomLog('window-mappings', 'debug', 'WinMappingScanW ', a:firstdigit)
    let s:sofar = "\<c-w>" . a:firstdigit
    call WinMappingScan()
endfunction
function! WinMappingScanZ(firstdigit)
    call EchomLog('window-mappings', 'debug', 'WinMappingScanZ ', a:firstdigit)
    let s:sofar = "z" . a:firstdigit
    call WinMappingScan()
endfunction

" These two mappings contain <plug>, so the user will never invoke them.
" They both start with <plug>WinMappingParse, so they are ambiguous.
" WinMappingScan exploits Vim's behaviour with ambiguous mappings - more on
" this below
map <silent> <plug>WinMappingParse :call WinMappingScan()<cr>
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
function! WinMappingScan()
    " If no characters at all have been typed, something is wrong.
    if empty(s:sofar)
        throw 'WinMappingScan() on empty s:sofar'
    endif

    " If no characters are available now, setup another call.
    if !getchar(1)
        call EchomLog('window-mappings', 'verbose', 'WinMappingScan sees no new characters')
        call WinStateRestoreMode()
        call feedkeys("\<plug>WinMappingParse")
        return
    endif

    " A character is available. Read it.
    let s:sofar .= nr2char(getchar())
    call EchomLog('window-mappings', 'debug', 'WinMappingScan captured ', s:sofar)
    " If it was a number, setup another call because there may be more
    " characters
    if s:sofar[1:] =~# '^\d*$'
        call EchomLog('window-mappings', 'debug', 'Not finished scanning yet')
        call WinStateRestoreMode()
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
    call EchomLog('window-mappings', 'info', 'RunInfixCmd ', a:cmd, ' -> ', a:cmd[1:-2], a:cmd[0], a:cmd[-1:-1])
    call WinStateRestoreMode()
    call feedkeys(a:cmd[1:-2] . a:cmd[0] . a:cmd[-1:-1])
endfunction

" The tower of hacks ends here

" Command mappings
let s:allCmds = {
\   'WinOnly':                      ['<c-w>o','<c-w><c-o>'                ],
\   'WinDecreaseHeight':            ['<c-w>-'                             ],
\   'WinDecreaseWidth':             ['<c-w><'                             ],
\   'WinEqualize':                  ['<c-w>='                             ],
\   'WinExchange':                  ['<c-w>x','<c-w><c-x>'                ],
\   'WinGoDown':                    ['<c-w>j','<c-w><down>','<c-j>'       ],
\   'WinGoFirst':                   ['<c-w>t','<c-w><c-t>'                ],
\   'WinGoLast':                    ['<c-w>b','<c-w><c-b>'                ],
\   'WinGoLeft':                    ['<c-w>h','<c-w><left>','<c-h>','<bs>'],
\   'WinGoNext':                    ['<c-w>w','<c-w><c-w>'                ],
\   'WinGoRight':                   ['<c-w>l','<c-w><right>','<c-l>'      ],
\   'WinGoUp':                      ['<c-w>k','<c-w><up>','<c-k>'         ],
\   'WinGotoPrevious':              ['<c-w>p','<c-w><c-p>'                ],
\   'WinIncreaseHeight':            ['<c-w>+'                             ],
\   'WinIncreaseWidth':             ['<c-w>>'                             ],
\   'WinMoveToBottomEdge':          ['<c-w>J'                             ],
\   'WinMoveToLeftEdge':            ['<c-w>H'                             ],
\   'WinMoveToNewTab':              ['<c-w>T'                             ],
\   'WinMoveToRightEdge':           ['<c-w>L'                             ],
\   'WinMoveToTopEdge':             ['<c-w>K'                             ],
\   'WinResizeHorizontal':          ['<c-w>_','<c-w><c-_>'                ],
\   'WinResizeHorizontalDefaultNop':['z<cr>'                              ],
\   'WinResizeVertical':            ['<c-w>\|'                            ],
\   'WinReverseGoNext':             ['<c-w>W'                             ],
\   'WinReverseRotate':             ['<c-w>R'                             ],
\   'WinRotate':                    ['<c-w>r','<c-w><c-r>'                ],
\   'WinSplitHorizontal':           ['<c-w>s','<c-w>S','<c-s>'            ],
\   'WinSplitVertical':             ['<c-w>v','<c-w><c-v>'                ],
\   'WinSplitNew':                  ['<c-w>n','<c-w><c-n>'                ],
\   'WinSplitAlternate':            ['<c-w>^','<c-w><c-^>'                ],
\   'WinQuit':                      ['<c-w>q','<c-w><c-q>'                ],
\   'WinClose':                     ['<c-w>c'                             ],
\   'WinGotoPreview':               ['<c-w>P'                             ]
\}

let s:cmdsWithAllow0 = [
\   'WinExchange',
\   'WinGotoPrevious',
\   'WinResizeHorizontal',
\   'WinResizeVertical'
\]


let s:cmdsWithNormalModeMapping = keys(s:allCmds)
let s:cmdsWithVisualModeMapping = keys(s:allCmds)
" This matches Vim's native behaviour. Sticks out like a sore thumb, dooesn't
" it?
let s:cmdsWithSelectModeMapping = ['WinResizeHorizontalDefuaultNop']
let s:cmdsWithTerminalModeMapping = keys(s:allCmds)

for cmdname in keys(s:allCmds)
    call WinMappingMapCmd(
   \    s:allCmds[cmdname], cmdname,
   \    index(s:cmdsWithAllow0,              cmdname) >=# 0,
   \    index(s:cmdsWithNormalModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithVisualModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithSelectModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithTerminalModeMapping, cmdname) >=# 0
   \)
endfor
