if has("python3")

let g:vimpreviewpandoc_document = ""

function! s:qutebrowser_set_output(stdout)
python3 << EOF
import vim
import base64
data = "setOutput('" +
            \ base64.b64encode(vim.eval("join(a:stdout, '\n')").encode("utf-8")).decode("utf-8") +
            \ "')"
vim.command('let cmd = "' + data + '"')
EOF
call s:qutebrowser_exec(cmd)
endfunction

function! s:qutebrowser_set_output_with_log(file, stdout)
    call writefile(a:stdout, a:file)
    call s:qutebrowser_set_output(a:stdout)
endfunction

function! vimpreviewpandoc#VimPreviewPandoc()
    if !exists('b:vimpreviewpandoc_changedtick')
        \ || b:vimpreviewpandoc_changedtick != b:changedtick
        if g:vimpreviewpandoc_document != expand('%:p')
            let b:qutebrowser_open = 1
            let g:vimpreviewpandoc_document = expand('%:p')
        endif
        let cmd = s:pandoc_argv() + [expand('%:p')]
        call s:start(cmd, function('s:qutebrowser_set_output'))
    endif
    let b:vimpreviewpandoc_changedtick = b:changedtick
endfunction

function! vimpreviewpandoc#VimPreviewScrollTo()
python3 << EOF
import vim
vim.command('let cmd = "' + FindPosition() + '"')
EOF
if len(cmd) > 0
    call s:qutebrowser_exec(cmd)
endif
endfunction

function! s:ignore_output(stdout)
    echo "Done"
endfunction

function! vimpreviewpandoc#VimPreviewPandocConvertTo(ext)
    let cmd = s:pandoc_argv() + [expand('%:p'), '-o ' + expand('%:p') + a:ext]
    call s:start(cmd, function('s:ignore_output'))
endfunction

function! s:gd1(stdout)
    let s:gd1_o = a:stdout
endfunction

function! s:gd2(stdout)
    let s:gd2_o = a:stdout
endfunction


function! vimpreviewpandoc#VimPreviewPandocGitDiff(file, from, to)
    let id1 = s:start(['git', 'show', a:from . ':' . a:file], function('s:gd1'))
    let id2 = s:start(['git', 'show', a:to . ':' . a:file], function('s:gd2'))
    call async#job#wait([id1, id2])
    call writefile(s:gd1_o, a:file.'.'.a:from)
    call writefile(s:gd2_o, a:file.'.'.a:to)
    let id3 = s:start(s:pandoc_argv() + [a:file.'.'.a:from, '-o'.a:file.'.html.'.a:from], function('s:ignore_output'))
    let id4 = s:start(s:pandoc_argv() + [a:file.'.'.a:to, '-o'.a:file.'.html.'.a:to], function('s:ignore_output'))
    call async#job#wait([id3, id4])
    call s:start(["python", "-m", "htmltreediff.cli", a:file.'.html.'.a:from, a:file.'.html.'.a:to], 
                \ function('s:qutebrowser_set_output_with_log', [a:file.'.html.'.a:from.'.'.a:to]))
endfunction

let s:path = expand('<sfile>:p:h').'/..'

function! s:qutebrowser_exec(data)
    if exists('b:qutebrowser_open')
        unlet b:qutebrowser_open
        let argv = ['qutebrowser', ':open '.s:path.'/static/index.html']
        let res = async#job#start(argv, {})
        execute 'sleep 1000m'
    endif
    let argv = ['qutebrowser', ':jseval --quiet --world 0 '.a:data]
    let res = async#job#start(argv, {})
endfunction

let s:output = []
let s:error = 0

function! s:on_stderr(job_id, data, event_type)
    let s:output = s:output + a:data
    let s:error = 1
endfunction

function! s:on_stdout(job_id, data, event_type)
    let s:output = s:output + a:data
endfunction

function! s:on_exit(callback, job_id, data, event_type)
    if s:error == 1
        echom join(s:output, '\n')
    else
        call a:callback(s:output)
    endif
    let s:output = []
endfunction

function! s:pandoc_argv()
    return ['pandoc',
                \ '--ascii',
                \ '--filter='.s:path.'/plugin/graphviz.py',
                \ '--filter='.s:path.'/plugin/blockdiag.py',
                \ '--filter='.s:path.'/plugin/R.py',
                \ '--filter='.s:path.'/plugin/plantuml.py',
                \ '--filter='.s:path.'/plugin/ditaa.py',
                \ '--filter='.s:path.'/plugin/pre.py',
                \ '--filter='.s:path.'/plugin/realpath.py',
                \ '--number-section']
endfunction

function! s:start(cmd, callback)
    let s:output = []
    let s:error = 0
    return async#job#start(a:cmd, {
                \ 'on_exit': function('s:on_exit', [a:callback]),
                \ 'on_stdout': function('s:on_stdout'),
                \ 'on_stderr': function('s:on_stderr'),
                \ })
endfunction

python3 << EOF
import base64

def FindPosition():
    wordUnderCursor = vim.eval("expand('<cword>')")
    if len(wordUnderCursor) >= 3:
        cb = vim.current.buffer
        (row, col) = vim.current.window.cursor
        count = 0
        inBlock = False
        for i in range(0, row):
            line = cb[i]
            if line[0:3] == '```':
                if inBlock:
                    inBlock = not inBlock
                elif line[0:6] == '```dot' \
                    or line[0:4] == '```R' \
                    or line[0:8] == '```ditaa' \
                    or line[0:11] == '```plantuml' \
                    or line[0:12] == '```blockdiag' \
                    or line[0:10] == '```seqdiag' \
                    or line[0:10] == '```actdiag' \
                    or line[0:9] == '```nwdiag':
                    inBlock = True
            if i == row - 1:                # last line?
                if inBlock:                 #  in a block?
                    return ""               #   not found
                line = line[0:col]          #  limit line to cursor's position column
            else:
                if inBlock:                 #  in a block?
                    continue                #   skip the line
            if i + 1 < row \
                and cb[i+1].count("{.bookmark") \
                and cb[i+1][0] == "#":              # next line follows?
                                                    # is that line a bookmark?
                continue                            #  skip current line
            count += line.count(wordUnderCursor)
        # add one because the cursor's position column always trims the
        # word under cursor so it won't be found with line.count(...)
        count += 1
        return "setCursor('" +
                    \  base64.b64encode(
                    \   wordUnderCursor.encode("utf-8")).decode("utf-8") +
                    \  "', " + str(count) + ")" 
    else:
        return ""
EOF

else
echoerr "VimPreviewPandoc: Python3 support required!"
endif
