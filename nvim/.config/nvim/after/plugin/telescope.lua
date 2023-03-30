local status, telescope = pcall(require, 'telescope')
if not status then
    return
end

telescope.setup {
    extensions = {
        file_browser = {
            hijack_netrw = true,
        }
    }
}

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "Find Project Files" })
vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = "Find Tracked Files" })
vim.keymap.set('n', '<leader>ps', builtin.live_grep, { desc = "Grep Files" })
vim.keymap.set('n', '<leader>ph', builtin.help_tags, { desc = "Help Tags" })
vim.keymap.set('n', '<leader>pb', builtin.buffers, { desc = "Show Buffers" })

telescope.load_extension('file_browser')

vim.keymap.set('n', '<leader>fb', ':Telescope file_browser path=%:p:h select_buffer=true<cr>',
{ noremap = true, desc = "Show File Browser" })
