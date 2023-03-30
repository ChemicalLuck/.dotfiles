local status, gitsigns = pcall(require, 'gitsigns')
if not status then
    return
end

gitsigns.setup {
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
        end, { expr = true })

        map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
        end, { expr = true })

        map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<cr>', { desc = "Stage Hunk" })
        map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<cr>', { desc = "Reset Hunk" })
        map('n', '<leader>hS', gs.stage_buffer, { desc = "Stage Buffer" })
        map('n', '<leader>hu', gs.undo_stage_hunk, { desc = "Undo Stage Hunk" })
        map('n', '<leader>hR', gs.reset_buffer, { desc = "Reset Buffer" })
        map('n', '<leader>hp', gs.preview_hunk, { desc = "Preview Hunk" })
        map('n', '<leader>hb', function() gs.blame_line { full = true } end, { desc = "Show Line Blame" })
        map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = "Toggle Current Line Blame" })
        map('n', '<leader>hd', gs.diffthis, { desc = "Diff This" })
        map('n', '<leader>td', gs.toggle_deleted, { desc = "Toggle Deleted" })
    end
}
