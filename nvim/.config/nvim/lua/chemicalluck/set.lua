local opt = vim.opt
local g = vim.g

-- Line numbers
opt.nu = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- search patterns
opt.ignorecase = true
opt.smartcase = true

opt.wrap = false

opt.swapfile = false
opt.backup = false

opt.termguicolors = true
opt.background = "dark"

opt.scrolloff = 8
opt.signcolumn = "yes"
opt.isfname:append("@-@")

opt.colorcolumn = "80"

opt.updatetime = 50

g.mapleader = " "

opt.shortmess:append "I"
