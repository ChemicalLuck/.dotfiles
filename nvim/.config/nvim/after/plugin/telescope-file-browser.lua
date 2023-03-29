local status, telescope = pcall(require, 'telescope')
if not status then
    return
end

telescope.load_extension("file_browser")
vim.keymap.set('n', '<leader>fb', ':Telescope file_browser<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fb', ':Telescope file_browser path=%:p:h select_buffer=true<cr>', { noremap = true })
