vim.cmd [[packadd packer.nvim]]

local status, packer = pcall(require, "packer")
if not status then
    return
end

packer.startup(function(use)
    -- Package manager
    use('wbthomason/packer.nvim')

    use('github/copilot.vim')

    -- Fuzzy finder
    use {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.0',
        requires = {
            { 'nvim-lua/plenary.nvim' }
        }
    }
    use {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
            return vim.fn.executable == 1
        end
    }
    use {
        'nvim-telescope/telescope-file-browser.nvim',
        requires = {
            { 'nvim-telescope/telescope.nvim' },
            { 'nvim-lua/plenary.nvim' }
        }
    }

    -- Colorscheme
    use('loctvl842/monokai-pro.nvim')

    -- Syntax highlighting, editing, and navigating
    use {
        'nvim-treesitter/nvim-treesitter',
        { run = ':TSUpdate' }
    }
    use('nvim-treesitter/nvim-treesitter-context')

    -- Git
    use('tpope/vim-fugitive')
    use('lewis6991/gitsigns.nvim')

    -- Language Server Protocol
    use {
        'VonHeikemen/lsp-zero.nvim',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }

    -- Statusline
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }

    -- helper
    use("folke/which-key.nvim")

    -- "gc" to comment visual regions/lines
    use {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end
    }

    use('lukas-reineke/indent-blankline.nvim')

    if packer_bootstrap then
        require('packer').sync()
    end
end)
