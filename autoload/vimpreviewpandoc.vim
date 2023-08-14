function! vimpreviewpandoc#Preview()
    if !exists('b:vimpreviewpandoc_changedtick')
        \ || b:vimpreviewpandoc_changedtick != b:changedtick
        let cmd = s:pandoc_argv() + [expand('%:p')]
        call s:start(cmd, function('s:after_pandoc', [expand('%:p').".html"]))
    endif
    let b:vimpreviewpandoc_changedtick = b:changedtick
endfunction

function! vimpreviewpandoc#PreviewForce()
    if exists('b:vimpreviewpandoc_browser')
        unlet b:vimpreviewpandoc_browser
    endif
    if exists('b:vimpreviewpandoc_changedtick')
        unlet b:vimpreviewpandoc_changedtick
    endif
    call vimpreviewpandoc#Preview()
endfunction

function! vimpreviewpandoc#ConvertTo(ext)
    let cmd = s:pandoc_argv() + [expand('%:p'), '-o ' + expand('%:p') + a:ext]
    call s:start(cmd, function('s:ignore_output', ["Pandoc conversion finished!"]))
endfunction


function! s:after_pandoc(file, data)
    " epiphany does automatically refresh local html file
    call writefile(a:data, a:file)
    " open epiphany if not opened for this buffer
    " will open a new tab if epiphany is already opened
    if !exists('b:vimpreviewpandoc_browser')
        let b:vimpreviewpandoc_browser = 1
        let argv = ['epiphany', a:file]
        let res = async#job#start(argv, {})
    endif
endfunction

function! s:ignore_output(message, data)
    if len(a:message) > 0
        echo a:message
    endif
endfunction

let s:path = expand('<sfile>:p:h') . '/..'

function! s:pandoc_argv()
    return ['pandoc',
                \ '--ascii',
                \ '--lua-filter='.s:path.'/pandoc/pikchr.lua',
                \ '--filter='.s:path.'/pandoc/graphviz.py',
                \ '--filter='.s:path.'/pandoc/blockdiag.py',
                \ '--filter='.s:path.'/pandoc/R.py',
                \ '--filter='.s:path.'/pandoc/plantuml.py',
                \ '--filter='.s:path.'/pandoc/ditaa.py',
                \ '--filter='.s:path.'/pandoc/pre.py',
                \ '--filter='.s:path.'/pandoc/realpath.py',
                \ '--number-section']
endfunction

let s:jobs = {}

function! s:new_job(job_id)
    let s:jobs[a:job_id] = {
                \ 'data' : [],
                \ 'error' : 0
                \ }
endfunction

function! s:on_stderr(job_id, data, event_type)
    if !has_key(s:jobs, a:job_id)
        call s:new_job(a:job_id)
    endif
    if strlen(join(a:data, '')) > 0
        let s:jobs[a:job_id].data += a:data
        let s:jobs[a:job_id].error = 1
    endif
endfunction

function! s:on_stdout(job_id, data, event_type)
    if !has_key(s:jobs, a:job_id)
        call s:new_job(a:job_id)
    endif
    let s:jobs[a:job_id].data += a:data
endfunction

function! s:on_exit(callback, job_id, data, event_type)
    if !has_key(s:jobs, a:job_id)
        call s:new_job(a:job_id)
    endif
    if s:jobs[a:job_id].error == 1
        echom join(s:jobs[a:job_id].data, '\n')
    endif
    call a:callback(s:jobs[a:job_id].data)
    call remove(s:jobs, a:job_id)
endfunction

function! s:start(cmd, callback)
    return async#job#start(a:cmd, {
                \ 'on_exit': function('s:on_exit', [a:callback]),
                \ 'on_stdout': function('s:on_stdout'),
                \ 'on_stderr': function('s:on_stderr'),
                \ })
endfunction
