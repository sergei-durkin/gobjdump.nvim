local ts_utils = require("nvim-treesitter.ts_utils")

---@class Config
---@field command function The command to run objdump
---@field build table Build options
---@field dump table Dump options
local config = {
  build = {
    output = "main.o",
    args = {},
  },
  dump = {
    tool = "go tool objdump",
    output = "objdump.txt",
    args = {},
  },
}

---@class Gobjdump
local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.hm_index = {}

M.func_name = function(bufnr)
  local node = ts_utils.get_node_at_cursor()
  if not node then
    return nil
  end

  while node do
    local type = node:type()
    if type == "function_declaration" or type == "method_declaration" then
      local name_node = node:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, bufnr)
      end
    end
    node = node:parent()
  end

  return nil
end

M.sync_cursor = function(win, filename, basename, cursor, func)
  if
    not M.hm_index[filename]
    or not M.hm_index[filename][func]
    or not M.hm_index[filename][func][basename]
    or not M.hm_index[filename][func][basename][cursor]
  then
    return
  end

  local func_line = M.hm_index[filename][func][basename][cursor].line

  vim.api.nvim_win_set_cursor(win, { func_line, 0 })
end

M.index = function(lines)
  local file_pattern = "^TEXT"
  local files = {}

  for i, v in ipairs(lines) do
    if string.match(v, file_pattern) then
      -- local func, path = string.match(v, "TEXT%s+([^(]+%b())%s+(.+)")
      local func, path = string.match(v, "%.([^.%(]+)%b()%s+(.+)")
      if func and path then
        if not files[path] then
          files[path] = {}
        end

        if not files[path][func] then
          files[path][func] = {}
        end

        files[path][func][0] = { line = i }

        for j = i + 1, #lines do
          local next_line = lines[j]
          if string.match(next_line, file_pattern) then
            break
          end

          local basename, line = string.match(next_line, "([%w_%.%-]+):(%d+)")
          if basename and line then
            if not files[path][func][basename] then
              files[path][func][basename] = {}
            end
            files[path][func][basename][tonumber(line)] = { line = j }
          end
        end
      end
    end
  end

  M.hm_index = files
end

M.dump = function(details)
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(0)
  local basename = vim.fs.basename(filename)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local func = M.func_name(bufnr) or ""

  local command = string.format(
    "!go build -o %s %s %s && %s %s %s > %s",
    M.config.build.output,
    table.concat(M.config.build.args, " "),
    details.fargs[1],
    M.config.dump.tool,
    M.config.build.output,
    table.concat(M.config.dump.args, " "),
    M.config.dump.output
  )

  vim.cmd("rightbelow vnew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { command })

  vim.opt_local.modified = false
  vim.wo.statuscolumn = ""
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.bo.filetype = "objdump"

  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_exec(command, true)

  local file = io.open(M.config.dump.output, "r")
  if not file then
    print("Failed to open objdump.txt")
    return
  end

  local content = file:read("*a")
  file:close()

  local lines = vim.split(content, "\n", { plain = true })
  M.index(lines)

  table.insert(lines, 1, "")
  table.insert(lines, 1, command)

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  M.sync_cursor(win, filename, basename, cursor, func)
end

return M
