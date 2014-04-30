autocmd FileType pandoc autocmd BufWritePost <buffer> call VimKonqPandoc()

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! VimKonqPandoc()
        let curr = s:VimKonqPandoc_IndexHtml()
        let dest = s:VimKonqPandoc_FindDest()
        if resolve(s:VimKonqPandoc_CurrentUrl(dest)) != "file:" . curr
            call s:VimKonqPandoc_OpenUrl(dest, curr)
        endif
        let html64 = system("cd " . fnamemodify(expand('%'), ':h') . "; pandoc " . fnamemodify(expand('%'), ':t') . " -t " . s:path . "/html_dot.lua | base64 -w0")
        call s:VimKonqPandoc_EvalJS(dest, "setOutput(\"" . html64 . "\")")
endfunction

function! s:DbusSend(reply, dest, path, int, parm)
    if a:reply
        let reply = "--print-reply"
    else
        let reply = ""
    endif
    return system("dbus-send --type=method_call ".reply." --session --dest=".a:dest." ".a:path." ".a:int." ".a:parm)
endfunction

function! s:VimKonqPandoc_IndexHtml()
    return resolve(s:path . "/../static/index.html")
endfunction

function! s:VimKonqPandoc_EvalJS(dest, js)
    let num = s:VimKonqPandoc_FindWidget(a:dest)
    call s:DbusSend(0, a:dest, "/KHTML/".num."/widget", "org.kde.KHTMLPart.evalJS", "string:'" . a:js . "'")
endfunction

function! s:VimKonqPandoc_CurrentUrl(dest)
    let vw = s:DbusSend(1, a:dest, "/konqueror/MainWindow_1", "org.freedesktop.DBus.Properties.Get", "string:org.kde.konqueror.KonqMainWindow string:currentURL")
    return matchstr(vw, 'variant.*string "\zs.*\ze\1"')
endfunction

function! s:VimKonqPandoc_OpenUrl(dest, path)
    call s:DbusSend(0, a:dest, "/konqueror/MainWindow_1", "org.kde.Konqueror.MainWindow.openUrl", "string:" . a:path . " boolean:false")
endfunction

function! s:VimKonqPandoc_FindWidget(dest)
    for i in [1,2,3,4,5]
        let intro = s:DbusSend(1, a:dest, "/KHTML/".i, "org.freedesktop.DBus.Introspectable.Introspect", "")
        if !empty(matchstr(intro, "widget"))
            return i
        endif
    endfor
    echohl ErrorMsg | echo "widget not found" |echohl None
    throw ""
endfunction

function! s:VimKonqPandoc_FindDest()
    let services = s:DbusSend(1, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus.ListNames", "")
    let dest = matchstr(services, '"org.kde.konqueror-\d*"')
    if empty(dest)
        echohl ErrorMsg | echo "konqueror not running" |echohl None
        throw ""
    endif
    return dest
endfunction
