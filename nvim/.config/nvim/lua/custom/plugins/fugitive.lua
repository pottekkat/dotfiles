-- `dq` in the :Git status buffer is supposed to tear down the diff opened by
-- `dv`/`dd`/`ds`, but it only ever closes one of the two windows and leaves the
-- fugitive:// blob behind -- so you end up :q-ing windows by hand to get back to
-- your own buffers.
--
-- fugitive#DiffClose() snapshots window *numbers*, then closes windows inside
-- the loop. Closing the first one fires fugitive's own BufWinLeave autocmd
-- (autoload/fugitive.vim), which runs `diffoff!` as soon as the diffset is down
-- to two windows. The loop then re-reads &diff on the next window, sees the
-- flag it just had cleared for it, and skips the close:
--
--     BEFORE: windows=3 diffflags=[0, 1, 1]
--     mywinnr=1 loop_order=[3, 3, 2, 1]
--       visit win3: diff=1 -> CLOSE
--         closed. windows now=2 diffflags=[0, 0]   <- cleared here
--       visit win2: diff=0 -> skip                 <- so it never closes
--     AFTER: windows=2
--
-- Reported upstream as tpope/vim-fugitive#2196, which tpope closed by rewording
-- the docs (d0c1a43, "Clarify dq behavior", doc/fugitive.txt only). DiffClose()
-- and that autocmd have not been touched since, so this stays broken.
--
-- Pressing `dq` from the status window is nonetheless the intended flow -- see
-- tpope in #2030: "Look at the cursor. The status window, not the diff window,
-- is focused." It is also the only place `dq` exists; despite what the docs
-- imply, neither diff window gets the mapping, not even the fugitive-owned one.
--
-- The replacement below takes the whole diffset in one pass up front and never
-- re-reads &diff, so fugitive clearing the flag underneath it cannot make it
-- skip a window. Reading the flag live is not safe even when only fugitive://
-- windows are closed: `dv` on a *staged* entry diffs the index against HEAD, so
-- both sides are fugitive:// and closing the first one blanks the second.
--
-- Derived from swarn's workaround in #2196.
local function diff_close()
  local diffset = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_get_option_value('diff', { win = win }) then
      local buf = vim.api.nvim_win_get_buf(win)
      table.insert(diffset, {
        win = win,
        buf = buf,
        -- The status buffer is fugitive:// too, but never in diff mode, so it
        -- is already excluded above.
        blob = vim.startswith(vim.api.nvim_buf_get_name(buf), 'fugitive://'),
      })
    end
  end

  for _, entry in ipairs(diffset) do
    if entry.blob and vim.api.nvim_win_is_valid(entry.win) then
      vim.api.nvim_win_close(entry.win, false)

      -- Closing the window leaves the blob loaded and listed, so it lingers in
      -- :ls and the Telescope buffers picker long after the diff is gone. Only
      -- wipe it once nothing is displaying it -- `dv` on a staged entry can put
      -- the same blob in two windows.
      if vim.api.nvim_buf_is_valid(entry.buf) and #vim.fn.win_findbuf(entry.buf) == 0 then
        vim.api.nvim_buf_delete(entry.buf, { force = true })
      end
    end
  end

  -- Drops diff mode on the working-tree window that is left. Redundant when the
  -- autocmd above already fired, but not when it did not -- a three-way conflict
  -- diff starts with three windows and never hits its `== 2` condition.
  vim.cmd 'diffoff!'

  -- Land back on the file being diffed rather than in the status window, which
  -- is where the diff was being read anyway. Nothing to do for a staged diff:
  -- both sides were blobs and both are now gone.
  for _, entry in ipairs(diffset) do
    if not entry.blob and vim.api.nvim_win_is_valid(entry.win) then
      vim.api.nvim_set_current_win(entry.win)
      break
    end
  end
end

-- Tear the whole thing down: the diff, the blobs, and the status window, ending
-- up on the file that was being diffed.
--
-- `dq` cannot do this on its own, because fugitive only installs it in its own
-- buffers -- so it does nothing in the working-tree window, which is where `dv`
-- leaves the cursor. Reaching it means hopping back to the status window first,
-- then `gq` to dismiss that as well. This collapses the round trip into one key
-- that works from anywhere in the layout.
local function close_all()
  local origin = vim.api.nvim_get_current_win()

  diff_close()

  -- Whichever window we end up keeping, remember it before the status windows
  -- go, so focus does not land somewhere arbitrary.
  local keep = vim.api.nvim_get_current_win()

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'fugitive' then
      -- Only close the window when it is not the last one, otherwise fall back
      -- to swapping the buffer out so the tabpage survives.
      if #vim.api.nvim_tabpage_list_wins(0) > 1 then
        vim.api.nvim_win_close(win, false)
      elseif vim.fn.bufnr '#' ~= -1 then
        vim.cmd 'buffer #'
      end
      if vim.api.nvim_buf_is_valid(buf) and #vim.fn.win_findbuf(buf) == 0 then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end

  for _, win in ipairs { keep, origin } do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

return {
  'tpope/vim-fugitive',
  config = function()
    -- Global rather than buffer-local: the whole point is that it works from the
    -- diff window too, which is not a fugitive buffer. Set here rather than in a
    -- `keys` block, because adding lazy-load triggers to this spec would defer
    -- the plugin -- and `:G` has to exist before any of these keys get pressed.
    vim.keymap.set('n', '<leader>gq', close_all, { desc = '[G]it diff and status [Q]uit' })

    -- Buffer-local, so it shadows fugitive's own `dq` rather than fighting it,
    -- and only inside the buffers where fugitive installs it in the first place.
    vim.api.nvim_create_autocmd('FileType', {
      desc = 'Fix fugitive dq leaving a diff window behind',
      group = vim.api.nvim_create_augroup('custom-fugitive-diff-close', { clear = true }),
      pattern = 'fugitive',
      callback = function(event)
        vim.keymap.set('n', 'dq', diff_close, {
          buffer = event.buf,
          desc = 'Close the fugitive diff',
        })
      end,
    })
  end,
}
