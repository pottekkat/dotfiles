return {
  'github/copilot.vim',
  keys = {
    {
      '<leader>tp',
      function()
        local copilot_enabled = vim.g.copilot_enabled
        if copilot_enabled == nil or copilot_enabled then
          vim.cmd('Copilot disable')
          vim.g.copilot_enabled = false
          print('Copilot disabled')
        else
          vim.cmd('Copilot enable')
          vim.g.copilot_enabled = true
          print('Copilot enabled')
        end
      end,
      desc = '[T]oggle Co[p]ilot'
    }
  }
}
