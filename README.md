# VimKonqPandoc

## Introduction

VimKonqPandoc is VIM plugin that helps with editing MarkDown-like documents.

Edit you MarkDown-like documents in VIM and see a nice HTML-based output in Konqueror.
Konqueror always shows changed area so you don't need to scroll manually.

Place your VIM on one side of your screen and Konqueror on the other side to get
productive environment.

## Dependencies

 - pandoc
 - base64
 - dbus-send
 - konqueror

Please, note that there cannot be a `-` character anywhere in the path to this plugin.
Please, note that all characters in path to this plugin must be lowercase.

We use a custom writer feature of `pandoc`(*1.12.3.3*) which incorrectly parses it's input parameters and incorrectly recognizes the `-` character there as beginning of a parameter. It also incorrectly changes the path to lowercase.

## Theory of operation

 `BufWritePost` event executes following:

 - `pandoc` to convert MarkDown document to HTML

    custom writer to create a graphviz graphs from `dot` code blocks

 - base64 to encode pandoc output to be passable through DBUS
 - `DBUS` to control Konqueror
    - open `static/index.html` if not already opened
    - pass `pandoc` output to the Konqueror using `DBUS` call `org.kde.KHTMLPart.evalJS`

        evaluate JavaScript function `setOutput(html)` where html is `base64` encoded output from `pandoc`

 - index.html is almost empty page with one `div` and `setOutput(html)` function

     function creates a `DOM` from the `html` parameter, compares it with what already is in the `div`, computes offset of first difference, updates the `div` with new output and scrolls window to it

