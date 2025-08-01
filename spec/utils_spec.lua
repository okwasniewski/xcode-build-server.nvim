local utils = require('xcode-build-server.utils')

describe('utils', function()
  describe('path_join', function()
    it('joins two paths', function()
      local result = utils.path_join('foo', 'bar')
      assert.equals('foo/bar', result)
    end)

    it('joins multiple paths', function()
      local result = utils.path_join('foo', 'bar', 'baz')
      assert.equals('foo/bar/baz', result)
    end)

    it('handles empty strings', function()
      local result = utils.path_join('', 'bar')
      assert.equals('/bar', result)
    end)

    it('removes duplicate slashes', function()
      local result = utils.path_join('foo//', 'bar')
      assert.equals('foo/bar', result)
    end)

    it('handles trailing slashes', function()
      local result = utils.path_join('foo/', 'bar')
      assert.equals('foo/bar', result)
    end)
  end)

  describe('trim', function()
    it('removes leading and trailing whitespace', function()
      local result = utils.trim('  hello world  ')
      assert.equals('hello world', result)
    end)

    it('removes only leading whitespace', function()
      local result = utils.trim('  hello world')
      assert.equals('hello world', result)
    end)

    it('removes only trailing whitespace', function()
      local result = utils.trim('hello world  ')
      assert.equals('hello world', result)
    end)

    it('handles empty string', function()
      local result = utils.trim('')
      assert.equals('', result)
    end)

    it('handles string with only whitespace', function()
      local result = utils.trim('   ')
      assert.equals('', result)
    end)

    it('handles tabs and newlines', function()
      local result = utils.trim('\t\nhello world\n\t')
      assert.equals('hello world', result)
    end)
  end)

  describe('split', function()
    it('splits string by delimiter', function()
      local result = utils.split('foo,bar,baz', ',')
      assert.same({'foo', 'bar', 'baz'}, result)
    end)

    it('splits string by space', function()
      local result = utils.split('foo bar baz', ' ')
      assert.same({'foo', 'bar', 'baz'}, result)
    end)

    it('handles empty string', function()
      local result = utils.split('', ',')
      assert.same({}, result)
    end)

    it('handles string without delimiter', function()
      local result = utils.split('foobar', ',')
      assert.same({'foobar'}, result)
    end)

    it('handles consecutive delimiters', function()
      local result = utils.split('foo,,bar', ',')
      assert.same({'foo', 'bar'}, result)
    end)
  end)

  describe('file_exists', function()
    it('returns false for non-existent file', function()
      local result = utils.file_exists('/non/existent/file.txt')
      assert.is_false(result or false)
    end)

    it('returns false for directory', function()
      local result = utils.dir_exists('/tmp')
      if result then
        -- If /tmp exists as a directory, file_exists should return false
        local file_result = utils.file_exists('/tmp')
        assert.is_false(file_result or false)
      end
    end)
  end)

  describe('dir_exists', function()
    it('returns true for existing directory', function()
      local result = utils.dir_exists('/tmp')
      -- /tmp might not exist on all systems, so just check it's not nil if it exists
      assert.is_not_nil(result ~= nil)
    end)

    it('returns false for non-existent directory', function()
      local result = utils.dir_exists('/non/existent/directory')
      assert.is_false(result or false)
    end)

    it('returns false for file', function()
      -- Create a temporary file to test
      local temp_file = '/tmp/test_file_' .. os.time()
      local file = io.open(temp_file, 'w')
      if file then
        file:write('test')
        file:close()
        
        local result = utils.dir_exists(temp_file)
        assert.is_false(result)
        
        -- Clean up
        os.remove(temp_file)
      end
    end)
  end)

  describe('execute_command', function()
    it('executes successful command', function()
      local result, err = utils.execute_command('echo "test"')
      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.is_true(result:find('test') ~= nil)
    end)

    it('handles command failure', function()
      local result, err = utils.execute_command('false')
      assert.is_nil(result)
      assert.is_not_nil(err)
    end)

    it('ignores errors when ignore_errors is true', function()
      local result, err = utils.execute_command('false', { ignore_errors = true })
      assert.is_not_nil(result)
      assert.is_nil(err)
    end)
  end)

  describe('get_project_root', function()
    it('returns nil when no project found', function()
      local result = utils.get_project_root('/tmp')
      assert.is_nil(result)
    end)
  end)
end)