if exists( "g:vimkonqpandoc" )
  autocmd FileType pandoc autocmd BufWritePost <buffer> call VimKonqPandoc()
  autocmd FileType pandoc autocmd CursorHold,CursorHoldI <buffer> call VimKonqPandoc()
  autocmd FileType pandoc autocmd TextChanged,TextChangedI <buffer> call VimKonqChanged()
endif

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

let b:vimkonqpandoc_update = 0

function! VimKonqChanged()
    let b:vimkonqpandoc_update = 1
endfunction

function! VimKonqPandoc()
    if b:vimkonqpandoc_update == 1
        try
            let curr = s:IndexHtml()
            let dest = s:KonqFindDest()
            if resolve(s:KonqCurrentUrl(dest)) != "file:" . curr
                call s:KonqOpenUrl(dest, curr)
            endif
            let html64 = system("pandoc -t " . s:path . "/html_dot.lua | base64 -w0", GetBufContent())
            call s:KonqEvalJS(dest, "setOutput(\"" . html64 . "\")")
        catch
        endtry
        let b:vimkonqpandoc_update = 0
    endif
endfunction

function! GetBufContent()
    let bufnr = expand('<bufnr>')
    return join(getbufline(bufnr, 1, "$"),"\n")
endfunction

function! s:IndexHtml()
    return resolve(s:path . "/../static/index.html")
endfunction

function! s:DbusSend(reply, dest, path, int, parm)
    if a:reply
        let reply = "--print-reply"
    else
        let reply = ""
    endif
    return system("dbus-send --type=method_call ".reply." --session --dest=".a:dest." ".a:path." ".a:int." ".a:parm)
endfunction

function! s:KonqEvalJS(dest, js)
    let num = s:KonqFindWidget(a:dest)
    return s:DbusSend(1, a:dest, "/KHTML/".num."/widget", "org.kde.KHTMLPart.evalJS", "string:'" . a:js . "'")
endfunction

function! s:KonqCurrentUrl(dest)
    let location = s:KonqEvalJS(a:dest, "window.location.href")
    return matchstr(location, 'string "\zs.*\ze\1"')
endfunction

function! s:KonqOpenUrl(dest, path)
    call s:DbusSend(0, a:dest, "/konqueror/MainWindow_1", "org.kde.Konqueror.MainWindow.openUrl", "string:" . a:path . " boolean:false")
endfunction

function! s:KonqFindWidget(dest)
    for i in [1,2,3,4,5]
        let intro = s:DbusSend(1, a:dest, "/KHTML/".i, "org.freedesktop.DBus.Introspectable.Introspect", "")
        if !empty(matchstr(intro, "widget"))
            return i
        endif
    endfor
    echohl ErrorMsg | echo "Konqueror widget not found" |echohl None
    throw ""
endfunction

function! s:KonqFindDest()
    let services = s:DbusSend(1, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus.ListNames", "")
    let dest = matchstr(services, '"org.kde.konqueror-\d*"')
    if empty(dest)
        echohl ErrorMsg | echo "Konqueror not running" |echohl None
        throw ""
    endif
    return dest
endfunction
