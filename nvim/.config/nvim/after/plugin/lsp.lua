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


    nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ctions")

    nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
    nmap("gt", vim.lsp.buf.type_defintion, "[G]oto [T]ype Definition")
    nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

    nmap("K", vim.lsp.buf.hover(), "Hover Docs")
    name("<C-k>", vim.lsp.buf.signature_help, "Signature Docs")

    nmap("<leader>vd", vim.diagnostic.open_float, "[V}iew [D]iagnostic")
    nmap("<leader>ld", vim.diagnostic.setloclist, "[L]ist [D]iagnostics")
    nmap("[d", vim.diagnostic.goto_prev, "Cycle Prev Diagnostic")
    nmap("]d", vim.diagnostic.goto_next, "Cycle  Next Diagnostic")

    nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
    nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
    nmap("<leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "[W]orkspace [L]ist Folders")
end)

lsp.setup()

vim.diagnostic.config({
    virtual_text = true
})
