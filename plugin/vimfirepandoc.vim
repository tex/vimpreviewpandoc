if exists( "g:vimfirepandoc" )
  autocmd FileType pandoc autocmd BufWritePost <buffer> call VimFirePandoc()
  autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer> call VimFirePandoc()
  autocmd FileType pandoc autocmd TextChanged,TextChangedI <buffer> call VimFireUpdate(1)
endif

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! VimFireUpdate(value)
    if !exists("b:vimfirepandoc_update")
        let b:vimfirepandoc_update = 1
    endif
    let l:old_value = b:vimfirepandoc_update
    let b:vimfirepandoc_update = a:value
    return l:old_value
endfunction

function! VimFirePandoc()
    if VimFireUpdate(0) == 1
        let tmp = tempname()
        silent execute '%write '.tmp
        let cmd = printf("%s/vimfirepandoc.py %s %s", s:path, tmp, resolve(expand("%:p")))
        let sub = vimproc#system_bg(cmd)
    endif
endfunction
