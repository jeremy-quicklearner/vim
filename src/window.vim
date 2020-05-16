" Window manipulation
" 
" Vim does not natively enforce any correlation between the purpose of a
" window and its position, or between the position of a window and the positions
" of its related windows. A window can exist at the far left, with its
" location window on the far right and six other windows inbetween. A quickfix
" window can be in any position, and so easily mistaken for a location window.
" This infrastructure's main purpose is to enforce such correlations. A window's
" location window is only ever directly below. The quickfix window is only
" ever at the bottom of the screen.
"
" The primary design goal is extensibility: incorporation of new types of
" windows must be easy, especially ones added by plugins (like the undotree and
" undodiff windows from mbbill/undotree). Therefore there needs to be a scheme
" for classification of windows into categories more general than 'the quickfix
" window' or 'the location window for window X'. Constraints on windows are
" enforced according to the window's category.
" The categories are:
"     - Supwin (Superwindow): The standard kind of window
"     - Subwin (Subwindow): A window that is slaved to a supwin, like a
"       location window. Subwins are allowed to exist only when their supwins exist,
"       and move around together with their supwins
"     - Uberwin (Uberwindow): A window that is always against the edge of the
"       screen and whose content is either tab-specific or Vim-global, like the
"       quickfix window
"
" Since some types of windows appear and disappear together (such as the undotree
" and undodiff windows from the mbbill/undotree plugin), uberwins and subwins
" are managed in groups.
" 
" For additional flexibility, uberwin and subwin groups can be 'hidden'
" by closing them while internally accounting for their existence, ready to be
" restored ('shown') at any time. For instance, if a supwin has a location
" list but its location window isn't open. Then we say the loclist subwin
" group for that supwin is hidden.
" 
" Sometimes, as is the case with the mbbill/undotree plugin, content in auxilliary
" windows is associated with specific supwins/buffers but only the content for one
" of those windows/buffers can be displayed at any given time. This infrastructure
" mitigates that problem with a feature called afterimaging, which gives the user
" the impression that the content in a subwin is being displayed
" simultaneously for multiple supwins. If a subwin is designated as afterimaging,
" the contents of its subwins are 'afterimaged' - replaced with visually identical
" (but inert) copies called afterimages - whenever the user leaves the supwin of
" that subwin. At any given time, no more than one supwin may have a non-afterimaged
" subwin of that group. So really, the user is looking at what amounts to one real
" subwin and multiple cardboard cutouts of subwins.
"
" These are the infrastructure's architectural components:
"     1 The State - meaning the state of Vim's window tiling
"     2 The Model - a collection of Vim-Global, Script-local and Tab-local data
"       structures that represent the *intended* state of the window tiling in
"       terms of supwins, subwins, and uberwins. At any time, the model may be
"       consistent or inconsistent with the the state. But it is always
"       internally consistent.
"     3 The User Operations - A collection of functions that manipulate the model
"       and state under the assumption that they are already consistent with each
"       other
"     4 The Mappings - Exactly what it sounds like - a collection of mappings
"       and custom commands that replace native Vim commands with calls to
"       User Operations.
"
" If the State were to be mutated by *only* the user operations, it would
" always be consistent with the model. Alas, that is not an assumption we can
" make. All it takes to ruin the consistency is a single invocation of 'wincmd r'
" in a plugin. That's why there's a fifth component:
"
"     5 The Resolver - an algorithm which runs on the CursorHold autocmd event and
"       guarantees on completion that the model and state are consistent with
"       each other, even if they were inconsistent when the resolver started
"
" In short, the user interacts with the state and model by means of mappings
" and custom commands that call user operations, which keep the state and
" model consistent. If anything goes wrong and the state and model become
" inconsistent, the resolver will quickly swoop in and fix the inconsistency
" anyway. If updatetime is set to a small enough value, the inconsistency is
" visible only for a split second.
"
" Consumers of this system are definitions of uberwin and subwin group types
" (i.e. calls to the WinAddUberwinGroupType and WinAddSubwinGroupType user
" operations).
" 
" TODO? Preserve folds, signs, etc. when subwins and uberwins are hidden. Not
"       sure if this is desirable - would they still be restored after
"       location list contents change? Would different blobs of persisted
"       state be stored for each location list? Maybe just leave it as the
"       responsibility of files like loclist.vim and undotree.vim:w
" TODO: Make the Help window an uberwin
" TODO: Make the Option window an uberwin
" TODO: Make the Command-line window an uberwin
" TODO: Fix sessions
" TODO: Audit instances of echohl | echo and consider changing them to echom
" TODO: Audit all the user operations and common code for direct accesses to
"       the state and model
" TODO: Audit all the user operations for redundancy
" TODO: Audit all the asserts for redundancy
" TODO: Audit all files for lines longer than 80 characters
" TODO: Audit all files for 'endfunction!'
" TODO: Move the CursorHold callback infrastructure to a plugin
" TODO: Move the whole window engine to a plugin
" TODO: Autoload everything
" TODO: Move subwin and uberwin group definitions to their own plugins

" Model
source <sfile>:p:h/window-model.vim
" State
source <sfile>:p:h/window-state.vim
" Code common to the Resolver and User Operations
source <sfile>:p:h/window-common.vim
" Resolver
source <sfile>:p:h/window-resolve.vim
" User Operations
source <sfile>:p:h/window-user.vim
" Mappings
source <sfile>:p:h/window-mappings.vim

" Set up the window engine for a tab
function! s:InitTab()
    " The resolver should run after any changes to the state
    call RegisterCursorHoldCallback(function('WinResolve'), [], 1, 0, 1)

    " Also run the resolver immediately
    let t:winresolvetabenteredcond = 1
    call WinResolve([])
endfunction

" Every tab must be initialized
augroup Window
    autocmd!
    autocmd VimEnter,TabNew * call s:InitTab()
augroup END

" Don't equalize window sizes when windows are closed
set noequalalways
