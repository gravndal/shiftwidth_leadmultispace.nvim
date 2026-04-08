local api = vim.api

local bo, go, wo = vim.bo, vim.go, vim.wo
local v = vim.v

local nvim_get_current_buf = api.nvim_get_current_buf
local nvim_list_wins = api.nvim_list_wins
local nvim_win_get_buf = api.nvim_win_get_buf

local char = vim.g.indentLine_char or '┊'

local function lms(rep)
  return string.format(
    'leadmultispace:%s%s',
    char,
    string.rep(' ', rep > 0 and rep - 1 or 0)
  )
end

local function update(old, rep)
  return old:gsub('leadmultispace:[^,]*', lms(rep))
end

local function update_curbuf()
  local curbuf = nvim_get_current_buf()
  for _, w in ipairs(nvim_list_wins()) do
    if nvim_win_get_buf(w) == curbuf then
      wo[w].listchars = update(wo[w].listchars, bo.shiftwidth)
    end
  end
end

local group = api.nvim_create_augroup('ShiftwidthLeadmultispace', {})

-- Sync with 'shiftwidth'.
api.nvim_create_autocmd('OptionSet', {
  pattern = 'shiftwidth',
  group = group,
  callback = function()
    if v.option_type ~= 'local' then
      go.listchars = update(go.listchars, go.shiftwidth)
    end
    update_curbuf()
  end,
})

-- Update 'listchars' when displaying buffer in a window.
api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  callback = function()
    wo.listchars = update(wo.listchars, bo.shiftwidth)
  end,
})

-- Handle cases where 'filetype' is set after BufWinEnter.
api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function()
    update_curbuf()
  end,
})

-- Define toggle :command.
api.nvim_create_user_command('IndentGuidesToggle', function()
  if wo.listchars:match('leadmultispace') then
    vim.opt_local.listchars:remove('leadmultispace')
    vim.opt_local.listchars:remove('leadtab')
  else
    vim.opt_local.listchars:append(lms(bo.shiftwidth))
    vim.opt_local.listchars:append(string.format('leadtab:%s ', char))
  end
end, {})

-- Set global defaults.
vim.opt_global.listchars:append(lms(go.shiftwidth))
vim.opt_global.listchars:append(string.format('leadtab:%s ', char))
