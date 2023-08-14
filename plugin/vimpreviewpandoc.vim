autocmd FileType pandoc autocmd BufWinEnter,BufWritePost <buffer> 
            \ call vimpreviewpandoc#Preview()

autocmd FileType markdown autocmd BufWinEnter,BufWritePost <buffer> 
            \ call vimpreviewpandoc#Preview()
