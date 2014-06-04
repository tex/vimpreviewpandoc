# VimPreviewPandoc

## Introduction

VimPreviewPandoc is VIM plugin that helps with editing MarkDown-like documents.

Edit you MarkDown-like documents in VIM and see a nice HTML-based output in Konqueror or Firefox.
The web browser always shows changed area so you don't need to scroll manually.

Add `let g:vimkonqpandoc = 1` to your `.vimrc` to set Konqueror as previewer.
Add `let g:vimfirepandoc = 1` to your `.vimrc` to set Firefox as previewer.

Place your VIM on one side of your screen and web browser on the other side to get
productive environment.

The Konqueror shows automatically correct preview, when using Firefox you have to manually open `static/index.html` for first time.

![Screenshot](screen-1.png)

## Dependencies

 - VIM with Python support
 - vimproc [https://github.com/Shougo/vimproc]()
 - python2
 - pandoc *1.12.3.3*
 - pandocfilters [https://github.com/jgm/pandocfilters]()
 - graphviz

### Konqueror

 - Konqueror *4.13.0*
 - python2 dbus

### Firefox

 - Firefox
 - Remote Control extension [https://addons.mozilla.org/en-US/firefox/addon/remote-control]()

## Theory of operation

 `BufWritePost` event executes following:

 - `pandoc` to convert MarkDown document to HTML

    - custom filter to create a graphviz graphs from `dot` code blocks
    - custom filter to replace relative paths to images to absolute paths

    - Konqueror

        - `DBUS` to control Konqueror
        - open `static/index.html` if not already opened
        - pass `pandoc` output to the Konqueror using `DBUS` call `org.kde.KHTMLPart.evalJS`

    - Firefox

        - `Remote Control` extension to control Firefox
        - pass `pandoc` output to the Firefox using `Remote Control` (TCP socket, default parameters)

        both browsers evaluate JavaScript function `setOutput(html)` where html is `base64` encoded output from `pandoc`

 - index.html is almost empty page with one `div` and `setOutput(html)` function

     function creates a `DOM` from the `html` parameter, compares it with what already is in the `div`, computes offset of first difference, updates the `div` with new output and scrolls window to it

