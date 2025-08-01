local finder = require('xcode-build-server.finder')

describe('finder', function()
  describe('validate_project', function()
    it('returns false for non-existent project', function()
      local valid, error_msg = finder.validate_project('/non/existent/project.xcodeproj')
      assert.is_false(valid)
      assert.equals('Project path does not exist', error_msg)
    end)

    it('validates xcworkspace with contents.xcworkspacedata', function()
      -- Mock utils functions
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      local original_file_exists = utils.file_exists
      local original_path_join = utils.path_join

      utils.dir_exists = function(path)
        return path == '/path/to/App.xcworkspace'
      end

      utils.file_exists = function(path)
        return path == '/path/to/App.xcworkspace/contents.xcworkspacedata'
      end

      utils.path_join = function(...)
        local parts = { ... }
        return table.concat(parts, '/')
      end

      local valid, error_msg = finder.validate_project('/path/to/App.xcworkspace')
      assert.is_true(valid)
      assert.is_nil(error_msg)

      -- Restore original functions
      utils.dir_exists = original_dir_exists
      utils.file_exists = original_file_exists
      utils.path_join = original_path_join
    end)

    it('returns false for xcworkspace without contents.xcworkspacedata', function()
      -- Mock utils functions
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      local original_file_exists = utils.file_exists
      local original_path_join = utils.path_join

      utils.dir_exists = function(path)
        return path == '/path/to/App.xcworkspace'
      end

      utils.file_exists = function(path)
        return false -- No contents.xcworkspacedata
      end

      utils.path_join = function(...)
        local parts = { ... }
        return table.concat(parts, '/')
      end

      local valid, error_msg = finder.validate_project('/path/to/App.xcworkspace')
      assert.is_false(valid)
      assert.equals('Invalid Xcode workspace: missing contents.xcworkspacedata', error_msg)

      -- Restore original functions
      utils.dir_exists = original_dir_exists
      utils.file_exists = original_file_exists
      utils.path_join = original_path_join
    end)

    it('validates xcodeproj with project.pbxproj', function()
      -- Mock utils functions
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      local original_file_exists = utils.file_exists
      local original_path_join = utils.path_join

      utils.dir_exists = function(path)
        return path == '/path/to/App.xcodeproj'
      end

      utils.file_exists = function(path)
        return path == '/path/to/App.xcodeproj/project.pbxproj'
      end

      utils.path_join = function(...)
        local parts = { ... }
        return table.concat(parts, '/')
      end

      local valid, error_msg = finder.validate_project('/path/to/App.xcodeproj')
      assert.is_true(valid)
      assert.is_nil(error_msg)

      -- Restore original functions
      utils.dir_exists = original_dir_exists
      utils.file_exists = original_file_exists
      utils.path_join = original_path_join
    end)

    it('returns false for xcodeproj without project.pbxproj', function()
      -- Mock utils functions
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      local original_file_exists = utils.file_exists
      local original_path_join = utils.path_join

      utils.dir_exists = function(path)
        return path == '/path/to/App.xcodeproj'
      end

      utils.file_exists = function(path)
        return false -- No project.pbxproj
      end

      utils.path_join = function(...)
        local parts = { ... }
        return table.concat(parts, '/')
      end

      local valid, error_msg = finder.validate_project('/path/to/App.xcodeproj')
      assert.is_false(valid)
      assert.equals('Invalid Xcode project: missing project.pbxproj', error_msg)

      -- Restore original functions
      utils.dir_exists = original_dir_exists
      utils.file_exists = original_file_exists
      utils.path_join = original_path_join
    end)
  end)

  describe('has_buildserver_json', function()
    it('returns true when buildServer.json exists in root directory', function()
      -- Mock vim.fn.getcwd and utils.file_exists
      local original_getcwd = vim.fn.getcwd
      local utils = require('xcode-build-server.utils')
      local original_file_exists = utils.file_exists
      local original_path_join = utils.path_join

      vim.fn.getcwd = function()
        return '/root/project'
      end

      utils.file_exists = function(path)
        return path == '/root/project/buildServer.json'
      end

      utils.path_join = function(...)
        local parts = { ... }
        return table.concat(parts, '/')
      end

      local result = finder.has_buildserver_json('/some/project/dir')
      assert.is_true(result)

      -- Restore original functions
      vim.fn.getcwd = original_getcwd
      utils.file_exists = original_file_exists
      utils.path_join = original_path_join
    end)

    it('returns false when buildServer.json does not exist', function()
      -- Mock vim.fn.getcwd and utils.file_exists
      local original_getcwd = vim.fn.getcwd
      local utils = require('xcode-build-server.utils')
      local original_file_exists = utils.file_exists
      local original_path_join = utils.path_join

      vim.fn.getcwd = function()
        return '/root/project'
      end

      utils.file_exists = function(path)
        return false
      end

      utils.path_join = function(...)
        local parts = { ... }
        return table.concat(parts, '/')
      end

      local result = finder.has_buildserver_json('/some/project/dir')
      assert.is_false(result)

      -- Restore original functions
      vim.fn.getcwd = original_getcwd
      utils.file_exists = original_file_exists
      utils.path_join = original_path_join
    end)
  end)

  describe('find_nearest_project', function()
    it('returns nil when no project found', function()
      -- Mock vim.fn.expand and vim.fn.fnamemodify
      local original_expand = vim.fn.expand
      local original_fnamemodify = vim.fn.fnamemodify

      vim.fn.expand = function(path)
        return '/tmp/no/project'
      end

      vim.fn.fnamemodify = function(path, modifier)
        if path == '/tmp/no/project' and modifier == ':h' then
          return '/tmp/no'
        elseif path == '/tmp/no' and modifier == ':h' then
          return '/tmp'
        elseif path == '/tmp' and modifier == ':h' then
          return '/'
        end
        return path
      end

      -- Mock find_xcode_projects to return empty results
      local original_find_xcode_projects = finder.find_xcode_projects
      finder.find_xcode_projects = function(search_path, max_depth)
        return {}
      end

      local result = finder.find_nearest_project('/tmp/no/project')
      assert.is_nil(result)

      -- Restore original functions
      vim.fn.expand = original_expand
      vim.fn.fnamemodify = original_fnamemodify
      finder.find_xcode_projects = original_find_xcode_projects
    end)

    it('returns first project when found', function()
      -- Mock vim.fn.expand and vim.fn.fnamemodify
      local original_expand = vim.fn.expand
      local original_fnamemodify = vim.fn.fnamemodify

      vim.fn.expand = function(path)
        return '/project/dir'
      end

      vim.fn.fnamemodify = function(path, modifier)
        return path -- Don't change for this test
      end

      -- Mock find_xcode_projects to return a project
      local original_find_xcode_projects = finder.find_xcode_projects
      finder.find_xcode_projects = function(search_path, max_depth)
        return {
          {
            type = 'project',
            name = 'TestApp',
            path = '/project/dir/TestApp.xcodeproj',
            parent_dir = '/project/dir',
          },
        }
      end

      local result = finder.find_nearest_project('/project/dir')
      assert.is_not_nil(result)
      assert.equals('TestApp', result.name)
      assert.equals('project', result.type)

      -- Restore original functions
      vim.fn.expand = original_expand
      vim.fn.fnamemodify = original_fnamemodify
      finder.find_xcode_projects = original_find_xcode_projects
    end)
  end)

  describe('find_xcode_projects', function()
    it('returns empty table when no projects found', function()
      -- Mock vim.fn.getcwd and vim.loop.fs_scandir
      local original_getcwd = vim.fn.getcwd
      local original_fs_scandir = vim.loop.fs_scandir

      vim.fn.getcwd = function()
        return '/empty/dir'
      end

      vim.loop.fs_scandir = function(dir)
        return nil -- No files
      end

      local result = finder.find_xcode_projects('/empty/dir', 1)
      assert.same({}, result)

      -- Restore original functions
      vim.fn.getcwd = original_getcwd
      vim.loop.fs_scandir = original_fs_scandir
    end)
  end)
end)
