# VimPreviewPandoc

## Introduction

VimPreviewPandoc is VIM plugin that helps you with editing MarkDown-like documents.

Edit your MarkDown documents in VIM and see a nice HTML-based output in `qutebrowser`.
The web browser always shows changed area so you don't need to scroll manually.

## Features

 - Preview your MarkDown documents with `qutebrowser`

    - Scroll browser's view to show changed area automatically
    - Generate `dot` graphs with `graphviz`
    - Generate `blockdiag`, `seqdiag`, `actdiag`, `nwdiag`, `packetdiag`, `rackdiag` graphs
    - Generate `R` graphs
    - Generate PlantUML graphs
    - Generate ascii art based images with `ditaa`

 - Show structural diff of specified file between specified git revisions

    - `:call vimpreviewpandoc#VimPreviewPandocGitDiff(expand("%"), "HEAD~5", "HEAD")`
    - `:Unite giti/log`, press `a` (action), select `diff_pandoc_preview`

        Please see [Unite.vim integration] for required configuration.

 - Generate output document in specified output format

    - `:call vimpreviewpandoc#VimPreviewPandocConvertTo("docx,html")`

## TODO

 - Decouple `pandoc` plugins to a separate project

## Examples

### Supports links

    ```
    [Link to generated image from R](#whatever)
    ```

### *DOT* Graph

This *DOT* code is shown as the following picture in the preview window:

    ```dot
    graph {
    A -- B
    C -- B
    C -- D
    }
    ```

![](.dot/aec7aeb0383414f6b9953047930d7e6a98eba221.png)

### *Blockdiag* Graph

This *DOT* code is shown as the following picture in the preview window:

    ```blockdiag
    blockdiag {
    A -> B -> C
    }
    ```

![](.dot/1a92794a2297a42b1a8c4333a02a2a1fd0ad0531.png)

### *Seqdiag* Graph

This *Seqdiag* code is shown as the following picture in the preview window:

    ```seqdiag
    seqdiag {
      browser  -> webserver [label = "GET /index.html"];
      browser <-- webserver;
      browser  -> webserver [label = "POST /blog/comment"];
                  webserver  -> database [label = "INSERT comment"];
                  webserver <-- database;
      browser <-- webserver;
    }
    ```

![](.dot/ed14e596b4aae2d220c398a53d8348a0e747c47e.png)

### *Actdiag* Graph

This *Actdiag* code is shown as the following picture in the preview window:

    ```actdiag
    actdiag {
      write -> convert -> image

      lane user {
         label = "User"
         write [label = "Writing reST"];
         image [label = "Get diagram IMAGE"];
      }
      lane actdiag {
         convert [label = "Convert reST to Image"];
      }
    }
    ```

![](.dot/b1e11e258d038f18d8ac1c6a6b18507438faf842.png)

### *Nwdiag* Graph

This *Nwdiag* code is shown as the following picture in the preview window:

    ```nwdiag
    nwdiag {
      network dmz {
          address = "210.x.x.x/24"

          web01 [address = "210.x.x.1"];
          web02 [address = "210.x.x.2"];
      }
      network internal {
          address = "172.x.x.x/24";

          web01 [address = "172.x.x.1"];
          web02 [address = "172.x.x.2"];
          db01;
          db02;
      }
    }
    ```

![](.dot/f554ea7bf97fb660fa23931c6b1129f1af825cf9.png)

### *Packetdiag* Graph

This *Packetdiag* code is shown as the following picture in the preview window:

    ```packetdiag
    {
      colwidth = 32
      node_height = 72

      0-15: Source Port
      16-31: Destination Port
      32-63: Sequence Number
      64-95: Acknowledgment Number
      96-99: Data Offset
      100-105: Reserved
      106: URG [rotate = 270]
      107: ACK [rotate = 270]
      108: PSH [rotate = 270]
      109: RST [rotate = 270]
      110: SYN [rotate = 270]
      111: FIN [rotate = 270]
      112-127: Window
      128-143: Checksum
      144-159: Urgent Pointer
      160-191: (Options and Padding)
      192-223: data [colheight = 3]
    }
    ```

![](.dot/bf2856a4c0ead5305f15bd74063717f1df5631d8.png)

### *Rackdiag* Graph

This *Rackdiag* code is shown as the following picture in the preview window:

    ```rackdiag

    rackdiag {
      // define height of rack
      16U;

      // define rack items
      1: UPS [2U];
      3: DB Server
      4: Web Server
      5: Web Server
      6: Web Server
      7: Load Balancer
      8: L3 Switch
    }
    ```

![](.dot/d26aa0f06de6baa647e45b2295901dce690d0711.png)

### *R* Graph

This *R* code is shown as the following picture in the preview window:

    ```{.r #whatever width=9 height=6 caption="R generated output"}
                                  
    y <- c(1,4,9,13,10)     
    x <- c(1,2,3,4, 5 )
    xx <- seq(1, 5, length.out=250)
           
    plot(x, y)

    fit <- lm(y~x)
    label1 <- bquote(italic(R)^2 == .(format(summary(fit)$adj.r.squared, digits=4)))
    lines(xx, predict(fit, data.frame(x=xx)))
    fnc1 <- bquote(y == .(coef(fit)[[2]]) * x + .(coef(fit)[[1]]))

             
    fit <- lm(y~poly(x,3, raw = TRUE))
    label2 <- bquote(italic(R)^2 == .(format(summary(fit)$adj.r.squared, digits=4)))
    lines(xx, predict(fit, data.frame(x=xx)))
    fnc2 <- bquote(y == .(coef(fit)[[4]]) * x^3 + .(coef(fit)[[3]]) * x^2 + .(coef(fit)[[2]]) * x + .  (coef(fit)[[1]]))

    labels <- c(label1, fnc1, label2, fnc2)
    legend("topleft", bty="n", legend=as.expression(labels))
    ```

