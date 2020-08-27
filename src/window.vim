" Window manipulation
" 
" WHY?
"
" Vim does not natively enforce any correlation between the purpose of a
" window and its position, or between the position of a window and the positions
" of its related windows. A window can exist at the far left, with its
" location window on the far right and six other windows inbetween. A quickfix
" window can be in any position, and so easily mistaken for a location window.
" This infrastructure's main purpose is to enforce such correlations. A window's
" location window should only ever directly below. The quickfix window should only
" ever be at the bottom of the screen. And so on and so forth.
"
" CORE CONCEPTS
"
" The primary design goal is extensibility: incorporation of new types of
" windows must be easy, especially ones added by plugins (like the undotree and
" undodiff windows from mbbill/undotree). Therefore there needs to be a scheme
" for classification of windows into categories more general than 'the quickfix
" window' or 'a location window'. Constraints on windows can then be enforced
" agnostically, based only on the window's category.
" The categories used are:
"     - Supwin (Superwindow): The standard kind of window
"     - Subwin (Subwindow): A window that is slaved to a supwin, like a location
"                           window. Subwins are allowed to exist only when their
"                           supwins exist, and are always in the same position
"                           relative the position of their supwins
"     - Uberwin (Uberwindow): A window that is always against the edge of the
"                             screen and whose content is either tab-specific or
"                             session-global, like the quickfix window
"
" Since some types of windows appear and disappear together (such as the undotree
" and undodiff windows from the mbbill/undotree plugin), uberwins and subwins
" are managed in groups.
" An uberwin group is a collection of uberwins that are only ever
" opened and closed at the same time as each other. An uberwin group is associate
" with a single tab.
" Similarly, a subwin group is a collection of subwins that are only ever opened and
" closed at the same time as each other. A subwin group is associated with a single
" supwin.
" 
" FEATURES
"
" For additional flexibility, uberwin and subwin groups can be 'hidden'
" by closing them while still accounting for their existence in Vimscript data
" structures. A hidden uberwin or subwin group is ready to be restored ('shown') at
" any time. For instance, if a supwin has a location list but its location window
" isn't open. Then the reference definition of the location list subwin group
" for that supwin is hidden (see: loclist.vim)
" 
" Sometimes, as is the case with the mbbill/undotree plugin, content in windows is
" associated with specific supwins/buffers but only the content for one of those
" supwins/buffers can be displayed at any given time. This infrastructure mitigates
" that problem with a feature called afterimaging, which gives the user the
" impression that the content in a subwin is being displayed simultaneously for
" multiple supwins. If a subwin is designated as afterimaging, the contents of its
" subwins are 'afterimaged' - replaced with visually identical (but inert) copies
" called afterimages - whenever the user leaves the supwin of that subwin. At any
" given time, no more than one supwin may have a non-afterimaged subwin of that
" group. So really, the user is looking at what amounts to one real subwin and
" multiple cardboard cutouts of subwins.
"
" INTERNALS
"
" These are the infrastructure's architectural components:
"     1 The State - meaning the state of Vim's window tiling.
"     2 The Model - a collection of Vim-Global, Script-local and Tab-local data
"                   structures that represent the *intended* state of the window
"                   tiling in terms of supwins, subwins, and uberwins. At any time,
"                   the model may be consistent or inconsistent with the the state.
"                   But it is always internally consistent.
"     3 The User Operations - A collection of functions that manipulate the model and
"                             state under the assumption that they are already
"                             consistent with each other. The user operations
"                             can be used as an interface to this
"                             infrastructure when writing a script
"     4 The Commands - A collection of custom commands that make calls to the
"                      user operations
"     5 The Mappings - A collection of mappings that replace native Vim window
"                      operations with invocations of the custom commands.
"                      These mappings may interact in unwelcome ways with
"                      scripts, so they are optional
"
" If the State were to be mutated by *only* the user operations, it would
" always be consistent with the model... but unfortunately we can't make that
" assumption. All it takes to ruin the consistency is a single invocation of
" something like 'wincmd r' in a plugin. That's why there's a sixth component:
"
"     6 The Resolver - an algorithm which runs on the CursorHold autocmd event and
"                      guarantees on completion that the model and state are
"                      consistent with each other, even if they were inconsistent
"                      when the resolver started
"
" In short, the user interacts with the state and model by means of mappings
" and custom commands that call user operations, which keep the state and
" model consistent. Scripts may also use the user operations for more
" fine-grained control. If anything goes wrong and the state and model become
" inconsistent, the resolver will quickly swoop in and fix the inconsistency
" anyway. If updatetime is set to a small enough value, the inconsistency is
" visible only for a split second. I recommend an updatetime of 100, as I've
" found that anything shorter can sometimes lead to weird race conditions
"
" EXTENSIONS
"
" Extensions of this system take the form of definitions of uberwin and subwin group
" types (i.e. calls to the WinAddUberwinGroupType and WinAddSubwinGroupType user
" operations). Reference definitions are provided for help, preview, and
" quickfix uberwins. A reference definition is provided for a loclist subwin.
" These reference definitions are enabled by default, and easily disabled
" in case an alternate definition (or no definition) is desired
"
" LIMITATIONS
"
" - If the mappings are enabled, invoking a mapped command of the form
"   <c-w>{nr}<cr> or z{nr}<cr> from visual or select mode will cause the
"   mode indicator to disappear while {nr} is being typed in
"   TODO? See if there's some way to avoid this
"
" - If the mappings are enabled, invoking a mapped command in visual or
"   select mode will cause the mode indicator and highlighted area to
"   flicker - even if the mapped command has no effect (e.g. <c-w>j when
"   there's only one window)
"   TODO? See if there's some way to avoid this
"
" - If the resolver has to change the state, you are kicked into normal mode
"   This is hard to run into by accident, because you need to enter visual
"   mode after making the state and model inconsistent but before the resolver
"   starts.
"   TODO: Preserve mode in mappings from reference definitions
"   TODO: It may be possible to fix this, but I'm willing to bet that it won't
"   bother anyone... at least no more than the resolver changing the state
"   bothers them.
"
" - Compatibility with session reloading is dubious. In theory, the resolver is
" defensive enough to handle any and all possible changes to the state - but
" consistency between the state and model may not reasonably be enough for a
" smooth experience. For instance, sessions do not preserve location lists. So
" any location list subwins that exist during the :mksession invocation will
" be restored as supwins. It is the responsibility of the subwin group writers
" to deal with issues like these on a case-by-case basis. As an example, the
" reference definition of the location list subwin group (see: loclist.vim) handles
" the above case by closing all the supwins-that-were-subwins-in-a-previous-life.
"    TODO: Write a plugin that persists the the location lists outside the
"          session, and restores them after this happens
"    TODO: Write a plugin that persists the the quickfix list outside the
"          session, and restores it after this happens
"    TODO: Investigate whether the undotree can be persisted outside the
"          session and restored after this happens
"
"
" TODO? Preserve folds, signs, etc. when subwins and uberwins are hidden. Not
"       sure if this is desirable - would they still be restored after
"       location list contents change? Would different blobs of persisted
"       state be stored for each location list? Maybe just leave it as the
"       responsibility of files like loclist.vim and undotree.vim:w
" TODO? Figure out why folds keep appearing in the help window on
"       WinShowUberwin. Haven't seen this happen in some time - maybe it's
"       fixed?
" TODO? Think of a way to avoid creating a new buffer every time a subwin is
"       afterimaged
"       - This would mean reusing buffers and completely cleaning them between
"         uses
"       - Buffer numbers need to be 'freed' every time an afterimaged subwin is
"         closed, but the user (or some plugin) may do it directly without
"         freeing
" TODO: Actually make the mappings optional
" TODO: Actually make the reference definitions disable-able
" TODO: Allow for customization of a bunch of parameters to the reference
"       definitions
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
" TODO: Audit all the asserts (especially in the model) for redundancy
" TODO: Audit all of the code for performance improvements
" TODO: Comment out every logging statement that gets skipped by the default
"       levels. Write some kind of awk or sed script that uncomments and
"       recomments them
" TODO: Audit every function for calls to it
" TODO: Audit all files for ignoble terminology
" TODO: Audit all files for insufficient documentation
" TODO: Audit all files for lines longer than 80 characters
" TODO: Audit all files for 'endfunction!'
" TODO: Move the whole window engine to a plugin
" TODO: Autoload where appropriate
" TODO: Move undotree subwin to its own plugin so that the window engine
"       doesn't depend on mbbill/undotree

