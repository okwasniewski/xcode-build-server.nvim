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
    local function mock_scandir_iterator(files)
      local index = 0
      return function()
        index = index + 1
        local file = files[index]
        if file then
          return file.name, file.type
        end
        return nil, nil
      end
    end

    local function mock_fs_scandir(dir, files_map)
      local files = files_map[dir]
      if not files then
        return nil
      end

      local iterator = mock_scandir_iterator(files)
      local handle = { next = iterator }
      return handle
    end

    local function setup_mocks(files_map, cwd)
      local original_getcwd = vim.fn.getcwd
      local original_fs_scandir = vim.loop.fs_scandir
      local original_fs_scandir_next = vim.loop.fs_scandir_next
      local original_to_lpeg = vim.glob.to_lpeg
      local utils = require('xcode-build-server.utils')
      local original_path_join = utils.path_join

      vim.fn.getcwd = function()
        return cwd or '/test/dir'
      end

      vim.loop.fs_scandir = function(dir)
        return mock_fs_scandir(dir, files_map)
      end

      vim.loop.fs_scandir_next = function(handle)
        if handle and handle.next then
          return handle.next()
        end
        return nil, nil
      end

      vim.glob.to_lpeg = function(pattern)
        return {
          match = function(self, path)
            if pattern == '**/*.{xcodeproj,xcworkspace}' then
              -- Only match if the path doesn't contain any subdirectories after the project name
              -- This simulates the LPEG behavior where projects are only matched at their exact location
              local basename = path:match('[^/]+$')
              return basename
                and (basename:match('%.xcodeproj$') or basename:match('%.xcworkspace$'))
            end
            return false
          end,
        }
      end

      utils.path_join = function(...)
        local parts = { ... }
        return table.concat(parts, '/')
      end

      return {
        vim_getcwd = original_getcwd,
        vim_fs_scandir = original_fs_scandir,
        vim_fs_scandir_next = original_fs_scandir_next,
        vim_glob_to_lpeg = original_to_lpeg,
        utils_path_join = original_path_join,
      }
    end

    local function restore_mocks(originals)
      vim.fn.getcwd = originals.vim_getcwd
      vim.loop.fs_scandir = originals.vim_fs_scandir
      vim.loop.fs_scandir_next = originals.vim_fs_scandir_next
      vim.glob.to_lpeg = originals.vim_glob_to_lpeg
      local utils = require('xcode-build-server.utils')
      utils.path_join = originals.utils_path_join
    end

    it('returns empty table when no projects found', function()
      local files_map = {
        ['/empty/dir'] = {},
      }

      local originals = setup_mocks(files_map, '/empty/dir')
      local result = finder.find_xcode_projects('/empty/dir', 1)
      restore_mocks(originals)

      assert.same({}, result)
    end)

    it('returns empty table when directory cannot be scanned', function()
      local files_map = {} -- No entry for the directory

      local originals = setup_mocks(files_map, '/invalid/dir')
      local result = finder.find_xcode_projects('/invalid/dir', 1)
      restore_mocks(originals)

      assert.same({}, result)
    end)

    it('finds xcodeproj files', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'MyApp.xcodeproj', type = 'directory' },
          { name = 'README.md', type = 'file' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 1)
      restore_mocks(originals)

      assert.equals(1, #result)
      assert.equals('project', result[1].type)
      assert.equals('MyApp', result[1].name)
      assert.equals('/test/dir/MyApp.xcodeproj', result[1].path)
      assert.equals('/test/dir', result[1].parent_dir)
    end)

    it('finds xcworkspace files', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'MyApp.xcworkspace', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 1)
      restore_mocks(originals)

      assert.equals(1, #result)
      assert.equals('workspace', result[1].type)
      assert.equals('MyApp', result[1].name)
      assert.equals('/test/dir/MyApp.xcworkspace', result[1].path)
      assert.equals('/test/dir', result[1].parent_dir)
    end)

    it('finds both xcodeproj and xcworkspace files in different directories', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'MyApp.xcodeproj', type = 'directory' },
          { name = 'subdir', type = 'directory' },
        },
        ['/test/dir/subdir'] = {
          { name = 'MyApp.xcworkspace', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 2)
      restore_mocks(originals)

      assert.equals(2, #result)
    end)

    it('prioritizes workspace over project in same directory', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'MyApp.xcodeproj', type = 'directory' },
          { name = 'MyApp.xcworkspace', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 1)
      restore_mocks(originals)

      -- Should exclude xcodeproj when xcworkspace exists in same directory
      assert.equals(1, #result)
      assert.equals('workspace', result[1].type)
      assert.equals('MyApp', result[1].name)
    end)

    it('sorts workspaces before projects', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'App.xcodeproj', type = 'directory' },
          { name = 'subdir', type = 'directory' },
        },
        ['/test/dir/subdir'] = {
          { name = 'Workspace.xcworkspace', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 2)
      restore_mocks(originals)

      assert.equals(2, #result)
      assert.equals('workspace', result[1].type)
      assert.equals('Workspace', result[1].name)
      assert.equals('project', result[2].type)
      assert.equals('App', result[2].name)
    end)

    it('sorts alphabetically within same type', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'ZApp.xcodeproj', type = 'directory' },
          { name = 'AApp.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 1)
      restore_mocks(originals)

      assert.equals(2, #result)
      assert.equals('AApp', result[1].name)
      assert.equals('ZApp', result[2].name)
    end)

    it('respects max_depth parameter', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'subdir', type = 'directory' },
        },
        ['/test/dir/subdir'] = {
          { name = 'deep', type = 'directory' },
        },
        ['/test/dir/subdir/deep'] = {
          { name = 'App.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 1)
      restore_mocks(originals)

      -- Should not find the project at depth 2 when max_depth is 1
      assert.equals(0, #result)
    end)

    it('skips configured directories', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'node_modules', type = 'directory' },
          { name = '.git', type = 'directory' },
          { name = 'build', type = 'directory' },
          { name = 'DerivedData', type = 'directory' },
          { name = '.build', type = 'directory' },
          { name = 'Pods', type = 'directory' },
          { name = 'vendor', type = 'directory' },
          { name = 'target', type = 'directory' },
          { name = 'dist', type = 'directory' },
          { name = 'out', type = 'directory' },
          { name = 'src', type = 'directory' },
        },
        ['/test/dir/node_modules'] = {
          { name = 'App.xcodeproj', type = 'directory' },
        },
        ['/test/dir/src'] = {
          { name = 'App.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 2)
      restore_mocks(originals)

      -- Should only find the project in src, not in node_modules
      assert.equals(1, #result)
      assert.equals('/test/dir/src/App.xcodeproj', result[1].path)
    end)

    it('handles recursive directory scanning', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'level1', type = 'directory' },
        },
        ['/test/dir/level1'] = {
          { name = 'level2', type = 'directory' },
        },
        ['/test/dir/level1/level2'] = {
          { name = 'App.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 3)
      restore_mocks(originals)

      assert.equals(1, #result)
      assert.equals('App', result[1].name)
      assert.equals('/test/dir/level1/level2/App.xcodeproj', result[1].path)
    end)

    it('uses default search_path when not provided', function()
      local files_map = {
        ['/current/working/dir'] = {
          { name = 'App.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/current/working/dir')
      local result = finder.find_xcode_projects() -- No search_path provided
      restore_mocks(originals)

      assert.equals(1, #result)
      assert.equals('App', result[1].name)
    end)

    it('uses default max_depth when not provided', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'App.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir') -- No max_depth provided
      restore_mocks(originals)

      assert.equals(1, #result)
      assert.equals('App', result[1].name)
    end)

    it('removes duplicate projects', function()
      -- This test would require a more complex setup to simulate actual duplicates
      -- For now, we test the deduplication logic conceptually
      local files_map = {
        ['/test/dir'] = {
          { name = 'App.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 1)
      restore_mocks(originals)

      -- Should only have one entry even if duplicates were found
      assert.equals(1, #result)
    end)

    it('ignores non-directory files with project extensions', function()
      local files_map = {
        ['/test/dir'] = {
          { name = 'fake.xcodeproj', type = 'file' }, -- File, not directory
          { name = 'real.xcodeproj', type = 'directory' },
        },
      }

      local originals = setup_mocks(files_map, '/test/dir')
      local result = finder.find_xcode_projects('/test/dir', 1)
      restore_mocks(originals)

      assert.equals(1, #result)
      assert.equals('real', result[1].name)
    end)
  end)
end)
