-- Pandoc filter to process code blocks with class "pikchr" containing
-- pikchr markup into SVG images.
--
-- * Assumes pikchr is present on the path.
--
-- https://pandoc.org/lua-filters.html#converting-abc-code-to-music-notation

local function pikchr(markup)
    local svg = pandoc.pipe("pikchr", {"--svg-only", "-"}, markup)
    return svg
end

local function save(fname, img)
    local f = assert(io.open(fname, "w"))
    f:write(img)
    f:close()
end

function CodeBlock(block)
    if block.classes[1] == "pikchr" then
        local img = pikchr(block.text)
        local fname = '.dot/' .. pandoc.sha1(img) .. "." .. "svg"
        save(fname, img)
        return pandoc.Para{pandoc.Image({pandoc.Str("pikchr diagram")}, fname)}
    end
end
