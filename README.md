# VimPreviewPandoc

## Introduction

VimPreviewPandoc is VIM plugin that helps you with editing MarkDown-like documents.

Edit your MarkDown documents in VIM and see a nice HTML-based output in Konqueror or Firefox.
The web browser always shows changed area so you don't need to scroll manually.

## Features

 - Preview your markdown documents with Konqueror or Firefox

    - Scroll browser's view to show changed area automatically
    - Generate `dot` graphs with `graphviz`
    - Generate `blockdiag`, `seqdiag`, `actdiag`, `nwdiag` graphs

 - Show structural diff of specified file between specified git revisions

    - `:call VimPreviewPandocGitDiff(expand("%"), "HEAD~5", "HEAD")`
    - `:Unite giti/log`, a (action), *diff_pandoc_preview*

 - Generate output document in specified output format

    `:call VimPreviewPandocConvertTo("docx,html")`


## Todo

- Add support for plotting

    - python2 [matplotlib]()?
    - [gnuplot]()?

## Installation

Install this plugin either manually or using any plugin manager (Vundle, NeoBundle, ...).

I also recommend you to install the following plugins to extend pandoc support:

- [vim-pantondoc](https://github.com/vim-pandoc/vim-pantondoc)
- [vim-pandoc-syntax](https://github.com/vim-pandoc/vim-pandoc-syntax.git)
- [vim-pandoc-after](https://github.com/vim-pandoc/vim-pandoc-after.git)

Add `autocmd BufNewFile,BufRead *.md set filetype=pandoc` to your `.vimrc` if not using `vim-pantondoc` which sets it.

Place your VIM on one side of your screen and manually start a web browser on the other side to get productive environment.

Konqueror shows automatically correct preview. With Firefox you have to manually open `static/index.html` for first time.

![Screenshot](screen-1.png)

## Dependencies

 - VIM with Python2 support
 - pandoc *1.12.3.3*
 - pyhton2 [pandocfilters](https://github.com/jgm/pandocfilters)

### Structural diff support

 - python2 [htmltreediff](https://github.com/PolicyStat/htmltreediff.git)
 - optionally [unite.vim](https://github.com/Shougo/unite.vim.git) and [vim-unite-giti](https://github.com/kmnk/vim-unite-giti.git)

### Dot block support

 - [graphviz](http://www.graphviz.org)

### Diag block support

 - [blockdiag](http://blockdiag.com/en/blockdiag/index.html)
 - [seqdiag](http://blockdiag.com/en/seqdiag/index.html)
 - [actdiag](http://blockdiag.com/en/actdiag/index.html)
 - [nwdiag](http://blockdiag.com/en/nwdiag/index.html)

### Konqueror

 - Konqueror *4.13.0*
 - python2 dbus

### Firefox

 - Firefox
 - [Remote Control extension](https://addons.mozilla.org/en-US/firefox/addon/remote-control)

## Unite.vim integration

Add the following code to your *.vimrc* to add *diff_pandoc_preview* action to *vim-unite-giti*'s *giti-log*.

```vimrc
if neobundle#tap("unite.vim")
            \ && neobundle#tap("vim-unite-giti")
            \ && neobundle#tap("vimpreviewpandoc")

    function! s:is_graph_only_line(candidate)
        return has_key(a:candidate.action__data, 'hash') ? 0 : 1
    endfunction

    let s:pandoc_diff_action = {
        \ 'description' : 'pandoc diff with vimpreviewpandoc',
        \ 'is_selectable' : 1,
        \ 'is_quit' : 1,
        \ 'is_invalidate_cache' : 0,
        \ }
    function! s:pandoc_diff_action.func(candidates)
        if s:is_graph_only_line(a:candidates[0])
                    \ || len(a:candidates) > 1 && s:is_graph_only_line(a:candidates[1])
            call giti#print('graph only line')
            return
        endif

        let from  = ''
        let to    = ''
        let file  = len(a:candidates[0].action__file) > 0
                    \               ? a:candidates[0].action__file
                    \               : expand('%:p')
        let relative_path = giti#to_relative_path(file)
        if len(a:candidates) == 1
            let to   = a:candidates[0].action__data.hash
            let from = a:candidates[0].action__data.parent_hash
        elseif len(a:candidates) == 2
            let to   = a:candidates[0].action__data.hash
            let from = a:candidates[1].action__data.hash
        else
            call unite#print_error('too many commits selected')
            return
        endif

        call VimPreviewPandocGitDiff({
                    \   'file' : relative_path,
                    \   'from' : from,
                    \   'to'   : to,
                    \ })
    endfunction

    call unite#custom#action('giti/log', 'diff_pandoc_preview', s:pandoc_diff_action)
    unlet s:pandoc_diff_action

endif
```

## Theory of operation

 `BufwinEnter`, `CursorHold,CusrsorHildI` events execute the following:

 - `pandoc` to convert MarkDown document to HTML

    - custom filter to create a `graphviz` graphs from *dot* code blocks
    - custom filter to create a `blockdiag`, `seqdiag`, `actdiag`, `nwdiag` graphs from *blockdiag*, *seqdiag*, *actdiag*, *nwdiag* blocks
    - custom filter to replace relative paths to images to absolute paths

    - Konqueror

        - `DBUS` to control Konqueror
        - open `static/index.html` if not already opened
        - pass pandoc output to the Konqueror using `DBUS` call `org.kde.KHTMLPart.evalJS`

    - Firefox

        - `Remote Control` extension to control Firefox
        - pass pandoc output to the Firefox using `Remote Control` (TCP socket, default parameters)

        Both browsers evaluate JavaScript functions `setCursor(word, count)` where word and count is encoded position and `setOutput(html)` where html is output from pandoc

 - index.html is empty page with `setCursor(word, count)` `setOutput(html)` functions

     - `setCursor(word, count)` finds the encoded position and scrolls window to it
     - `setOutput(html)` replaces the content of the `div` with a new one
