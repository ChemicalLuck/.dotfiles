local status, monokai_pro = pcall(require, 'monokai-pro')
if not status then
    return
end

monokai_pro.setup({
    transparent_background = false,
    terminal_colors = true,
    devicons = true, -- highlight the icons of `nvim-web-devicons`
    styles = {
        comment = { italic = true },
        keyword = { italic = true },       -- any other keyword
        type = { italic = true },          -- (preferred) int, long, char, etc
        storageclass = { italic = true },  -- static, register, volatile, etc
        structure = { italic = true },     -- struct, union, enum, etc
        parameter = { italic = true },     -- parameter pass in function
        annotation = { italic = true },
        tag_attribute = { italic = true }, -- attribute of tag in reactjs
    },
    filter = "spectrum",                   -- classic | octagon | pro | machine | ristretto | spectrum
    -- Enable this will disable filter option
    day_night = {
        enable = false,            -- turn off by default
        day_filter = "spectrum",   -- classic | octagon | pro | machine | ristretto | spectrum
        night_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
    },
    inc_search = "background",     -- underline | background
    background_clear = {
        "which-key",
        "float_win"
    }, -- "float_win", "toggleterm", "telescope", "which-key", "renamer", "neo-tree"
    plugins = {
    },
})

vim.cmd('colorscheme monokai-pro')