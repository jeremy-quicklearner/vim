" setup
if !exists("g:pretest")
    let g:pretest=1
    function! TestToOpenSingleS()
        let supwinid = win_getid()
        noautocmd split
        let subwinid = win_getid()
        noautocmd wincmd p
        return [subwinid]
    endfunction

    function! TestToOpenSingleU()
       help
       wincmd K
       return [win_getid()]
    endfunction

    function! TestToCloseSingleS()
        let supwinid = win_getid()
        let subwinid = t:supwin[supwinid].testSingleSubwin.subwin.testS.id
        noautocmd call win_gotoid(subwinid)
        noautocmd q!
        noautocmd call win_gotoid(supwinid)
    endfunction

    function! TestToCloseSingleU()
       helpc
    endfunction

    function! TestToOpenDoubleS()
        let supwinid = win_getid()
        noautocmd split
        let subwin1id = win_getid()
        noautocmd vsplit
        let subwin2id = win_getid()
        noautocmd call win_gotoid(supwinid)
        return [subwin1id, subwin2id]
    endfunction

    function! TestToOpenDoubleU()
       vnew
       wincmd H
       let id1 = win_getid()
       sp
       let id2 = win_getid()
       return [id1,id2]
    endfunction

    function! TestToCloseDoubleS()
        let supwinid = win_getid()
        let subwin1id = t:supwin[supwinid].testDoubleSubwin.subwin.testD1.id
        noautocmd call win_gotoid(subwin1id)
        noautocmd q!
        let subwin2id = t:supwin[supwinid].testDoubleSubwin.subwin.testD2.id
        noautocmd call win_gotoid(subwin2id)
        noautocmd q!
        noautocmd call win_gotoid(supwinid)
    endfunction

    function! TestToCloseDoubleU()
        let subwin1id = t:uberwin.testDoubleUberwin.uberwin.testD1.id
        noautocmd call win_gotoid(subwin1id)
        noautocmd q!
        let subwin2id = t:uberwin.testDoubleUberwin.uberwin.testD2.id
        noautocmd call win_gotoid(subwin2id)
        noautocmd q!
    endfunction

    call WinAddSubwinGroupType('testSingleSubwin',
                              \['testS'],
                              \'[TST]', '[HID]', 1,
                              \0, [1], [-1], [5],
                              \function('TestToOpenSingleS'),
                              \function('TestToCloseSingleS')) 

    call WinAddSubwinGroupType('testDoubleSubwin',
                              \['testD1', 'testD2'],
                              \'[TDB]', '[HID]', 1,
                              \1, [1, 1], [-1, -1], [5, 5],
                              \function('TestToOpenDoubleS'),
                              \function('TestToCloseDoubleS')) 

    call WinAddUberwinGroupType('testSingleUberwin',
                               \['testS'],
                               \'[TST]', '[HID]', 1,
                               \0, [-1], [5],
                               \function('TestToOpenSingleU'),
                               \function('TestToCloseSingleU')) 

    call WinAddUberwinGroupType('testDoubleUberwin',
                               \['testD1', 'testD2'],
                               \'[TDB]', '[HID]', 1,
                               \1, [-1, -1], [5, 5],
                               \function('TestToOpenDoubleU'),
                               \function('TestToCloseDoubleU')) 

    nnoremap -so :call WinAddSubwinGroup(win_getid(), 'testSingleSubwin', 0)<cr>
    nnoremap -sc :call WinRemoveSubwinGroup(win_getid(), 'testSingleSubwin')<cr>
    nnoremap -ss :call WinShowSubwinGroup(win_getid(), 'testSingleSubwin')<cr>
    nnoremap -sh :call WinHideSubwinGroup(win_getid(), 'testSingleSubwin')<cr>

    nnoremap -do :call WinAddSubwinGroup(win_getid(), 'testDoubleSubwin', 0)<cr>
    nnoremap -dc :call WinRemoveSubwinGroup(win_getid(), 'testDoubleSubwin')<cr>
    nnoremap -ds :call WinShowSubwinGroup(win_getid(), 'testDoubleSubwin')<cr>
    nnoremap -dh :call WinHideSubwinGroup(win_getid(), 'testDoubleSubwin')<cr>
endif

" Uberwin Model
call WinModelAddUberwins('testSingleUberwin', [])
call WinModelShowUberwins('testSingleUberwin', [win_getid()+1])
call WinModelHideUberwins('testSingleUberwin')
call WinModelRemoveUberwins('testSingleUberwin')

call WinModelAddUberwins('testSingleUberwin', [win_getid()+1])
call WinModelHideUberwins('testSingleUberwin')
call WinModelShowUberwins('testSingleUberwin', [win_getid()+1])
call WinModelRemoveUberwins('testSingleUberwin')

call WinModelAddUberwins('testDoubleUberwin', [])
call WinModelShowUberwins('testDoubleUberwin', [win_getid()+1, win_getid()+2])
call WinModelHideUberwins('testDoubleUberwin')
call WinModelRemoveUberwins('testDoubleUberwin')

