" Window infrastructure Resolve function
" See window.vim

function! s:WinResolveStateToModel()
    " Terminal windows get special handling because the CursorHold event
    " doesn't execute when the cursor is inside them

    " TODO: If any terminal window is listed in the model as an uberwin, mark that
    "       uberwin group hidden in the model and relist the window as a supwin

    " TODO: If any terminal window is listed in the model as a subwin, mark that
    "       subwin group hidden in the model and relist the window as a supwin

    " TODO: If any terminal window has non-hidden subwins, mark them as
    "       terminal-hidden in the model

    " TODO: If any non-terminal window has terminal-hidden subwins, mark those
    "       subwins as shown in the model

    " TODO: If any window is listed in the model as an uberwin but doesn't
    "       satisfy its type's constraints, mark the uberwin group hidden
    "       in the model and relist the window as a supwin

    " TODO: If any window is listed in the model as a subwin but doesn't
    "       satisfy its type's constraints, mark the uberwin group hidden
    "       in the model and relist the window as a supwin

    " If any window in the state isn't in the model, add it to the model
    let statewinids = WinStateGetWinidsByCurrentTab()
    for statewinid in statewinids
        if !WinModelWinExists(statewinid)
            " TODO: Add as appropriate subwin/uberwin
            call WinModelAddSupwin(statewinid)
        endif
    endfor

    " If any uberwin group in the model isn't fully represented in the state,
    " mark it hidden in the model
    let modeluberwinids = WinModelUberwinIds()
    " Using a dict so no keys will be duplicated
    let uberwingrouptypestohide = {}
    for modeluberwinid in modeluberwinids
        if !WinStateWinExists(modeluberwinid)
           let tohide = WinModelInfoById(modeluberwinid)
           if tohide.category != 'uberwin'
               throw 'Inconsistency in model. ID ' . modeluberwinid . ' is both' .
              \      ' uberwin and ' . tohide.category       
           endif
           let uberwingrouptypestohide[tohide.grouptype] = ''
        endif
    endfor
    for tohide in keys(uberwingrouptypestohide)
         call WinModelHideUberwins(tohide)
    endfor

    " If any subwin group in the model isn't fully represented in the state,
    " mark it hidden in the model
    let modelsupwinids = WinModelSupwinIds()
    let modelsubwinids = WinModelSubwinIds()
    " Using a dict for each supwin so no keys will be duplicated
    let subwingrouptypestohidebysupwin = {}
    for modelsupwinid in modelsupwinids
        let subwingrouptypestohidebysupwin[modelsupwinid] = {}
    endfor
    for modelsubwinid in modelsubwinids
        if !WinStateWinExists(modelsubwinid)
            let tohide = WinModelInfoById(modelsubwinid)
            if tohide.category != 'subwin'
                throw 'Inconsistency in model. ID ' . modelsubwinid . ' is both' .
               \      ' subwin and ' . tohide.category
            endif
            let subwingrouptypestohidebysupwin[tohide.supwin][tohide.grouptype] = ''
        endif
    endfor
    for supwinid in keys(subwingrouptypestohidebysupwin)
        for subwingrouptypetohide in keys(subwingrouptypestohidebysupwin[supwinid])
            call WinModelHideSubwins(supwinid, subwingrouptypetohide)
        endfor
    endfor

    " If any supwin in the model isn't in the state, remove it and its subwins
    " from the model
    for modelsupwinid in modelsupwinids
        if !WinStateWinExists(modelsupwinid)
            call WinModelRemoveSupwin(modelsupwinid)
        endif
    endfor
endfunction

function! s:WinResolveModelToState()
    " TODO: If any uberwin's dimensions have changed, remove that uberwin's group
    "       and all groups with lower priorities from the state
    " TODO: If any subwin's dimensions have changed, remove that subwin's group
    "       and all groups with lower priorities from the state

    " TODO: If any supwin in the state isn't in the model, remove it from the
    "       state.
    " TODO: If any uberwin in the state isn't shown in the model, remove it
    "       from the state.
    " TODO: If any subwin in the state isn't shown in the model, remove it
    "       from the state

    " TODO: If any non-hidden uberwin in the model isn't in the state,
    "       add it to the state
    " TODO: If any non-hidden subwin in the model isn't in the state,
    "       add it to the state
endfunction

" Third, record all open windows' dimensions in the model so that changes can be
" detected
function! s:WinResolveRecordDimensions()
    " TODO: stub
endfunction
    
" The resolve function
let s:resolveIsRunning = 0
function! WinResolve(arg)
    if s:resolveIsRunning
        return
    endif
    let s:resolveIsRunning = 1

    " Make sure the tab-specific model elements exist
    if !WinModelExists()
        call WinModelInit()
    endif

    " The state may have changed since the last WinResolve() call. Adapt the
    " model to fit it.
    call s:WinResolveStateToModel()

    " Now the model is the way it should be, so adjust the state to fit it.
    call s:WinResolveModelToState()

    " Window dimensions may have changed. Record them in the model.
    call s:WinResolveRecordDimensions()

    let s:resolveIsRunning = 0
endfunction
