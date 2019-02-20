" Text colouring

" Comments are green because green doesn't call out for attention
highlight Comment        ctermfg=Green   ctermbg=Black

" Errors and Todos are red because red calls out for attention
highlight Error          ctermfg=Black   ctermbg=Red
highlight Todo           ctermfg=Red     ctermbg=Black

" Anything to do with the preprocessor is blue
highlight Macro          ctermfg=Blue    ctermbg=Black
highlight PreCondit      ctermfg=Blue    ctermbg=Black
highlight PreProc        ctermfg=Blue    ctermbg=Black
highlight Define         ctermfg=Blue    ctermbg=Black

" Literals are yellow
highlight Boolean        ctermfg=Yellow  ctermbg=Black
highlight Character      ctermfg=Yellow  ctermbg=Black
highlight Float          ctermfg=Yellow  ctermbg=Black
highlight Number         ctermfg=Yellow  ctermbg=Black
highlight String         ctermfg=Yellow  ctermbg=Black
" But special characters in them aren't
highlight Special        ctermfg=White   ctermbg=Black
highlight SpecialChar    ctermfg=White   ctermbg=Black

" Keywords from the language syntax are cyan
highlight Conditional    ctermfg=Cyan    ctermbg=Black
highlight Constant       ctermfg=Cyan    ctermbg=Black
highlight Exception      ctermfg=Cyan    ctermbg=Black
highlight Include        ctermfg=Cyan    ctermbg=Black
highlight Repeat         ctermfg=Cyan    ctermbg=Black
highlight Statement      ctermfg=Cyan    ctermbg=Black
highlight StorageClass   ctermfg=Cyan    ctermbg=Black
highlight Structure      ctermfg=Cyan    ctermbg=Black

" Meaningful single characters are magenta
highlight Delimiter      ctermfg=Magenta ctermbg=Black
highlight Operator       ctermfg=Magenta ctermbg=Black

" Names are white
highlight Function       ctermfg=White   ctermbg=Black
highlight Identifier     ctermfg=White   ctermbg=Black
highlight Label          ctermfg=White   ctermbg=Black
highlight Type           ctermfg=White   ctermbg=Black

" Anything I haven't seen yet is red, so I can find it easily and recolour it
highlight Debug          ctermfg=Red     ctermbg=Black
highlight Keyword        ctermfg=Red     ctermbg=Black
highlight SpecialComment ctermfg=Red     ctermbg=Black
highlight Tag            ctermfg=Red     ctermbg=Black
highlight Typedef        ctermfg=Red     ctermbg=Black
highlight Underlined     ctermfg=Red     ctermbg=Black
highlight Ignore         ctermfg=Red     ctermbg=Black