call WinModelAddUberwins('testDoubleUberwin', [win_getid()+2, win_getid() + 3])
call WinModelHideUberwins('testDoubleUberwin')
call WinModelShowUberwins('testDoubleUberwin', [win_getid()+1, win_getid()+2])
call WinModelRemoveUberwins('testDoubleUberwin')

call WinModelAddUberwins('testSingleUberwin', [])
call WinModelAddUberwins('testDoubleUberwin', [])

call WinModelShowUberwins('testSingleUberwin', [win_getid()+1])
call WinModelShowUberwins('testDoubleUberwin', [win_getid()+2, win_getid()+3])
call WinModelHideUberwins('testSingleUberwin')
call WinModelHideUberwins('testDoubleUberwin')

call WinModelRemoveUberwins('testSingleUberwin')
call WinModelRemoveUberwins('testDoubleUberwin')

call WinModelAddUberwins('testSingleUberwin', [win_getid()+4])
call WinModelAddUberwins('testDoubleUberwin', [win_getid()+5, win_getid() + 6])

call WinModelHideUberwins('testSingleUberwin')
call WinModelHideUberwins('testDoubleUberwin')
call WinModelShowUberwins('testSingleUberwin', [win_getid()+1])
call WinModelShowUberwins('testDoubleUberwin', [win_getid()+2, win_getid()+3])

call WinModelRemoveUberwins('testSingleUberwin')
call WinModelRemoveUberwins('testDoubleUberwin')

call WinModelAddUberwins('testSingleUberwin', [win_getid()+1])
call WinModelAddUberwins('testDoubleUberwin', [win_getid()+2, win_getid() + 3])

call WinModelChangeUberwinIds('testSingleUberwin', [win_getid()+4])
call WinModelChangeUberwinIds('testDoubleUberwin', [win_getid()+5, win_getid()+6])

call WinModelRemoveUberwins('testSingleUberwin')
call WinModelRemoveUberwins('testDoubleUberwin')

" Subwin model
call WinModelAddSubwins(win_getid(), 'testSingleSubwin', [])
call WinModelShowSubwins(win_getid(), 'testSingleSubwin', [win_getid()+1])
call WinModelAfterimageSubwin(win_getid(), 'testSingleSubwin', 'testS', 123)
call WinModelHideSubwins(win_getid(), 'testSingleSubwin')
call WinModelRemoveSubwins(win_getid(), 'testSingleSubwin')

call WinModelAddSubwins(win_getid(), 'testSingleSubwin', [win_getid()+1])
call WinModelAfterimageSubwin(win_getid(), 'testSingleSubwin', 'testS', 123)
call WinModelHideSubwins(win_getid(), 'testSingleSubwin')
call WinModelShowSubwins(win_getid(), 'testSingleSubwin', [win_getid()+1])
call WinModelAfterimageSubwin(win_getid(), 'testSingleSubwin', 'testS', 123)
call WinModelRemoveSubwins(win_getid(), 'testSingleSubwin')

call WinModelAddSubwins(win_getid(), 'testDoubleSubwin', [])
call WinModelShowSubwins(win_getid(), 'testDoubleSubwin', [win_getid()+1, win_getid()+2])
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD1', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD2', 123)
call WinModelHideSubwins(win_getid(), 'testDoubleSubwin')
call WinModelRemoveSubwins(win_getid(), 'testDoubleSubwin')

call WinModelAddSubwins(win_getid(), 'testDoubleSubwin', [win_getid()+2, win_getid() + 3])
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD1', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD2', 123)
call WinModelHideSubwins(win_getid(), 'testDoubleSubwin')
call WinModelShowSubwins(win_getid(), 'testDoubleSubwin', [win_getid()+1, win_getid()+2])
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD1', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD2', 123)
call WinModelRemoveSubwins(win_getid(), 'testDoubleSubwin')

call WinModelAddSubwins(win_getid(), 'testSingleSubwin', [])
call WinModelAddSubwins(win_getid(), 'testDoubleSubwin', [])

call WinModelShowSubwins(win_getid(), 'testSingleSubwin', [win_getid()+1])
call WinModelShowSubwins(win_getid(), 'testDoubleSubwin', [win_getid()+2, win_getid()+3])
call WinModelAfterimageSubwin(win_getid(), 'testSingleSubwin', 'testS', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD1', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD2', 123)
call WinModelHideSubwins(win_getid(), 'testSingleSubwin')
call WinModelHideSubwins(win_getid(), 'testDoubleSubwin')

call WinModelRemoveSubwins(win_getid(), 'testSingleSubwin')
call WinModelRemoveSubwins(win_getid(), 'testDoubleSubwin')

call WinModelAddSubwins(win_getid(), 'testSingleSubwin', [win_getid()+4])
call WinModelAddSubwins(win_getid(), 'testDoubleSubwin', [win_getid()+5, win_getid() + 6])
call WinModelAfterimageSubwin(win_getid(), 'testSingleSubwin', 'testS', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD1', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD2', 123)

