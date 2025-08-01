local config = require('xcode-build-server.config')

describe('config', function()
  before_each(function()
    -- Reset config for each test
    config.setup()
  end)

  describe('setup', function()
    it('uses defaults when no options provided', function()
      config.setup()
      local cfg = config.get()

      assert.equals(3, cfg.search_depth)
      assert.equals(10000, cfg.timeout)
      assert.is_false(cfg.auto_setup)
      assert.is_true(cfg.restart_lsp)
      assert.equals('xcode-build-server', cfg.build_server_path)
    end)

    it('overrides defaults with provided options', function()
      config.setup({
        search_depth = 5,
        timeout = 15000,
        auto_setup = true,
        restart_lsp = false,
      })

      local cfg = config.get()
      assert.equals(5, cfg.search_depth)
      assert.equals(15000, cfg.timeout)
      assert.is_true(cfg.auto_setup)
      assert.is_false(cfg.restart_lsp)
    end)

    it('deep merges nested options', function()
      config.setup({
        picker = {
          backend = 'telescope',
          telescope = {
            theme = 'ivy',
          },
        },
      })

      local cfg = config.get()
      assert.equals('telescope', cfg.picker.backend)
      assert.equals('ivy', cfg.picker.telescope.theme)
      -- Should preserve other default telescope options
      assert.equals(0.8, cfg.picker.telescope.layout_config.width)
    end)
  end)

  describe('generate_buildserver_config', function()
    it('generates config for xcodeproj', function()
      -- Mock utils.execute_command to return a success response
      local original_execute = require('xcode-build-server.utils').execute_command
      require('xcode-build-server.utils').execute_command = function(cmd, opts)
        assert.is_not_nil(cmd:find('-project'))
        assert.is_not_nil(cmd:find('TestApp.xcodeproj'))
        assert.is_not_nil(cmd:find('-scheme'))
        assert.is_not_nil(cmd:find('TestScheme'))
        return '{"buildServer": "config"}', nil
      end

      local result = config.generate_buildserver_config('/path/to/TestApp.xcodeproj', 'TestScheme')
      assert.equals('{"buildServer": "config"}', result)

      -- Restore original function
      require('xcode-build-server.utils').execute_command = original_execute
    end)

    it('generates config for xcworkspace', function()
      -- Mock utils.execute_command to return a success response
      local original_execute = require('xcode-build-server.utils').execute_command
      require('xcode-build-server.utils').execute_command = function(cmd, opts)
        assert.is_not_nil(cmd:find('-workspace'))
        assert.is_not_nil(cmd:find('TestApp.xcworkspace'))
        assert.is_not_nil(cmd:find('-scheme'))
        assert.is_not_nil(cmd:find('TestScheme'))
        return '{"buildServer": "config"}', nil
      end

      local result =
        config.generate_buildserver_config('/path/to/TestApp.xcworkspace', 'TestScheme')
      assert.equals('{"buildServer": "config"}', result)

      -- Restore original function
      require('xcode-build-server.utils').execute_command = original_execute
    end)

    it('handles command failure', function()
      -- Mock utils.execute_command to return failure
      local original_execute = require('xcode-build-server.utils').execute_command
      require('xcode-build-server.utils').execute_command = function(cmd, opts)
        return nil, 'Command failed'
      end

      local result = config.generate_buildserver_config('/path/to/TestApp.xcodeproj', 'TestScheme')
      assert.is_nil(result)

      -- Restore original function
      require('xcode-build-server.utils').execute_command = original_execute
    end)

    it('works without scheme name', function()
      -- Mock utils.execute_command
      local original_execute = require('xcode-build-server.utils').execute_command
      require('xcode-build-server.utils').execute_command = function(cmd, opts)
        assert.is_nil(cmd:find('-scheme'))
        return '{"buildServer": "config"}', nil
      end

      local result = config.generate_buildserver_config('/path/to/TestApp.xcodeproj')
      assert.equals('{"buildServer": "config"}', result)

      -- Restore original function
      require('xcode-build-server.utils').execute_command = original_execute
    end)
  end)

  describe('check_xcode_build_server', function()
    it('returns true when xcode-build-server is available', function()
      -- Mock utils.execute_command to simulate available xcode-build-server
      local original_execute = require('xcode-build-server.utils').execute_command
      require('xcode-build-server.utils').execute_command = function(cmd, opts)
        if cmd:find('--version') then
          return 'xcode-build-server 2.0.0', nil
        end
        return nil, 'Command not found'
      end

      local available, version = config.check_xcode_build_server()
      assert.is_true(available)
      assert.equals('xcode-build-server 2.0.0', version)

      -- Restore original function
      require('xcode-build-server.utils').execute_command = original_execute
    end)

    it('returns false when xcode-build-server is not available', function()
      -- Mock utils.execute_command to simulate unavailable xcode-build-server
      local original_execute = require('xcode-build-server.utils').execute_command
      require('xcode-build-server.utils').execute_command = function(cmd, opts)
        return nil, 'Command not found'
      end

      local available, error_msg = config.check_xcode_build_server()
      assert.is_false(available)
      assert.equals('xcode-build-server not found in PATH', error_msg)

      -- Restore original function
      require('xcode-build-server.utils').execute_command = original_execute
    end)
  end)

  describe('get_project_root_for_buildserver', function()
    it('returns parent directory for xcworkspace', function()
      -- Mock vim.fn.fnamemodify
      local original_fnamemodify = vim.fn.fnamemodify
      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':h' then
          return '/path/to/project'
        end
        return path
      end

      local result = config.get_project_root_for_buildserver('/path/to/project/App.xcworkspace')
      assert.equals('/path/to/project', result)

      -- Restore original function
      vim.fn.fnamemodify = original_fnamemodify
    end)

    it('returns parent directory for xcodeproj', function()
      -- Mock vim.fn.fnamemodify
      local original_fnamemodify = vim.fn.fnamemodify
      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':h' then
          return '/path/to/project'
        end
        return path
      end

      local result = config.get_project_root_for_buildserver('/path/to/project/App.xcodeproj')
      assert.equals('/path/to/project', result)

      -- Restore original function
      vim.fn.fnamemodify = original_fnamemodify
    end)
  end)

  describe('defaults', function()
    it('has expected default values', function()
      local defaults = config.defaults

      assert.equals(3, defaults.search_depth)
      assert.equals(10000, defaults.timeout)
      assert.is_false(defaults.auto_setup)
      assert.is_true(defaults.restart_lsp)
      assert.equals('xcode-build-server', defaults.build_server_path)

      -- Check picker defaults
      assert.equals('vim_ui', defaults.picker.backend)
      assert.is_table(defaults.picker.telescope)
      assert.is_table(defaults.picker.fzf)
    end)
  end)
end)
