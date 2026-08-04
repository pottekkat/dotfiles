-- <c-hjkl> moves between nvim splits and, once there is no split left that way,
-- out into the surrounding multiplexer.
--
-- vim-tmux-navigator only covers the tmux half of that. With $TMUX unset it
-- falls back to a plain wincmd and stops dead at the edge, which is what happens
-- inside herdr. herdr marks its panes with $HERDR_PANE_ID, so the herdr branch
-- below does what the plugin does with `tmux select-pane`, using the herdr CLI.
--
-- The other direction is handled in ~/.config/herdr/scripts/herdr-nav: herdr
-- binds ctrl+hjkl, sees nvim in the foreground, and forwards the key here rather
-- than moving the focus itself.

local directions = {
  h = { wincmd = 'h', tmux = 'TmuxNavigateLeft', herdr = 'left' },
  j = { wincmd = 'j', tmux = 'TmuxNavigateDown', herdr = 'down' },
  k = { wincmd = 'k', tmux = 'TmuxNavigateUp', herdr = 'up' },
  l = { wincmd = 'l', tmux = 'TmuxNavigateRight', herdr = 'right' },
}

-- A remote attach (`herdr --remote box --session box`) puts the server under a
-- named session, whose socket lives in sessions/<name>/ instead of at the
-- default path. The bare CLI keeps looking at the default socket and answers
-- server_not_running, so the pane hop below silently does nothing. Resolve the
-- session when there is no default server and exactly one candidate; anything
-- ambiguous falls back to the default rather than guessing.
local function herdr_cmd()
  local base = vim.fn.expand '~/.config/herdr'
  if vim.uv.fs_stat(base .. '/herdr.sock') then
    return { 'herdr' }
  end

  local sessions = vim.fn.glob(base .. '/sessions/*/herdr.sock', true, true)
  if #sessions == 1 then
    return { 'herdr', '--session', vim.fn.fnamemodify(sessions[1], ':h:t') }
  end

  return { 'herdr' }
end

local function navigate(key)
  local dir = directions[key]

  return function()
    if vim.env.TMUX then
      vim.cmd(dir.tmux)
      return
    end

    -- wincmd is silent when there is nothing that way, so compare the window
    -- before and after to find out whether we are at the edge.
    local before = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(dir.wincmd)
    if vim.api.nvim_get_current_win() ~= before then
      return
    end

    local pane = vim.env.HERDR_PANE_ID
    if pane then
      local cmd = herdr_cmd()
      vim.list_extend(cmd, { 'pane', 'focus', '--direction', dir.herdr, '--pane', pane })
      vim.system(cmd)
    end
  end
end

return {
  'christoomey/vim-tmux-navigator',
  -- Without this the plugin defines its own <c-hjkl> mappings on load, and
  -- since lazy loads it *from* the first keypress, those land on top of the
  -- ones below before the key is replayed. Only the commands are wanted here.
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
    'TmuxNavigatePrevious',
    'TmuxNavigatorProcessList',
  },
  keys = {
    { '<c-h>', navigate 'h', desc = 'Go to the left window or pane' },
    { '<c-j>', navigate 'j', desc = 'Go to the lower window or pane' },
    { '<c-k>', navigate 'k', desc = 'Go to the upper window or pane' },
    { '<c-l>', navigate 'l', desc = 'Go to the right window or pane' },
    { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
  },
}
