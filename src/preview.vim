" Preview window manipulation

" The preview uberwin is intended to only ever be opened by native commands like
" ptag and pjump - no user operations. Therefore the window engine code interacts
" with it only via the resolver and ToOpenPreview only ever gets called when the
" resolver closes and reopens the window. So the implementation of
" ToOpenPreview assumes that ToClosePreview has recently been called.

augroup Preview
    autocmd!
    autocmd VimEnter, TabNew * let t:j_preview = {}
augroup END

" Callback that opens the preview window
function! ToOpenPreview()
    if empty(t:j_preview)
        throw 'Preview window has not been closed yet'
    endif

    for winid in WinStateGetWinidsByCurrentTab()
        if getwinvar(winid, '&previewwindow', 0)
            throw 'Preview window already open'
        endif
    endfor

    noautocmd execute 'topleft ' . &previewheight . 'split'
    call WinStateWincmd(&previewheight, '_')

    " If the file being previewed is already open in another Vim instance,
    " this command throws ( but works )
    try
       silent execute 'buffer ' . t:j_preview.bufnr
    catch /.*/
       call EchomLog('warning', v:exception)
    endtry

    let winid = win_getid()
    call WinStatePostCloseAndReopen(winid, t:j_preview)
    set previewwindow
    set winfixheight

    return [winid]
endfunction

" Callback that closes the preview window
function! ToClosePreview()
    let previewwinid = 0
    for winid in WinStateGetWinidsByCurrentTab()
        if getwinvar(winid, '&previewwindow', 0)
            let previewwinid = winid
        endif
    endfor

    if !previewwinid
        throw 'Preview window is not open'
    endif

    " pclose fails if the preview window is the last window, so use :quit
    " instead
    if winnr('$') ==# 1 && tabpagenr('$') ==# 1
        quit
        return
    endif

    let t:j_preview = WinStatePreCloseAndReopen(previewwinid)
    let t:j_preview.bufnr = winbufnr(previewwinid)

    pclose
endfunction

" Callback that returns 'preview' if the supplied winid is for the preview
" window
function! ToIdentifyPreview(winid)
    if getwinvar(a:winid, '&previewwindow', 0)
        return 'preview'
    endif
    return ''
endfunction

" Returns the statusline of the preview window
function! PreviewStatusLine()
    let statusline = ''

    " 'Preview' string
    let statusline .= '%7*[Preview]'

    " Buffer type
    let statusline .= '%7*%y'

    " Start truncating
    let statusline .= '%<'

    " Buffer number
    let statusline .= '%1*[%n]'

    " Filename
    let statusline .= '%1*[%f]'

    " Argument status
    let statusline .= '%5*%a%{SpaceIfArgs()}%1*'

    " Right-justify from now on
    let statusline .= '%=%<'

    " [Column][Current line/Total lines][% of buffer]
    let statusline .= '%7*[%c][%l/%L][%p%%]'

    return statusline
endfunction

" The preview window is an uberwin
call WinAddUberwinGroupType('preview', ['preview'],
                           \['%!PreviewStatusLine()'],
                           \'P', 'p', 7,
                           \40,
                           \[-1], [&previewheight],
                           \function('ToOpenPreview'),
                           \function('ToClosePreview'),
                           \function('ToIdentifyPreview'))

" Mappings
function! WinGotoPreview(count)
    call WinGotoUberwin('preview', 'preview')
endfunction
call WinCmdDefineSpecialCmd('WinGotoPreview', 'WinGotoPreview')
call WinMappingMapCmd(['P'], 'WinGotoPreview', 0, 1,1,1)

nnoremap <silent> <leader>pc :call WinRemoveUberwinGroup('preview')<cr>
nnoremap <silent> <leader>ps :call WinShowUberwinGroup('preview')<cr>
nnoremap <silent> <leader>ph :call WinHideUberwinGroup('preview')<cr>
nnoremap <silent> <leader>pp :call WinGotoUberwin('preview', 'preview')<cr>
