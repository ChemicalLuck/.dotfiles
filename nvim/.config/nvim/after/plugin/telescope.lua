local status, telescope = pcall(require, 'telescope.builtin')
if not status then
    return
end

vim.keymap.set('n', '<leader>pf', telescope.find_files, {})
vim.keymap.set('n', '<C-p>', telescope.git_files, {})
vim.keymap.set('n', '<leader>ps', telescope.live_grep, {})
vim.keymap.set('n', '<leader>ph', telescope.help_tags, {})
vim.keymap.set('n', '<leader>pb', telescope.buffers, {})
