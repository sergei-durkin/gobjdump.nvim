# Gobjdump

Neovim plugin for analyzing Go code through `objdump`. Allows you to view disassembled machine code of a function directly in the editor with source code line synchronization.

## Features

- Compile Go projects with custom compilation flags
- Generate disassembled output using `go tool objdump`
- Display results in a separate editor window
- Automatic cursor position synchronization between source code and disassembly
- Find the current function in the disassembled code

## Installation

### Using a package manager (e.g., lazy.nvim)

```lua
{
  "sergei-durkin/gobjdump.nvim",
  ft = "go",
  config = function()
    require("gobjdump").setup()
  end,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
}
```

## Configuration

```lua
require("gobjdump").setup({
  build = {
    output = "main.o",           -- Output filename for compilation
    gcflags = "-N -l",           -- Compilation flags (disable optimization/inlining)
  },
  dump = {
    tool = "go tool objdump",    -- Command for disassembly
    output = "objdump.txt",      -- Temporary output file
    args = { "-s=main.main" },   -- Additional objdump arguments
  }
})
```

## Usage

After installation and configuration, use the command:

```vim
:Gobjdump [package path]
```

For example:

```vim
:Gobjdump ./cmd/main.go
:Gobjdump .
```

## Dependencies

- Neovim (0.7+)
- Go
- `go tool objdump` (included in the standard Go toolset)
- nvim-treesitter

## License

MIT