call WinModelHideSubwins(win_getid(), 'testSingleSubwin')
call WinModelHideSubwins(win_getid(), 'testDoubleSubwin')
call WinModelShowSubwins(win_getid(), 'testSingleSubwin', [win_getid()+1])
call WinModelShowSubwins(win_getid(), 'testDoubleSubwin', [win_getid()+2, win_getid()+3])
call WinModelAfterimageSubwin(win_getid(), 'testSingleSubwin', 'testS', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD1', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD2', 123)

call WinModelRemoveSubwins(win_getid(), 'testSingleSubwin')
call WinModelRemoveSubwins(win_getid(), 'testDoubleSubwin')

call WinModelAddSubwins(win_getid(), 'testSingleSubwin', [win_getid()+1])
call WinModelAddSubwins(win_getid(), 'testDoubleSubwin', [win_getid()+2, win_getid() + 3])
call WinModelAfterimageSubwin(win_getid(), 'testSingleSubwin', 'testS', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD1', 123)
call WinModelAfterimageSubwin(win_getid(), 'testDoubleSubwin', 'testD2', 123)

call WinModelChangeSubwinIds(win_getid(), 'testSingleSubwin', [win_getid()+4])
call WinModelChangeSubwinIds(win_getid(), 'testDoubleSubwin', [win_getid()+5, win_getid()+6])

call WinModelRemoveSubwins(win_getid(), 'testSingleSubwin')
call WinModelRemoveSubwins(win_getid(), 'testDoubleSubwin')

" Adding and removing uberwins
call WinAddUberwinGroup('testSingleUberwin', 0)
call WinRemoveUberwinGroup('testSingleUberwin')

call WinAddUberwinGroup('testDoubleUberwin', 0)
call WinRemoveUberwinGroup('testDoubleUberwin')

call WinAddUberwinGroup('testDoubleUberwin', 0)
call WinAddUberwinGroup('testSingleUberwin', 0)
call WinRemoveUberwinGroup('testSingleUberwin')
call WinRemoveUberwinGroup('testDoubleUberwin')

call WinAddUberwinGroup('testSingleUberwin', 0)
call WinAddUberwinGroup('testDoubleUberwin', 0)
call WinRemoveUberwinGroup('testDoubleUberwin')
call WinRemoveUberwinGroup('testSingleUberwin')

" Hiding and showing uberwins
call WinAddUberwinGroup('testSingleUberwin', 0)
call WinAddUberwinGroup('testDoubleUberwin', 0)

call WinHideUberwinGroup('testSingleUberwin')
call WinHideUberwinGroup('testDoubleUberwin')
call WinShowUberwinGroup('testSingleUberwin')
call WinShowUberwinGroup('testDoubleUberwin')

call WinHideUberwinGroup('testDoubleUberwin')
call WinHideUberwinGroup('testSingleUberwin')
call WinShowUberwinGroup('testDoubleUberwin')
call WinShowUberwinGroup('testSingleUberwin')

call WinRemoveUberwinGroup('testSingleUberwin')
call WinRemoveUberwinGroup('testDoubleUberwin')

" Adding and removing subwins
call WinAddSubwinGroup(win_getid(), 'testSingleSubwin', 0)
call WinRemoveSubwinGroup(win_getid(), 'testSingleSubwin')

call WinAddSubwinGroup(win_getid(), 'testDoubleSubwin', 0)
call WinRemoveSubwinGroup(win_getid(), 'testDoubleSubwin')

call WinAddSubwinGroup(win_getid(), 'testDoubleSubwin', 0)
call WinAddSubwinGroup(win_getid(), 'testSingleSubwin', 0)
call WinRemoveSubwinGroup(win_getid(), 'testSingleSubwin')
call WinRemoveSubwinGroup(win_getid(), 'testDoubleSubwin')

call WinAddSubwinGroup(win_getid(), 'testSingleSubwin', 0)
call WinAddSubwinGroup(win_getid(), 'testDoubleSubwin', 0)
call WinRemoveSubwinGroup(win_getid(), 'testDoubleSubwin')
call WinRemoveSubwinGroup(win_getid(), 'testSingleSubwin')

" Hiding and showing subwins
call WinAddSubwinGroup(win_getid(), 'testSingleSubwin', 0)
call WinAddSubwinGroup(win_getid(), 'testDoubleSubwin', 0)

call WinHideSubwinGroup(win_getid(), 'testSingleSubwin')
call WinHideSubwinGroup(win_getid(), 'testDoubleSubwin')
call WinShowSubwinGroup(win_getid(), 'testSingleSubwin')
call WinShowSubwinGroup(win_getid(), 'testDoubleSubwin')

call WinHideSubwinGroup(win_getid(), 'testDoubleSubwin')
call WinHideSubwinGroup(win_getid(), 'testSingleSubwin')
call WinShowSubwinGroup(win_getid(), 'testDoubleSubwin')
call WinShowSubwinGroup(win_getid(), 'testSingleSubwin')

call WinRemoveSubwinGroup(win_getid(), 'testSingleSubwin')
call WinRemoveSubwinGroup(win_getid(), 'testDoubleSubwin')
