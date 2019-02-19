" Changes to default file paths. No polluting the filesystem!

" From this script, go two levels up to reach the repo root
let s:newVimDir = expand('<sfile>:p:h:h')

" Regex matching the default path for user-specific Vim stuff
let s:oldVimDir = $HOME . '/\.vim.\{-},'

" Subdirectories of the repo root
let s:after = s:newVimDir . '/src/after'
let s:tmp = s:newVimDir . '/tmp'
let s:ext = s:newVimDir . '/ext'

" Add the external stuff directory to the runtimepath
let &runtimepath = s:ext . ',' . &runtimepath

" Add the custom after directory to the runtimepath
let &runtimepath .= ',' . s:after

" Remove the default path from the runtimepath
let &runtimepath = substitute(&runtimepath, s:oldVimDir, '', 'g')

" Put the viminfo file in the new tmp directory
let &viminfo = &viminfo . ",n" . s:tmp . "/viminfo"

" Put backups in the new tmp directory
let &backupdir = s:tmp . "/backup"

" Put swap files in the new tmp directory
let &directory = s:tmp . "/swap"

" Put the undo history in the new tmp directory
let &undodir = s:tmp . "/undo"
