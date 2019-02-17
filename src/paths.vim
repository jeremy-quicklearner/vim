" Changes to default file paths. No polluting the filesystem!

" From this script, go two levels up (to the repo root) and then down into tmp
let s:tmp = expand('<sfile>:p:h:h') . "/tmp"

" Regex matching the default path for user-specific Vim stuff
let s:default = $HOME . "/\\.vim"

" User-specific temporary Vim stuff will be in the new directory, so look there
" instead of the default
let &runtimepath = substitute(&runtimepath, s:default, s:tmp, "g")

" Put the viminfo file in the new directory
let &viminfo = &viminfo . ",n" . s:tmp . "/viminfo"

" Put backups in the new directory
let &backupdir = s:tmp . "/backup/"

" Put swap files in the new directory
let &directory = s:tmp . "/swap/"

" Put the undo history in the new directory
let &undodir = s:tmp . "/undo/"
