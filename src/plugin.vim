" Plugin management

" External stuff directory
let s:vimDir = expand('<sfile>:p:h:h')
let s:extDir = s:vimDir . '/ext'
let s:plugScriptName = s:extDir . '/autoload/plug.vim'

" Make sure Vim-Plug is installed
" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
if empty(glob(s:extDir . '/autoload/plug.vim'))
    execute 'silent !curl -fLo ' . s:plugScriptName . ' --create-dirs ' .
                \ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

" Install any missing plugins
" https://github.com/junegunn/vim-plug/wiki/extra#automatically-install-missing-plugins-on-startup
autocmd VimEnter *
            \  if !empty(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
            \|     PlugInstall --sync
            \| endif

" Plugin selection
let s:google_plugins = 1
" Maktaba hits issues with funcrefs between these two versions
if has('patch-7.4.1577') && !has('patch-7.4.1607')
    let s:google_plugins = 0
endif
" Maktaba's JSON encoding is broken between these two versions
if has('patch-7.4.1434') && !has('patch-7.4.1445')
    let s:google_plugins = 0
endif
" Maktaba uses "is/isnot" keyword that's broken in this version
if has('patch-8.2.0044') && !has('patch-8.2.0045')
    let s:google_plugins = 0
endif

" Load plugins
call plug#begin()
Plug 'justinmk/vim-syntax-extra'
Plug 'benknoble/vim-auto-origami'
Plug 'mbbill/undotree'
Plug 'tpope/vim-fugitive'
Plug 'wellle/context.vim'
Plug 'jeremy-quicklearner/vim-jersuite-core'
Plug 'jeremy-quicklearner/vim-wince'
Plug 'jeremy-quicklearner/vim-wince-undotree'
Plug 'jeremy-quicklearner/vim-sign-utils'

" Minimum supported version
if has('patch-8.1.2269')
    Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
endif


if s:google_plugins
    Plug 'google/vim-maktaba'
    Plug 'google/vim-codefmt'
    Plug 'google/vim-glaive'
endif

for extraplugin in g:jeremyExtraPlugins
    Plug extraplugin
endfor
call plug#end()

" Netrw stuff
" Vertically open windows on the right
let g:netrw_altv=1
let g:netrw_preview=1
" Buffer settings: nu and rnu mean numbers and relative numbers
let g:netrw_bufsettings="noma nomod nu rnu nobl nowrap ro"
" Tree view
let g:netrw_liststyle=3

" Auto Origami stuff
let g:auto_origami_foldcolumn=1
augroup AutoOrigami
    autocmd!
    if exists('##SafeStateAgain') && exists('*state')
        autocmd SafeState,BufWinEnter,WinEnter *
                    \  if exists('v:false') && 
                    \     exists('g:loaded_auto_origami') &&
                    \     &buftype !=# 'terminal'
                    \|     execute('AutoOrigamiFoldColumn')
                    \| endif
    else
       autocmd CursorHold,BufWinEnter,WinEnter *
                    \  if exists('v:false') &&
                    \     exists('g:loaded_auto_origami') &&
                    \     &buftype !=# 'terminal'
                    \|     execute('AutoOrigamiFoldColumn')
                    \| endif
    endif
augroup END

" vim-go stuff
let go_list_height = 10
autocmd FileType go nnoremap <c-[> :GoCallers<cr>

" Vim Sign Utils stuff
" Place a sign on the current line
nnoremap <silent> <leader>sr :PlaceUtilSigns Red<cr>
nnoremap <silent> <leader>sg :PlaceUtilSigns Green<cr>
nnoremap <silent> <leader>sy :PlaceUtilSigns Yellow<cr>
nnoremap <silent> <leader>sb :PlaceUtilSigns Blue<cr>
nnoremap <silent> <leader>sm :PlaceUtilSigns Magenta<cr>
nnoremap <silent> <leader>sc :PlaceUtilSigns Cyan<cr>
nnoremap <silent> <leader>sw :PlaceUtilSigns White<cr>
" Place signs on highlighted lines
vnoremap <silent> <leader>sr :PlaceUtilSigns Red<cr>
vnoremap <silent> <leader>sg :PlaceUtilSigns Green<cr>
vnoremap <silent> <leader>sy :PlaceUtilSigns Yellow<cr>
vnoremap <silent> <leader>sb :PlaceUtilSigns Blue<cr>
vnoremap <silent> <leader>sm :PlaceUtilSigns Magenta<cr>
vnoremap <silent> <leader>sc :PlaceUtilSigns Cyan<cr>
vnoremap <silent> <leader>sw :PlaceUtilSigns White<cr>
" Remove signs from the current line
nnoremap <silent> <leader>S :UnplaceUtilSigns<cr>
" Remove signs from highlighted lines
vnoremap <silent> <leader>S :UnplaceUtilSigns<cr>

" context.vim stuff
let g:context_border_char = '='
let g:context_skip_regex = '^\([<=>]\{7\}\|\s*\($\|\h\S\+\s*:\(\s*$\|\s\+\)\|#\|//\|/\*\|\*\($\|\s\|/\)\)\)'
" Jersuite-core stuff
" Use experimental SafeState feature
let g:jersuite_forcecursorholdforpostevent = 0

" Wince stuff
let g:wince_enable_help = 1
let g:wince_enable_preview = 1
let g:wince_enable_option = 1
if v:version >=# 800 && (!exists('g:jersuite_forcelegacywinid') ||
                       \ !g:jersuite_forcelegacywinid)
    let g:wince_enable_quickfix = 1
    let g:wince_enable_loclist = 1
endif
let g:wince_disable_mappings = 0
let g:wince_disabled_mappings = {}

" Undotree stuff
" TODO: Figure out why opening the undotree with UndotreeOpen doesn't set
" &number
let g:undotree_ShortIndicators = 1
let g:undotree_HelpLine = 0
let g:undotree_TreeNodeShape = 'O'

