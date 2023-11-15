-- openfolds.lua
vim.api.nvim_create_autocmd({ 'BufReadPost', 'FileReadPost' }, {
  group = vim.api.nvim_create_augroup('kickstart-openfolds', { clear = true }),
  command = 'normal zR'
})
