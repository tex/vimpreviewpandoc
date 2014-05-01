if exists( "g:vimfirepandoc" )
  autocmd FileType pandoc autocmd BufWritePost <buffer> call VimFirePandoc()
endif

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! VimFirePandoc()
    let html64 = system("cd " . fnamemodify(expand('%'), ':h') . "; pandoc " . fnamemodify(expand('%'), ':t') . " -t " . s:path . "/html_dot.lua | base64 -w0")
    call FireEvalJS("setOutput(\"" . html64 . "\")")
endfunction

function! FireEvalJS(content)
python << endpython
import vim
import socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 32000))
    s.send(vim.eval("a:content"))
    data = s.recv(2048)
    s.close()
    vim.command("let s:TcpSendResult= '%s'" % data)
except socket.error:
    vim.command("echohl ErrorMsg|echo 'Firefox or Remote Controller not running'|echohl None")
endpython
    return s:TcpSendResult
endfunction
