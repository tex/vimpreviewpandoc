autocmd FileType pandoc autocmd BufWritePost <buffer> call VimPreviewPandoc()
autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer> call VimPreviewPandoc()
autocmd FileType pandoc autocmd TextChanged,TextChangedI <buffer> call VimPreviewPandocUpdate(1)

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! VimPreviewPandocUpdate(value)
    if !exists("b:vimpreviewpandoc_update")
        let b:vimpreviewpandoc_update = 1
    endif
    let l:old_value = b:vimpreviewpandoc_update
    let b:vimpreviewpandoc_update = a:value
    return l:old_value
endfunction

function! VimPreviewPandoc()
    if VimPreviewPandocUpdate(0) == 1
        let tmp = tempname()
        silent execute '%write '.tmp
        let cmd = printf("%s/vimpreviewpandoc.py \"%s\" \"%s\"", s:path, tmp, substitute(resolve(expand("%:p")), '"', '\\"', 'g'))
        let sub = vimproc#system_bg(cmd)
    endif
endfunction

function! VimPreviewPandocGitDiff(old, new)
    let cmd = printf("%s/vimpreviewpandoc_diff.py \"%s\" \"%s\" \"%s\"", s:path, substitute(expand("%"), '"', '\\"', 'g'), a:old, a:new)
    let sub = vimproc#system_bg(cmd)
endfunction

