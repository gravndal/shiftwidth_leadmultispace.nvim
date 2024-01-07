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

-- Toggle with 'diff', as combined highligting doesn't look good.
local function diff_reversed()
  for _, e in ipairs({
    'DiffAdd',
    'DiffChange',
    'DiffDelete',
    'DiffText',
  }) do
    if vim.api.nvim_get_hl(0, { name = e }).reverse then return true end
  end
end

local function diff_toggle()
  if
    diff_reversed()
    and vim.wo.diff
    and vim.wo.listchars:match('leadmultispace')
  then
    vim.w.__lms = true
    vim.opt_local.listchars:remove('leadmultispace')
  elseif vim.w.__lms and not (diff_reversed() and vim.wo.diff) then
    vim.opt_local.listchars:append(lms(vim.bo.shiftwidth))
    vim.w.__lms = nil
  end
end

vim.api.nvim_create_autocmd('OptionSet', {
  pattern = 'diff',
  group = group,
  callback = diff_toggle,
})

vim.api.nvim_create_autocmd('ColorScheme', {
  group = group,
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.wo[win].diff then vim.api.nvim_win_call(win, diff_toggle) end
    end
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

-- Set global default (unless `nvim -d foo bar`).
if not (diff_reversed() and vim.o.diff) then
  vim.opt.listchars:append(lms(vim.o.shiftwidth))
end
