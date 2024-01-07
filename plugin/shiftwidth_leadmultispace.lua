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
      vim.wo.listchars = update(vim.wo.listchars, vim.bo.shiftwidth)
    else
      vim.o.listchars = update(vim.o.listchars, vim.o.shiftwidth)
    end
  end,
})

-- OptionSet isn't triggered on startup, nor when switching to an already
-- visible buffer with :b. A side effect of this autocmd is that we will
-- sometimes update the window local 'listchars' twice on :edit, I can't be
-- bothered to optimise this as it doesn't really matter.
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
vim.opt.listchars:append(lms(vim.o.shiftwidth))
