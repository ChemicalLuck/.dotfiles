local status, lsp = pcall(require, "lsp-zero")
if not status then
    return
end
local cmp_status, cmp = pcall(require, "cmp")
if not cmp_status then
    return
end

lsp.preset("recommended")

lsp.ensure_installed({
    'tsserver',
    'eslint',
    'rust_analyzer',
    'pyright'
})

local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space'] = cmp.mapping.complete(),
})

lsp.set_preferences({
    sign_icons = {}
})

lsp.setup_nvim_cmp({
    mapping = cmp_mappings
})

lsp.on_attach(function(client, bufnr)
    lsp.buffer_autoformat()

    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end,
        { buffer = bufnr, remap = false, desc = "Goto Definition" })
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, { buffer = bufnr, remap = false, desc = "Show Hover" })
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end,
        { buffer = bufnr, remap = false, desc = "Search Workspace Symbols" })
    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end,
        { buffer = bufnr, remap = false, desc = "Open Diagnostic" })
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end,
        { buffer = bufnr, remap = false, desc = "Cycle Next Diagnostic" })
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end,
        { buffer = bufnr, remap = false, desc = "Cycle Prev Diagnostic" })
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end,
        { buffer = bufnr, remap = false, desc = "Show Code Actions" })
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end,
        { buffer = bufnr, remap = false, desc = "Find References" })
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end,
        { buffer = bufnr, remap = false, desc = "Rename Symbol" })
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end,
        { buffer = bufnr, remap = false, desc = "Signature Help" })
end)

lsp.setup()

vim.diagnostic.config({
    virtual_text = true
})
