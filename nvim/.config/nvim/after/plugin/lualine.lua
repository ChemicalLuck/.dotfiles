local status, lualine = pcall(require, 'lualine')
if not status then
    return
end

lualine.setup{
  options = {
    icons_enabled = false,
    theme = 'auto',
    component_separators = { left = '|', right = '|'},
    section_separators = '',
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = false,
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch'},
    lualine_c = {
        {
            'buffers',
            filetype_name = {
                TelescopePrompt = 'Telescope',
                packer = 'Packer'
            }
        }
    },
    lualine_x = {'diagnostics', 'encoding', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {"fugitive"}
}

vim.keymap.set('n', "<leader><Tab>", "<Cmd>:bn<cr>")
vim.keymap.set('n', "<leader><S-Tab>", "<Cmd>:bp<cr>")
