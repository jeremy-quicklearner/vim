" Window infrastructure Resolve function
" See window.vim

" First, adjust the model based on the state
function! s:WinResolveStateToModel()
    " TODO: If any terminal window is listed in the model as an uberwin, mark that
    "       uberwin group hidden in the model and relist the window as a supwin

    " TODO: If any terminal window is listed in the model as a subwin, mark that
    "       subwin group hidden in the model and relist the window as a supwin

    " TODO: If any terminal window has non-hidden subwins, mark them as
    "       terminal-hidden in the model

    " TODO: If any non-terminal window has terminal-hidden subwins, mark those
    "       subwins as shown in the model

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
    let uberwingrouptypestoremove = {}
    for modeluberwinid in modeluberwinids
        if !WinStateWinExists(modeluberwinid)
           let toremove = WinModelGroupTypeNameById(modeluberwinid)
           if toremove != 'supwin'
               let uberwingrouptypestoremove[toremove] = ''
           endif
        endif
    endfor
    for toremove in keys(uberwingrouptypestoremove)
         call WinModelHideUberwins(toremove)
    endfor

    " TODO: If any subwin group in the model isn't fully represented in the state,
    "       mark it hidden in the model

    " If any supwin in the model isn't in the state, remove it and its subwins
    " from the model
    let modelsupwinids = WinModelSupwinIds()
    for modelsupwinid in modelsupwinids
        if !WinStateWinExists(modelsupwinid)
            call WinModelRemoveSupwin(modelsupwinid)
        endif
    endfor


endfunction

" Second, adjust the state based on the model
function! s:WinResolveModelToState()
    " TODO: If any uberwin's dimensions have changed, remove that uberwin's group
    "       and all groups with lower priorities from the state
    " TODO: If any subwin's dimensions have changed, remove that subwin's group
    "       and all groups with lower priorities from the state

    " TODO: If any uberwin in the state isn't shown in the model, remove it
    "       from the state
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

    " First, adjust the model based on the state
    call s:WinResolveStateToModel()

    " Second, adjust the state based on the model
    call s:WinResolveModelToState()

    " Third, record all open windows' dimensions so that changes can be
    " detected
    call s:WinResolveRecordDimensions()

    let s:resolveIsRunning = 0
endfunction
