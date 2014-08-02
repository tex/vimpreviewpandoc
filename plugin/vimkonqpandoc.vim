if exists( "g:vimkonqpandoc" )
  autocmd FileType pandoc autocmd BufWritePost <buffer> call VimKonqPandoc()
  autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer> call VimKonqPandoc()
  autocmd FileType pandoc autocmd TextChanged,TextChangedI <buffer> call VimKonqUpdate(1)
endif

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! VimKonqUpdate(value)
    if !exists("b:vimkonqpandoc_update")
        let b:vimkonqpandoc_update = 1
    endif
    let l:old_value = b:vimkonqpandoc_update
    let b:vimkonqpandoc_update = a:value
    return l:old_value
endfunction

function! VimKonqPandoc()
    if VimKonqUpdate(0) == 1
        let tmp = tempname()
        silent execute '%write '.tmp
        let cmd = printf("%s/vimkonqpandoc.py %s %s", s:path, tmp, resolve(expand("%:p")))
        let sub = vimproc#system_bg(cmd)
    endif
endfunction


