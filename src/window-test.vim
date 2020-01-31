function! TestToOpenSingle()
    let supwinid = win_getid()
    noautocmd split
    let subwinid = win_getid()
    noautocmd wincmd p
    return [subwinid]
endfunction

function! TestToCloseSingle()
    let supwinid = win_getid()
    let subwinid = t:supwin[supwinid].subwin.testSingle.testS
    noautocmd call win_gotoid(subwinid)
    noautocmd q!
    noautocmd call win_gotoid(supwinid)
endfunction

function! TestToOpenDouble()
    let supwinid = win_getid()
    noautocmd split
    let subwin1id = win_getid()
    noautocmd vsplit
    let subwin2id = win_getid()
    noautocmd call win_gotoid(supwinid)
    return [subwin1id, subwin2id]
endfunction

function! TestToCloseDouble()
    let supwinid = win_getid()
    let subwin1id = t:supwin[supwinid].subwin.testDouble.testD1
    noautocmd call win_gotoid(subwin1id)
    noautocmd q!
    let subwin2id = t:supwin[supwinid].subwin.testDouble.testD2
    noautocmd call win_gotoid(subwin2id)
    noautocmd q!
    noautocmd call win_gotoid(supwinid)
endfunction

call WinAddSubwinGroupType('testSingle',
                          \['testS'],
                          \'[TST]', '[HID]', 1,
                          \0, 1, [-1], [5],
                          \function('TestToOpenSingle'),
                          \function('TestToCloseSingle')) 

call WinAddSubwinGroupType('testDouble',
                          \['testD1', 'testD2'],
                          \'[TDB]', '[HID]', 1,
                          \1, 1, [-1, -1], [5, 5],
                          \function('TestToOpenDouble'),
                          \function('TestToCloseDouble')) 

call WinAddUberwinGroupType('testSingle',
                           \['testS'],
                           \'[TST]', '[HID]', 1,
                           \0, [-1], [5],
                           \function('TestToOpenSingle'),
                           \function('TestToCloseSingle')) 

call WinAddUberwinGroupType('testDouble',
                           \['testD1', 'testD2'],
                           \'[TDB]', '[HID]', 1,
                           \1, [-1, -1], [5, 5],
                           \function('TestToOpenDouble'),
                           \function('TestToCloseDouble')) 

call WinModelAddUberwins([], 'testSingle')
call WinModelShowUberwins('testSingle', [win_getid()+1])
call WinModelHideUberwins('testSingle')
call WinModelRemoveUberwins('testSingle')





call WinModelAddUberwins([win_getid()+1], 'testSingle')
call WinModelHideUberwins('testSingle')
call WinModelShowUberwins('testSingle', [win_getid()+1])
call WinModelRemoveUberwins('testSingle')





call WinModelAddUberwins([], 'testDouble')
call WinModelShowUberwins('testDouble', [win_getid()+1, win_getid()+2])
call WinModelHideUberwins('testDouble')
call WinModelRemoveUberwins('testDouble')

call WinModelAddUberwins([win_getid()+2, win_getid() + 3], 'testDouble')
call WinModelHideUberwins('testDouble')
call WinModelShowUberwins('testDouble', [win_getid()+1, win_getid()+2])
call WinModelRemoveUberwins('testDouble')






call WinModelAddUberwins([], 'testSingle')
call WinModelAddUberwins([], 'testDouble')

call WinModelShowUberwins('testSingle', [win_getid()+1])
call WinModelShowUberwins('testDouble', [win_getid()+2, win_getid()+3])
call WinModelHideUberwins('testSingle')
call WinModelHideUberwins('testDouble')

call WinModelRemoveUberwins('testSingle')
call WinModelRemoveUberwins('testDouble')






call WinModelAddUberwins([win_getid()+4], 'testSingle')
call WinModelAddUberwins([win_getid()+5, win_getid() + 6], 'testDouble')

call WinModelHideUberwins('testSingle')
call WinModelHideUberwins('testDouble')
call WinModelShowUberwins('testSingle', [win_getid()+1])
call WinModelShowUberwins('testDouble', [win_getid()+2, win_getid()+3])

call WinModelRemoveUberwins('testSingle')
call WinModelRemoveUberwins('testDouble')
