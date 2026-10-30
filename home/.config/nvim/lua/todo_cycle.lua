local M = {}

local next_state = { [' '] = '/', ['/'] = 'x', x = ' ', X = ' ' }

local function list_item(line)
  local marker, body = line:match('^(%s*[-*+] )(.*)$')
  if marker then return marker, body end
  return line:match('^(%s*%d+[.)] )(.*)$')
end

function M.cycle_line(line)
  local marker, body = list_item(line)
  if marker and body then
    local state, rest = body:match('^%[(.)%](.*)$')
    if state and next_state[state] then
      return marker .. '[' .. next_state[state] .. ']' .. rest
    end
    return marker .. '[ ] ' .. body
  end
  local indent, text = line:match('^(%s*)(.+)$')
  if not text then return line end
  return indent .. '- [ ] ' .. text
end

function M.cycle(first, last)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  for i, line in ipairs(lines) do
    lines[i] = M.cycle_line(line)
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

function M.attach(bufnr)
  vim.keymap.set('n', '<Leader>x', function()
    local row = vim.fn.line('.')
    M.cycle(row, row + vim.v.count1 - 1)
  end, { buffer = bufnr, desc = 'Cycle todo' })
  vim.keymap.set('x', '<Leader>x', function()
    local a, b = vim.fn.line('v'), vim.fn.line('.')
    vim.cmd('normal! \27')
    M.cycle(math.min(a, b), math.max(a, b))
  end, { buffer = bufnr, desc = 'Cycle todo' })
end

return M
