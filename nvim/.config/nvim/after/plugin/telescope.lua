local status, telescope = pcall(require, 'telescope')
if not status then
    return
end

telescope.setup {
    extensions = {
        file_browser = {
            hijack_netrw = true,
        }
    },
    defaults = {
        borderchars = { "█", " ", "▀", "█", "█", " ", " ", "▀" },
    },
}

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Find existing [b]uffers' })
vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telecope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
    })
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = "[G]rep [F]iles" })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })

vim.keymap.set('n', 'gr', builtin.lsp_references, { desc = '[G]oto [R]eferences'})

vim.keymap.set('n', '<leader>ds', builtin.lsp_document_symbols, { desc = '[D]ocument [S]ymbols' })
vim.keymap.set('n', '<leader>ws', builtin.lsp_dynamic_workspace_symbols, { desc = '[W]orkspace [S]ymbols' })


telescope.load_extension('file_browser')

vim.keymap.set('n', '<leader>fb', ':Telescope file_browser path=%:p:h select_buffer=true<cr>',
    { noremap = true, desc = "Show File Browser" })
