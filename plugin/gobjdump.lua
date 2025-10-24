vim.api.nvim_create_user_command("Gobjdump", require("gobjdump").dump, { nargs = "?" })

vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(0)
    local basename = vim.fs.basename(filename)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local func = require("gobjdump").func_name(bufnr) or ""

    local src_buf = vim.api.nvim_get_current_buf()
    local src_ft = vim.bo[src_buf].filetype

    if src_ft ~= "go" then
      return
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "objdump" then
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            require("gobjdump").sync_cursor(win, filename, basename, cursor, func)
            return
          end
        end
      end
    end
  end,
})
