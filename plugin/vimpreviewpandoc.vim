" Provide commands to turn on markdown preview for current buffer.
" Once turned on, it will refresh preview for that buffer on each write.
command MarkdownPreview call vimpreviewpandoc#Preview() | autocmd BufWritePost <buffer> call vimpreviewpandoc#Preview()
command PreviewMarkdown call vimpreviewpandoc#Preview() | autocmd BufWritePost <buffer> call vimpreviewpandoc#Preview()
