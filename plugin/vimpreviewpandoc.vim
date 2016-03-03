autocmd FileType pandoc autocmd BufWinEnter <buffer> call vimpreviewpandoc#VimPreviewPandoc(1)
autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer> call vimpreviewpandoc#VimPreviewPandoc(0) | call vimpreviewpandoc#VimPreviewScrollTo()