" Logging facilities - all in one place so they can be changed easily
" TODO: Move facilities from reference definitions to this block
call SetLogLevel('window-mappings', 'info',    'warning')
call SetLogLevel('window-commands', 'info',    'warning')
call SetLogLevel('window-user',     'info',    'warning')
call SetLogLevel('window-resolve',  'info',    'warning')
call SetLogLevel('window-common',   'info',    'warning')
call SetLogLevel('window-model',    'warning', 'warning')
call SetLogLevel('window-state',    'warning', 'warning')

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

" The resolver should run after any changes to the state
if !exists('g:j_winresolve_chc')
    let g:j_winresolve_chc = 1
    call RegisterCursorHoldCallback(function('WinResolve'), [], 1, 0, 1, 0, 1)
endif

" When the resolver runs in a new tab, it should run as if the tab was entered
function! s:InitTab()
    let t:winresolvetabenteredcond = 1
endfunction

augroup Window
    autocmd!

    " Every tab must be initialized
    autocmd VimEnter,TabNew * call s:InitTab()

    " Run the resolver when Vim is resized
    autocmd VimResized * call WinResolve()
augroup END

" Don't equalize window sizes when windows are closed
set noequalalways

" Allow windows to be arbitratily small
set winheight=1
set winwidth=1
set winminheight=1
set winminheight=1
