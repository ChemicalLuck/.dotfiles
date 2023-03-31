local status, treesitter = pcall(require "nvim-treesitter.configs")
if not status then
    return
end

treesitter.setup {
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
    ensure_installed = {
        "help",
        "javascript",
        "typescript",
        "c",
        "lua",
        "rust",
        "python"
    },
    auto_install = true,
}
