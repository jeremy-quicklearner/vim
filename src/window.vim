" Window manipulation

" This infrastructure is here because I want to make sure groups of related
" windows (such as windows and their location windows) stay together, and
" because I want to keep some windows at the edges of the screen at all times
" (like the quickfix window). To these ends, I introduce some terms:
"     - Uberwin (Uberwindow): A window that is always against the edge of the
"       screen and whose content is either tab-specific or global, like the
"       quickfix window. Uberwins are operated on in groups.
"     - Supwin (Superwindow): The standard kind of window
"     - Subwin (Subwindow): A window that is slaved to a supwin. Subwins are
"       allowed to exist only when their supwins exist, and move around
"       together with their supwins. Subwins are operated on in groups.
" 
" For additional flexibility, uberwins and subwins can be 'hidden'
" by closing them while internally accounting for their existence in a hidden
" state.
" Sometimes, as is the case with the Undotree plugin, content is associated
" with specific windows/buffers (and therefore should be in subwins) but only
" the content for one window/buffer can be displayed at any given time. This
" is mitigated with afterimaging. If a subwin group is designated as
" afterimaging, the contents of its subwins are 'afterimaged' - replaced with
" visually identical (but inert) copies called afterimages - whenever the user
" leaves the supwin of that subwin group
"
" Architecturally, the window engine has four components
"     - The State - meaning the state of Vim's window tiling
"     - The Model, internal to the scripts. Script- and Tab-local data
"       structures that represent the *intended* state with concepts
"       like supwins, subwins, and uberwins. At any time, the model may be
"       consistent or inconsistent with the the state. But it is always
"       internally consistent.
"     - The Resolve function, which runs on CursorHold events and makes the
"       state and model consistent
"     - The User Operations - Commands and Mappings to manipulate the model
"       and state while preserving their consistency. May reuse portions of
"       the Resolve function

" Model
source <sfile>:p:h/window-model.vim
" State
source <sfile>:p:h/window-state.vim
" Resolve function
source <sfile>:p:h/window-resolve.vim
" User Operations
source <sfile>:p:h/window-user.vim

" Bootstrap code
function! s:InitTab()
    call WinModelInit()
    call RegisterCursorHoldCallback(function('WinResolve'), [], 1, 0, 1)
endfunction

augroup Subwindow
    autocmd!
    " Every tab must be initialized
    autocmd VimEnter,TabNew * call s:InitTab()
augroup END
