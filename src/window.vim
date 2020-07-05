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
"     4 The Commands - A collection of custom commands that make calls to the
"       user operations
"     5 The Mappings - A collection of mappings that replace native Vim window
"       operations with invocations of the custom commands
"
" If the State were to be mutated by *only* the user operations, it would
" always be consistent with the model. Alas, that is not an assumption we can
" make. All it takes to ruin the consistency is a single invocation of 'wincmd r'
" in a plugin. That's why there's a sixth component:
"
"     6 The Resolver - an algorithm which runs on the CursorHold autocmd event and
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
" The mappings may interact in unwelcome ways with other scripts, so they are
" optional. If they are enabled, they have some minor side effects such as:
"  - All window commands, even ones cancelled partway through with <esc> or
"    <c-c>, kick you out of visual mode
"    TODO? Fix
"  - z<cr>, which does nothing natively, is now equivalent to <c-w>_
"    TODO? Fix
"
" TODO: Fix sessions. Start by removing all dependencies on Vim 8 winids
" TODO? Preserve folds, signs, etc. when subwins and uberwins are hidden. Not
"       sure if this is desirable - would they still be restored after
"       location list contents change? Would different blobs of persisted
"       state be stored for each location list? Maybe just leave it as the
"       responsibility of files like loclist.vim and undotree.vim:w
" TODO? Figure out why folds keep appearing in the help window on
"       WinShowUberwin. Haven't seen this happen in some time - maybe it's
"       fixed?
" TODO? Add lots of info-level and config-level logging to the user operations
" TODO? Add lots of debug-level logging to the resolver
" TODO? Add lots of verbose-level logging to the common code
"
" TODO: Run the resolver on WinResize
" TODO: Add an uberwin to show the j_log
" TODO: Make the Option window an uberwin
" TODO: Think of a way to avoid creating a new buffer every time a subwin is
"       afterimaged
" TODO: Make the Command-line window an uberwin?
" TODO: Actually make the mappings optional
" TODO? Figure out why terminal windows keep breaking the resolver and
"       statuslines
"       - It's got to do with an internal bug in Vim. Maybe it can be
"         mitigated?
"       - The internal error is caught now, but it seems to add ranges to
"         a bunch of commands that run after it gets caught
"       - All the statuslines and tabline get cleared
" TODO: Audit all the user operations and common code for direct accesses to
"       the state and model
" TODO: Audit the common code for functions that are not common to the
"       resolver and user operations
" TODO: Audit all the user operations for redundancy
" TODO: Audit all the asserts for redundancy
" TODO: Audit all files for lines longer than 80 characters
" TODO: Audit all files for 'endfunction!'
" TODO: Move the CursorHold callback infrastructure to a plugin
" TODO: Move the whole window engine to a plugin
" TODO: Autoload everything
" TODO: Move subwin and uberwin group definitions to their own plugins

" Logging facilities - all in one place so they can be changed easily
call SetLogLevel('window-mappings', 'info', 'warning')
call SetLogLevel('window-commands', 'info', 'warning')
call SetLogLevel('window-user',     'info', 'warning')
call SetLogLevel('window-resolve',  'info', 'warning')
call SetLogLevel('window-common',   'info', 'warning')
call SetLogLevel('window-model',    'info', 'warning')
call SetLogLevel('window-state',    'info', 'warning')

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
" Commands
source <sfile>:p:h/window-commands.vim
" Mappings
source <sfile>:p:h/window-mappings.vim

" Run the resolver whenever a tab is created
function! s:InitTab()
    let t:winresolvetabenteredcond = 1
    call WinResolve([])
endfunction

" Every tab must be initialized
augroup Window
    autocmd!
    autocmd VimEnter,TabNew * call s:InitTab()
augroup END

" The resolver should run after any changes to the state
if !exists('g:j_winresolve_chc')
    let g:j_winresolve_chc = 1
    call RegisterCursorHoldCallback(function('WinResolve'), [], 0, 0, 1, 1)
endif

" Don't equalize window sizes when windows are closed
set noequalalways
