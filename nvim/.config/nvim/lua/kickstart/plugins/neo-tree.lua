-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal right<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    -- Applies to every source, so netrw hijacking (`nvim <dir>`, which opens the
    -- tree before `\` is ever pressed) lands on the same side as the keymap.
    window = {
      position = 'right',
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
