# xcode-build-server.nvim ⚙️

A Neovim plugin that seamlessly integrates `xcode-build-server` to enable `sourcekit-lsp` support for Xcode projects. This allows iOS/macOS developers to use Neovim with full LSP capabilities for Swift, C, C++, Objective-C, and Objective-C++ development.

## ⚠️ Before you dive in

For a comprehensive iOS/macOS development setup in Neovim, you'll need more than just this plugin. Check out [The Complete Guide to iOS & macOS Development in Neovim](https://wojciechkulik.pl/ios/the-complete-guide-to-ios-macos-development-in-neovim) by [Wojciech Kulik](https://github.com/wojciech-kulik) for the complete setup including:

- Swift syntax highlighting and treesitter configuration
- Proper LSP setup with `sourcekit-lsp`
- Debugging configuration with `nvim-dap`
- Testing integration
- Code formatting and linting
- And much more!

This guide is the best-in-class resource for getting a fully functional iOS development environment in Neovim.

This plugin offers a streamlined way to integrate and generate necessary configurations for `xcode-build-server`, which is essential for enabling `sourcekit-lsp` support in Neovim.

## Features

- 🔍 **Automatic Project Discovery**: Finds Xcode projects and workspaces in your directory tree
- 🎯 **Scheme Selection**: Interactive picker for available build schemes
- ⚙️ **Configuration Generation**: Automatically creates `buildServer.json` for `sourcekit-lsp`
- 🔄 **LSP Integration**: Seamless integration with Neovim's built-in LSP client
- 🏥 **Health Checks**: Built-in diagnostics to verify your setup
- 🚀 **Auto Setup**: Optional automatic configuration when opening Xcode projects (opt-in)

## Requirements

- Neovim >= 0.8.0
- [xcode-build-server](https://github.com/SolaWing/xcode-build-server) (install via: `brew install xcode-build-server`)
- Xcode or Xcode Command Line Tools
- `sourcekit-lsp` (usually included with Xcode)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'okwasniewski/xcode-build-server.nvim',
  ft = { 'swift', 'objc', 'objcpp' },
  config = function()
    require('xcode-build-server').setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'okwasniewski/xcode-build-server.nvim',
  config = function()
    require('xcode-build-server').setup()
  end
}
```

## Configuration

The plugin works out of the box with sensible defaults. You can customize it by passing options to the setup function:

```lua
require('xcode-build-server').setup({
  search_depth = 3,           -- How deep to search for projects
  timeout = 10000,            -- Command timeout in milliseconds
  auto_setup = false,         -- Auto-setup when opening Xcode projects (opt-in)
  restart_lsp = true,         -- Restart LSP after configuration
  build_server_path = "xcode-build-server",  -- Path to executable
  picker = {
    backend = "vim_ui",       -- Options: "vim_ui", "telescope", "fzf"
    telescope = {
      theme = "dropdown",
      layout_config = {
        width = 0.8,
        height = 0.6,
      }
    },
    fzf = {
      winopts = {
        width = 0.8,
        height = 0.6,
      }
    }
  }
})
```

### Picker Configuration

The plugin supports multiple picker backends for selecting projects and schemes:

#### Default vim.ui.select

```lua
require('xcode-build-server').setup({
  picker = {
    backend = "vim_ui"  -- Default Neovim picker
  }
})
```

#### Telescope Integration

Requires [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim):

```lua
require('xcode-build-server').setup({
  picker = {
    backend = "telescope",
    telescope = {
      theme = "dropdown",     -- or "ivy", "cursor", etc.
      layout_config = {
        width = 0.8,
        height = 0.6,
        preview_cutoff = 120,
      }
    }
  }
})
```

#### FZF-lua Integration

Requires [fzf-lua](https://github.com/ibhagwan/fzf-lua):

```lua
require('xcode-build-server').setup({
  picker = {
    backend = "fzf",
    fzf = {
      winopts = {
        width = 0.8,
        height = 0.6,
        border = "rounded",
      }
    }
  }
})
```

The plugin automatically falls back to `vim.ui.select` if the configured picker is not available.

### Auto Setup (Optional)

By default, the plugin requires manual setup using `:XcodeBuildServerSetup`. You can enable automatic configuration by setting `auto_setup = true`:

```lua
require('xcode-build-server').setup({
  auto_setup = true  -- Enable automatic buildServer.json generation
})
```

When enabled, auto setup will:

- Automatically detect Xcode projects when you open files
- For single scheme projects: configure silently
- For multiple schemes: prompt you to select a scheme using your configured picker
- Skip projects that already have buildServer.json

## Usage

### Interactive Setup

Run the setup command to configure `xcode-build-server` for your project:

```vim
:XcodeBuildServerSetup
```

This will:

1. Find available Xcode projects/workspaces
2. Let you select a project
3. Let you select a scheme
4. Generate `buildServer.json` configuration
5. Optionally restart LSP clients

### Check Status

View current configuration status:

```vim
:XcodeBuildServerStatus
```

### Restart LSP

Restart `sourcekit-lsp` clients after configuration changes:

```vim
:XcodeBuildServerRestart
```

## How it Works

The plugin bridges the gap between Apple's `sourcekit-lsp` and Xcode projects by:

1. **Project Discovery**: Scans your directory tree for `.xcodeproj` and `.xcworkspace` files
2. **Scheme Detection**: Uses `xcodebuild -list` to find available build schemes
3. **Configuration Generation**: Creates a `buildServer.json` file that tells `sourcekit-lsp` how to communicate with `xcode-build-server`
4. **LSP Integration**: Works with Neovim's built-in LSP client for features like:
   - Code completion
   - Diagnostics
   - Go to definition
   - Symbol search
   - And more!

## Troubleshooting

### LSP features aren't working

- Ensure `sourcekit-lsp` is installed (comes with Xcode)
- Restart LSP clients with `:XcodeBuildServerRestart`
- Check `:XcodeBuildServerStatus` for configuration issues

### "`xcode-build-server` not found" error

Install `xcode-build-server` via Homebrew:

```bash
brew install xcode-build-server
```

### No schemes found

- Ensure your Xcode project is valid
- Try opening the project in Xcode first to verify schemes exist
- Check that you're in the correct directory

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT
