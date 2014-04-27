" autocmd BufWritePost <buffer> source %

autocmd FileType pandoc autocmd BufWritePost <buffer> call VimPandocRefresh()

let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

" type = method_call | signal
" reply = 0 | 1
function! DbusSend(type, reply, dest, path, int, parm)
    if a:reply
        let reply = "--print-reply"
    else
        let reply = ""
    endif

    return system("dbus-send --type=".a:type." ".reply." --session --dest=".a:dest." ".a:path." ".a:int." ".a:parm)
endfunction

function! VimKonquerorIndex()
    return resolve(s:path . "/../static/index.html")
endfunction

function! VimPandocRefresh()
    try
        let dest = VimKonquerorFindDest()
        let aa = VimKonquerorIndex()
        if resolve(VimKonquerorCurrentUrl(dest)) != "file:" . aa
            call VimKonquerorOpen(dest, aa)
        endif
        let html64 = system("pandoc " . expand('%') . " -t " . s:path . "/sample.lua | base64 -w0")
        call VimKonquerorExecuteJS(dest, "setOutput(\"" . html64 . "\")")
    catch
    endtry
endfunction


function! VimKonquerorExecuteJS(dest, js)
    let num = VimKonquerorFindWidget(a:dest)
    call DbusSend("method_call", 0, a:dest, "/KHTML/".num."/widget", "org.kde.KHTMLPart.evalJS", "string:'" . a:js . "'")
endfunction

function! VimKonquerorCurrentUrl(dest)
    let vw = DbusSend("method_call", 1, a:dest, "/konqueror/MainWindow_1", "org.freedesktop.DBus.Properties.Get", "string:org.kde.konqueror.KonqMainWindow string:currentURL")
    return matchstr(vw, 'variant.*string "\zs.*\ze\1"')
endfunction

" Apparently currentView is something different that current KHTML instance
function! VimKonquerorCurrentView(dest)
    let view = DbusSend("method_call", 1, a:dest, "/konqueror/MainWindow_1", "org.kde.Konqueror.MainWindow.currentView", "")
    return matchstr(view, '"/konqueror/MainWindow_1/\zs.*\ze\1"')
endfunction

function! VimKonquerorOpen(dest, path)
    call DbusSend("method_call", 0, a:dest, "/konqueror/MainWindow_1", "org.kde.Konqueror.MainWindow.openUrl", "string:" . a:path . " boolean:false")
endfunction

function! VimKonquerorRefresh(dest)
    call DbusSend("method_call", 0, a:dest, "/konqueror/MainWindow_1", "org.kde.Konqueror.MainWindow.reload", "")
endfunction

function! VimKonquerorFindWidget(dest)
    for i in [1,2,3,4,5]
        let intro = DbusSend("method_call", 1, a:dest, "/KHTML/".i, "org.freedesktop.DBus.Introspectable.Introspect", "")
        if !empty(matchstr(intro, "widget"))
            return i
        endif
    endfor
    echohl WarningMsg | echo "widget not found" |echohl None
    throw ""
endfunction

function! VimKonquerorFindDest()
    let services = DbusSend("method_call", 1, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus.ListNames", "")
    let dest = matchstr(services, '"org.kde.konqueror-\d*"')
    if empty(dest)
        echohl WarningMsg | echo "konqueror not running" |echohl None
        throw ""
    endif
    return dest
endfunction