![](.dot/6c2661f7c930d1580fd1a937d73fdf4a98ff3bb6.png)

### PlantUML

This *PlantUML* code as the following picture in the preview window:

    ```plantuml
    @startuml
    Alice -> Bob: Authentication Request
    Bob --> Alice: Authentication Response

    Alice -> Bob: Another authentication Request
    Alice <-- Bob: another authentication Response
    @enduml
    ```

![](.dot/dba2905531256f9ebf116f41123f91f40a6e51e9.png)

### Ditaa

This *Ditaa* code is shown as the following picture in the preview window:

    ```ditaa
    +--------+   +-------+    +-------+
    |        | --+ ditaa +--> |       | 
    |  Text  |   +-------+    |diagram|
    |Document|   |!magic!|    |       |
    |     {d}|   |       |    |       |
    +---+----+   +-------+    +-------+
        :                         ^
        |       Lots of work      |
        +-------------------------+
    ```

![](.dot/ae322a2246aab824d3548bbdce54194d469ac5a4.png)

## Installation

Install this plugin either manually or using any plugin manager (Vundle, NeoBundle, Plug...).

Make sure that python scripts in *plugin* sub folder (pre.py, blockdiag.py, ...) needs to have executable bit set. This is required by `pandoc` to read its shebang and execute it with python version as specified with the shebang.

Those plugins are required:

- [async.vim](https://github.com/prabirshrestha/async.vim.git)
- [vim-base64](https://github.com/christianrondeau/vim-base64.git)

I also recommend you to install the following plugins to extend `pandoc` support:

- [vim-pandoc](https://github.com/vim-pandoc/vim-pandoc)
- [vim-pandoc-syntax](https://github.com/vim-pandoc/vim-pandoc-syntax.git)
- [vim-pandoc-after](https://github.com/vim-pandoc/vim-pandoc-after.git)

Place your VIM on one side of your screen and when `qutebrowser` appears, move it to the other side to get productive environment. `qutebrowser` shows automatically correct preview.

## Dependencies

 - VIM with python3 support
 - pandoc *1.12.3.3* and newer
 - python3 [pandocfilters](https://github.com/jgm/pandocfilters)

### Structural diff support

 - python2 [htmltreediff](https://github.com/tex/htmltreediff.git)

    `htmltreediff` requires setting of this environment variable to `PYTHONIOENCODING=UTF-8`

 - optionally [unite.vim](https://github.com/Shougo/unite.vim.git) with [vim-unite-giti](https://github.com/kmnk/vim-unite-giti.git)

### Dot graph support

 - [graphviz](http://www.graphviz.org)

### Diag-family graphs support

 - [blockdiag](http://blockdiag.com/en/blockdiag/index.html)
 - [seqdiag](http://blockdiag.com/en/seqdiag/index.html)
 - [actdiag](http://blockdiag.com/en/actdiag/index.html)
 - [nwdiag](http://blockdiag.com/en/nwdiag/index.html)

### R graph support

 - [R](http://r-project.org)

### PlantUML

 - [PlantUML](https://github.com/plantuml/plantuml)

### Ditaa

 - [Ditaa](https://github.com/stathissideris/ditaa.git)

### Qutebrowser

 - [Qutebrowser](https://qutebrowser.org)

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

        let file  = len(a:candidates[0].action__file) > 0
                    \               ? a:candidates[0].action__file
                    \               : expand('%:p')
        let relative_path = giti#to_relative_path(file)
        if len(a:candidates) == 1
            let from = a:candidates[0].action__data.hash
            call vimpreviewpandoc#VimPreviewPandocGitDiff(relative_path, from)
        elseif len(a:candidates) == 2
            let to   = a:candidates[0].action__data.hash
            let from = a:candidates[1].action__data.hash
            call vimpreviewpandoc#VimPreviewPandocGitDiff(relative_path, from, to)
        else
            call unite#print_error('select up to two commits')
            return
        endif
    endfunction

    call unite#custom#action('giti/log', 'diff_pandoc_preview', s:pandoc_diff_action)
    unlet s:pandoc_diff_action

endif
```

## Theory of operation

 `BufwinEnter`, `CursorHold,CusrsorHildI` events execute the following:

 - `pandoc` to convert MarkDown document to HTML

    - custom filter to create a `graphviz` graphs from *dot* code blocks
    - custom filter to create a `blockdiag`, `seqdiag`, `actdiag`, `nwdiag`, `packetdiag`, `rackdiag` graphs from *blockdiag*, *seqdiag*, *actdiag*, *nwdiag*, *packetdiag*, *rackdiag* blocks
    - custom filter to create a `R` generated graphs from *R* code blocks
    - custom filter to create a `plantuml` generated graphics from *planuml* code blocks
    - custom filter to create a `ditaa` generated graphics from *ditaa* code blocks
    - custom filter to fix block code view in `qutebrowser`
    - custom filter to replace relative paths to images to absolute paths

    - qutebrowser

        - `qutebrowser` uses a socket to talk to already running instance
        - this allows to execute JavaScript on loaded page

 - index.html is empty page with `setCursor(word, count)` and `setOutput(html)` functions

     - `setCursor(word, count)` finds the encoded position and scrolls window to it
     - `setOutput(html)` replaces the content of the `div` with a new one
