" Overwriting syntax for the Undotree plugin

" The undotree plugin's syntax file is all hardcoded, and based on some
" default values that I change in src/undotree.vim. Rewrite those syntax
" objects.
syntax match UndotreeNode ' \zsO\ze '
syntax match UndotreeNodeCurrent '\zsO\ze.*>\d\+<'
syntax match UndotreeTimeStamp conceal '(.*)$'
syntax match UndotreeFirstNode '(Orig)'
syntax match UndotreeBranch '[|/\\]'
syntax match UndotreeSeq ' \zs\d\+\ze '
syntax match UndotreeCurrent '>\d\+<'
syntax match UndotreeNext '{\d\+}'
syntax match UndotreeHead '\[\d\+]'
syntax match UndotreeHelp '^".*$' contains=UndotreeHelpKey,UndotreeHelpTitle
syntax match UndotreeHelpKey '^" \zs.\{-}\ze:' contained
syntax match UndotreeHelpTitle '===.*===' contained
syntax match UndotreeSavedSmall ' \zss\ze '
syntax match UndotreeSavedBig ' \zsS\ze '

" I disagree with some of the choices of highlight groups. Relink them to
" custom ones so I can change them by colour scheme
highlight link UndotreeNode        JUTNode
highlight link UndotreeNode        JUTNode
highlight link UndotreeNodeCurrent JUTNodeCurrent
highlight link UndotreeTimeStamp   JUTTimeStamp
highlight link UndotreeFirstNode   JUTFirstNode
highlight link UndotreeBranch      JUTBranch
highlight link UndotreeSeq         JUTSeq
highlight link UndotreeCurrent     JUTCurrent
highlight link UndotreeNext        JUTNext
highlight link UndotreeHead        JUTHead
highlight link UndotreeHelp        JUTHelp
highlight link UndotreeHelpKey     JUTHelpKey
highlight link UndotreeHelpTitle   JUTHelpTitle
highlight link UndotreeSavedSmall  JUTSavedSmall
highlight link UndotreeSavedBig    JUTSavedBig
