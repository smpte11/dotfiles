local M = {}

local ns = vim.api.nvim_create_namespace('task_progress')

local function marker_type(node)
  for child in node:iter_children() do
    local t = child:type()
    if t == 'task_list_marker_checked' or t == 'task_list_marker_unchecked' then
      return t
    end
  end
end

local function count_children(item)
  local done, total = 0, 0
  for child in item:iter_children() do
    if child:type() == 'list' then
      for li in child:iter_children() do
        if li:type() == 'list_item' then
          local m = marker_type(li)
          if m == 'task_list_marker_checked' then
            done = done + 1; total = total + 1
          elseif m == 'task_list_marker_unchecked' then
            total = total + 1
          end
        end
      end
    end
  end
  return done, total
end

local function render(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'markdown')
  if not ok or not parser then return end
  local tree = (parser:parse() or {})[1]
  if not tree then return end

  local function walk(node)
    if node:type() == 'list_item' and marker_type(node) then
      local done, total = count_children(node)
      if total > 0 then
        local row, col = node:start()
        local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
        local hl = (done == total) and 'DiagnosticOk' or 'Comment'
        vim.api.nvim_buf_set_extmark(bufnr, ns, row, #line, {
          virt_text = { { string.format(' [%d/%d]', done, total), hl } },
          virt_text_pos = 'eol',
          hl_mode = 'combine',
          priority = 200,
        })
        _ = col
      end
    end
    for child in node:iter_children() do walk(child) end
  end

  walk(tree:root())
end

local timers = {}

local function schedule(bufnr, delay)
  local t = timers[bufnr]
  if t then t:stop(); t:close() end
  t = vim.uv.new_timer()
  timers[bufnr] = t
  t:start(delay or 60, 0, vim.schedule_wrap(function()
    if timers[bufnr] then timers[bufnr]:close(); timers[bufnr] = nil end
    render(bufnr)
  end))
end

function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.b[bufnr].task_progress_attached then return end
  vim.b[bufnr].task_progress_attached = true

  render(bufnr)

  local group = vim.api.nvim_create_augroup('task_progress_' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedP' }, {
    group = group, buffer = bufnr,
    callback = function() schedule(bufnr, 40) end,
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave' }, {
    group = group, buffer = bufnr,
    callback = function() schedule(bufnr, 0) end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group, buffer = bufnr,
    callback = function()
      local t = timers[bufnr]
      if t then t:stop(); t:close(); timers[bufnr] = nil end
    end,
  })
end

return M
