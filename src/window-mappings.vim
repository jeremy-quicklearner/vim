" Window operation mappings
" See window.vim
" This file remaps every Vim Ctrl-W command that doesn't play well with the
" window engine to one of the custom commands from window-commands.vim

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

" Process v:count and v:count1 into a single count
function! WinMappingProcessCounts(allow0)
    " v:count and v:count1 default to different values when no count is
    " provided
    if v:count !=# v:count1
        return ''
    endif

    if !a:allow0 && v:count <= 0
        return 1
    endif

    return v:count
endfunction

" Map a command of the form <c-w><cmd> to run an Ex command with a count
function! s:DefineMappings(cmd, exCmd, allow0, mapinnormalmode, mapinvisualmode, mapinterminalmode)
    if a:mapinnormalmode
        execute 'nnoremap <silent> <c-w>' . a:cmd . ' :<c-u>execute WinMappingProcessCounts(' . a:allow0 . ') . "' . a:exCmd . '"<cr>'
    endif
    if a:mapinvisualmode
        execute 'vnoremap <silent> <c-w>' . a:cmd . ' :<c-u>execute WinMappingProcessCounts(' . a:allow0 . ') . "' . a:exCmd . '"<cr>'
    endif
    if a:mapinterminalmode
        execute 'tnoremap <silent> <c-w>' . a:cmd . ' <c-w>:<c-u>execute WinMappingProcessCounts(' . a:allow0 . ') . "' . a:exCmd . '"<cr>'
    endif
endfunction

" Create an Ex command and mappings that run a Ctrl-W command with flags
function! WinMappingMapCmd(cmds, exCmdName, allow0,
                         \ mapinnormalmode, mapinvisualmode,
                         \ mapinterminalmode)
    for cmd in a:cmds
        call s:DefineMappings(cmd, a:exCmdName, a:allow0, a:mapinnormalmode, a:mapinvisualmode, a:mapinterminalmode)
    endfor
endfunction

" This tower of hacks maps <c-w>{nr}{cmd} to {nr}<c-w>{cmd} and z{nr}<cr>
" to {nr}z<cr>. This can't be done with v:count because {nr} doesn't come first.
" We must parse the characters ourselves.

" These top-level mappings are just on the first character and first digit of
" {nr}. 0 Is ommitted because Vim's default behaviour on <c-w>0 and z0 is
" already a nop
for idx in range(1,9)
    execute 'nnoremap <silent> <c-w>' . idx . ' :call WinMappingScanW(' . idx . ')<cr>'
    execute 'vnoremap <silent> <c-w>' . idx . ' :<c-u>call WinMappingScanW(' . idx . ')<cr>'
    execute 'nnoremap <silent> z' . idx . ' :call WinMappingScanZ(' . idx . ')<cr>'
    execute 'vnoremap <silent> z' . idx . ' :<c-u>call WinMappingScanZ(' . idx . ')<cr>'
endfor

" Tracks the characters typed so far
let s:sofar = ''

" These functions call WinMappingScan() which will read more characters.
function! WinMappingScanW(firstdigit)
    let s:sofar = "\<c-w>" . a:firstdigit
    call WinMappingScan()
endfunction
function! WinMappingScanZ(firstdigit)
    let s:sofar = "z" . a:firstdigit
    call WinMappingScan()
endfunction

" These two mappings contain <plug>, so the user will never invoke them.
" They both start with <plug>WinMappingParse, so they are ambiguous.
" WinMappingScan exploits Vim's behaviour with ambiguous mappings.
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
        call feedkeys("\<plug>WinMappingParse")
        return
    endif

    " A character is available. Read it.
    let s:sofar .= nr2char(getchar())
    
    " If it was a number, setup another call because there may be more
    " characters
    if s:sofar[1:] =~# '^\d*$'
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
" v:count, it will be triggered. Otherwise the top-level mappings will be
" triggered. 
function! s:RunInfixCmd(cmd)
    if index(["\<c-w>", 'z'], a:cmd[0]) <# 0
        throw 's:RunInfixCmd on invalid command ' . a:cmd
    endif
    call feedkeys(a:cmd[1:-2] . a:cmd[0] . a:cmd[-1:-1])
endfunction

" The tower of hacks ends here

" Command mappings
" Window commands that aren't in this list will not be remapped
let s:allCmds = {
\   'WinOnly':            ['o','<c-o>'                ],
\   'WinDecreaseHeight':  ['-'                        ],
\   'WinDecreaseWidth':   ['<'                        ],
\   'WinEqualize':        ['='                        ],
\   'WinExchange':        ['x','<c-x>'                ],
\   'WinGoDown':          ['j','<down>','<c-j>'       ],       
\   'WinGoFirst':         ['t'                        ],
\   'WinGoLast':          ['b'                        ],
\   'WinGoLeft':          ['h','<left>','<c-h>','<bs>'],
\   'WinGoNext':          ['w','<c-w>'                ],
\   'WinGoRight':         ['l','<right>','<c-l>'      ],      
\   'WinGoUp':            ['k','<up>','<c-k>'         ],         
\   'WinGotoPrevious':    ['p','<c-p>'                ],
\   'WinIncreaseHeight':  ['+'                        ],
\   'WinIncreaseWidth':   ['>'                        ],
\   'WinMoveToBottomEdge':['J'                        ],
\   'WinMoveToLeftEdge':  ['H'                        ],
\   'WinMoveToNewTab':    ['T'                        ],
\   'WinMoveToRightEdge': ['L'                        ],
\   'WinMoveToTopEdge':   ['K'                        ],
\   'WinResizeHorizontal':['_'                        ],                        
\   'WinResizeVertical':  ['\|'                       ],                       
\   'WinReverseGoNext':   ['W'                        ],
\   'WinReverseRotate':   ['R'                        ],
\   'WinRotate':          ['r','<c-r>'                ]
\}

let s:cmdsWithAllow0 = [
\   'WinExchange',
\   'WinGotoPrevious',
\   'WinResizeHorizontal',
\   'WinResizeVertical',
\]

" {nr}z<cr> is a special case because it doesn't start with <c-w>
nnoremap <silent> z<cr> :<c-u>execute WinMappingProcessCounts(1) . 'WinResizeHorizontal'<cr>
vnoremap <silent> z<cr> :<c-u>execute WinMappingProcessCounts(1) . 'WinResizeHorizontal'<cr>


let s:cmdsWithNormalModeMapping = keys(s:allCmds)
let s:cmdsWithVisualModeMapping = keys(s:allCmds)
let s:cmdsWithTerminalModeMapping = keys(s:allCmds)

for cmdname in keys(s:allCmds)
    call WinMappingMapCmd(
   \    s:allCmds[cmdname], cmdname,
   \    index(s:cmdsWithAllow0,              cmdname) >=# 0,
   \    index(s:cmdsWithNormalModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithVisualModeMapping,   cmdname) >=# 0,
   \    index(s:cmdsWithTerminalModeMapping, cmdname) >=# 0
   \)
endfor
