autocmd FileType pandoc autocmd BufWritePost <buffer> call VimPreviewPandoc()
autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer> call VimPreviewPandoc()
autocmd FileType pandoc autocmd TextChanged,TextChangedI <buffer> call VimPreviewPandocUpdate(1)

let s:save_shellslash = &shellslash
set shellslash

let s:path = expand('<sfile>:p:h')

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
        let cmd = printf("%s %s %s", shellescape(s:path . "/vimpreviewpandoc.py"), shellescape(tmp), shellescape(expand("%p")))
        let sub = vimproc#system_bg(cmd)
    endif
endfunction

function! VimPreviewPandocGitDiff(old, new)
    let cmd = printf("%s %s %s %s", shellescape(s:path . "/vimpreviewpandoc_diff.py"), shellescape(expand("%p")), a:old, a:new)
    let sub = vimproc#system_bg(cmd)
endfunction

let shellslash = s:save_shellslash
unlet s:save_shellslash
