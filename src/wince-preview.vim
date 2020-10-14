" Wince Reference Definition for Preview uberwin
if !exists('g:wince_enable_preview') || !g:wince_enable_preview
    call EchomLog('wince-preview-uberwin', 'config', 'Preview uberwin disabled')
    finish
endif

" The preview uberwin is intended to only ever be opened by native commands like
" ptag and pjump - no user operations. Therefore the window engine code interacts
" with it only via the resolver and WinceToOpenPreview only ever gets called when the
" resolver closes and reopens the window. So the implementation of
" WinceToOpenPreview assumes that WinceToClosePreview has recently been called.
augroup WincePreview
    autocmd!
    autocmd VimEnter, TabNew * let t:j_preview = {}
augroup END

if !exists('g:wince_preview_bottom')
    let g:wince_preview_bottom = 0
endif

if !exists('g:wince_preview_statusline')
    let g:wince_preview_statusline = '%!WincePreviewStatusLine()'
endif

" Callback that opens the preview window
function! WinceToOpenPreview()
    call EchomLog('wince-preview-uberwin', 'info', 'WinceToOpenPreview')
    if empty(t:j_preview)
        throw 'Preview window has not been closed yet'
    endif

    for winid in WinceStateGetWinidsByCurrentTab()
        if getwinvar(Wince_id2win(winid), '&previewwindow', 0)
            throw 'Preview window already open'
        endif
    endfor

    let previouswinid = Wince_getid_cur()

    if g:wince_preview_bottom
        noautocmd botright split
    else
        noautocmd topleft split
    endif
    let &l:scrollbind = 0
    let &l:cursorbind = 0
    noautocmd execute 'resize ' . &previewheight

    " If the file being previewed is already open in another Vim instance,
    " this command throws (but works)
    try
        noautocmd silent execute 'buffer ' . t:j_preview.bufnr
    catch /.*/
        call EchomLog('wince-preview-uberwin', 'warning', v:exception)
    endtry

    let winid = Wince_getid_cur()
    call WinceStatePostCloseAndReopen(winid, t:j_preview)
    let &previewwindow = 1
    let &winfixheight = 1
    " This looks strange but it's necessary. Without it, the above uses of
    " noautocmd stop the syntax highlighting from being applied even though
    " the syntax option is set
    let &syntax = &syntax

    noautocmd call Wince_gotoid(previouswinid)

    return [winid]
endfunction

" Callback that closes the preview window
function! WinceToClosePreview()
    call EchomLog('wince-preview-uberwin', 'info', 'WinceToClosePreview')
    let previewwinid = 0
    for winid in WinceStateGetWinidsByCurrentTab()
        if getwinvar(Wince_id2win(winid), '&previewwindow', 0)
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

    let t:j_preview = WinceStatePreCloseAndReopen(previewwinid)
    let t:j_preview.bufnr = winbufnr(Wince_id2win(previewwinid))

    pclose
endfunction

" Callback that returns 'preview' if the supplied winid is for the preview
" window
function! WinceToIdentifyPreview(winid)
    call EchomLog('wince-preview-uberwin', 'debug', 'WinceToIdentifyPreview ', a:winid)
    if getwinvar(Wince_id2win(a:winid), '&previewwindow', 0)
        return 'preview'
    endif
    return ''
endfunction

" Returns the statusline of the preview window
function! WincePreviewStatusLine()
    call EchomLog('wince-preview-uberwin', 'debug', 'PreviewStatusLine')
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
call WinceAddUberwinGroupType('preview', ['preview'],
                           \[g:wince_preview_statusline],
                           \'P', 'p', 7,
                           \30, [0],
                           \[-1], [&previewheight],
                           \function('WinceToOpenPreview'),
                           \function('WinceToClosePreview'),
                           \function('WinceToIdentifyPreview'))

" Mappings
call WinceMappingMapUserOp('<leader>ps', 'call WinceShowUberwinGroup("preview", 1)')
call WinceMappingMapUserOp('<leader>ph', 'call WinceHideUberwinGroup("preview")')
call WinceMappingMapUserOp('<leader>pc', 'call WinceHideUberwinGroup("preview")')
call WinceMappingMapUserOp('<leader>pp', 'call WinceGotoUberwin("preview", "preview", 1)')
