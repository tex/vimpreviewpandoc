autocmd FileType pandoc autocmd BufWinEnter,BufWritePost <buffer> 
            \ call vimpreviewpandoc#VimPreviewPandoc()
autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer>
            \ call vimpreviewpandoc#VimPreviewScrollTo()
