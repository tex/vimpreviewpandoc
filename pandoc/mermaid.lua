-- Pandoc filter to process code blocks with class "mermaid" containing
-- mermaid markup into SVG images.
--
-- * Assumes mermaid is present on the path.
--
-- https://pandoc.org/lua-filters.html#converting-abc-code-to-music-notation

local function mermaid(markup)
    local svg = pandoc.pipe("mmdc", {"-i", "-", "-o", "-", "-e", "svg"}, markup)
    return svg
end

local function save(fname, img)
    local f = assert(io.open(fname, "w"))
    f:write(img)
    f:close()
end

function CodeBlock(block)
    if block.classes[1] == "mermaid" then
        local img = mermaid(block.text)
        local fname = '.dot/' .. pandoc.sha1(img) .. "." .. "svg"
        save(fname, img)
        return pandoc.Para{pandoc.Image({pandoc.Str("mermaid diagram")}, fname)}
    end
end
