local ts_utils = require('nvim-treesitter.ts_utils')

---@class Config
---@field command function The command to run objdump
---@field build table Build options
---@field dump table Dump options
local config = {
    build = {
        output = "main.o",
        gcflags = "",
    },
    dump = {
        tool = "go tool objdump",
        output = "objdump.txt",
        args = {},
    }
}

---@class Gobjdump
local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end


M.lines = {}

M.func_name = function(bufnr)
  local expr = ts_utils.get_node_at_cursor()

  while expr do
    if expr:type() == 'function_declaration' then
        break
    end
    expr = expr:parent()
  end
  if not expr then return "" end

  return (vim.treesitter.get_node_text(expr:child(1), bufnr))
end

M.sync_cursor = function(win, filename, basename, cursor, func)
  local new_cursor = 1
  local escaped_filename = filename:gsub("([/%.-])", "%%%1")
  local file_pattern = "^TEXT.-" .. func .. "%(SB%).-" .. escaped_filename
  local line_pattern = "^%s%s("..basename.."):("..cursor..")"
  local break_pattern = "^TEXT.-"

  for i, v in ipairs(M.lines) do
    if string.match(v, file_pattern) then
      new_cursor = i
      for j = i+1, #M.lines do
        local line = M.lines[j]
        if string.match(line, line_pattern) then
          new_cursor = j
          goto done
        end
        if string.match(line, break_pattern) then
          break
        end
      end
    end
  end

  ::done::

  vim.api.nvim_win_set_cursor(win, {new_cursor, 0})
end

M.dump = function(details)
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(0)
    local basename = vim.fs.basename(filename)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local func = M.func_name(bufnr) or ""

    vim.cmd('rightbelow vnew')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {"hello"})
    vim.opt_local.modified = false
    vim.wo.statuscolumn = ""
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.bo.filetype = "objdump"

    local win = vim.api.nvim_get_current_win()

    local command = string.format("!go build -o %s -gcflags=\"%s\" %s && %s %s %s > %s",
        config.build.output,
        config.build.gcflags,
        details.fargs[1],
        config.dump.tool,
        config.build.output,
        table.concat(config.dump.args, " "),
        config.dump.output
    )

    vim.api.nvim_exec(command, true)

    local file = io.open(M.config.dump.output, "r")
    if not file then
        print("Failed to open objdump.txt")
        return
    end

    local content = file:read("*a")
    file:close()

    M.lines = vim.split(content, '\n', { plain = true })

    vim.api.nvim_buf_set_lines(0, 0, -1, false, M.lines)

    M.sync_cursor(win, filename, basename, cursor, func)
end

return M
