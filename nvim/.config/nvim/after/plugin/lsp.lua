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

    local nmap = function(keys, func, desc)
        if desc then
            desc = 'LSP: ' .. desc
        end
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end


    nmap('<leader>rn', function() vim.lsp.buf.rename() end, '[R]e[n]ame')
    nmap('<leader>ca', function() vim.lsp.buf.code_action() end, '[C]ode [A]ction')

    nmap('gd', function() vim.lsp.buf.definition() end, '[G]oto [D]efinition')
    nmap('gI', function() vim.lsp.buf.implementation() end, '[G]oto [I]mplementation')
    nmap('<leader>D', function() vim.lsp.buf.type_definition() end, 'Goto Type [D]efinition')
    nmap('gD', function() vim.lsp.buf.declaration() end, '[G]oto [D]eclaration')

    nmap('K', function() vim.lsp.buf.hover() end, 'Hover Documentation')
    nmap('<C-k>', function() vim.lsp.buf.signature_help() end, 'Signature Documentation')

    nmap('[d', function() vim.diagnostic.goto_prev() end, "Cycle Prev Diagnostic")
    nmap(']d', function() vim.diagnostic.goto_next() end, "Cycle Next Diagnostic")

    nmap('<leader>wa', function() vim.lsp.buf.add_workspace_folder() end, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', function() vim.lsp.buf.remove_workspace_folder() end, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')
end)

lsp.setup()

vim.diagnostic.config({
    virtual_text = true
})
