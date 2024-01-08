local char = 'leadmultispace:' .. (vim.g.indentLine_char or '┊')

local function lms(rep)
  return char .. string.rep(' ', rep > 0 and rep - 1 or 0)
end

local function update(old, rep)
  return old:gsub('leadmultispace:[^,]*', lms(rep))
end

local group = vim.api.nvim_create_augroup('ShiftwidthLeadmultispace', {})

-- Sync with 'shiftwidth'.
vim.api.nvim_create_autocmd('OptionSet', {
  pattern = 'shiftwidth',
  group = group,
  callback = function()
    if vim.v.option_type == 'local' then
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(w) == vim.api.nvim_get_current_buf() then
          vim.wo[w].listchars = update(vim.wo[w].listchars, vim.bo.shiftwidth)
        end
      end
    else
      vim.go.listchars = update(vim.go.listchars, vim.go.shiftwidth)
    end
  end,
})

-- Update 'listchars' when displaying buffer in a window.
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  callback = function()
    vim.wo.listchars = update(vim.wo.listchars, vim.bo.shiftwidth)
  end,
})

-- Define toggle :command.
vim.api.nvim_create_user_command('IndentGuidesToggle', function()
  if vim.wo.listchars:match('leadmultispace') then
    vim.opt_local.listchars:remove('leadmultispace')
  else
    vim.opt_local.listchars:append(lms(vim.bo.shiftwidth))
  end
end, {})

-- Set global default.
vim.opt_global.listchars:append(lms(vim.go.shiftwidth))
