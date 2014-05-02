if exists( "g:vimfirepandoc" )
  autocmd FileType pandoc autocmd BufWritePost <buffer> call VimFirePandoc()
  autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer> call VimFirePandoc()
  autocmd FileType pandoc autocmd TextChanged,TextChangedI <buffer> call VimFireChanged()
endif

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

let b:vimfirepandoc_update = 0

function! VimFireChanged()
    let b:vimfirepandoc_update = 1
endfunction

function! VimFirePandoc()
    if b:vimfirepandoc_update == 1
        let html64 = system("pandoc -t " . s:path . "/html_dot.lua | base64 -w0", GetBufContent())
        call FireEvalJS("setOutput(\"" . html64 . "\")")
        let b:vimfirepandoc_update = 0
    endif
endfunction

function! GetBufContent()
    let bufnr = expand('<bufnr>')
    return join(getbufline(bufnr, 1, "$"),"\n")
endfunction

function! FireEvalJS(content)
python << endpython
import vim
import socket
try:
    data = ''
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 32000))
    s.send(vim.eval("a:content"))
    data = s.recv(2048)
    s.close()
except socket.error:
    vim.command("echohl ErrorMsg|echo 'Firefox or Remote Controller not running'|echohl None")
finally:
    vim.command("let s:TcpSendResult= '%s'" % data)
endpython
    return s:TcpSendResult
endfunction
