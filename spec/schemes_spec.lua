local schemes = require('xcode-build-server.schemes')

describe('schemes', function()
  describe('parse_schemes_output', function()
    it('parses schemes from xcodebuild output', function()
      local output = [[
Information about project "TestApp":
    Targets:
        TestApp
        TestAppTests

    Build Configurations:
        Debug
        Release

    If no build configuration is specified and -scheme is not passed then "Release" is used.

    Schemes:
        TestApp
        TestAppTests
        WidgetExtension

]]
      
      local result = schemes.parse_schemes_output(output)
      assert.same({'TestApp', 'TestAppTests', 'WidgetExtension'}, result)
    end)

    it('handles output without schemes section', function()
      local output = [[
Information about project "TestApp":
    Targets:
        TestApp

    Build Configurations:
        Debug
        Release
]]
      
      local result = schemes.parse_schemes_output(output)
      assert.same({}, result)
    end)

    it('handles empty schemes section', function()
      local output = [[
Information about project "TestApp":
    Schemes:

    Build Configurations:
        Debug
        Release
]]
      
      local result = schemes.parse_schemes_output(output)
      assert.same({}, result)
    end)

    it('stops parsing at Build Configurations', function()
      local output = [[
Information about project "TestApp":
    Schemes:
        TestApp
        TestAppTests
    Build Configurations:
        Debug
        Release
        SomeOtherLine
]]
      
      local result = schemes.parse_schemes_output(output)
      assert.same({'TestApp', 'TestAppTests'}, result)
    end)

    it('ignores Information about project lines in schemes section', function()
      local output = [[
Information about project "TestApp":
    Schemes:
        Information about project line should be ignored
        TestApp
        TestAppTests
]]
      
      local result = schemes.parse_schemes_output(output)
      assert.same({'TestApp', 'TestAppTests'}, result)
    end)
  end)

  describe('get_default_scheme', function()
    it('returns nil for empty schemes list', function()
      local result = schemes.get_default_scheme({})
      assert.is_nil(result)
    end)

    it('returns first scheme containing "app" (case insensitive)', function()
      local scheme_list = {'TestLib', 'MyApp', 'TestAppTests'}
      local result = schemes.get_default_scheme(scheme_list)
      assert.equals('MyApp', result)
    end)

    it('returns first scheme containing "App" (case insensitive)', function()
      local scheme_list = {'TestLib', 'MyAppKit', 'TestTests'}
      local result = schemes.get_default_scheme(scheme_list)
      assert.equals('MyAppKit', result)
    end)

    it('returns first scheme when none contain "app"', function()
      local scheme_list = {'TestLib', 'MyKit', 'TestTests'}
      local result = schemes.get_default_scheme(scheme_list)
      assert.equals('TestLib', result)
    end)

    it('returns first scheme containing "app" even if not first in list', function()
      local scheme_list = {'TestLib', 'MyKit', 'MainApp', 'TestTests'}
      local result = schemes.get_default_scheme(scheme_list)
      assert.equals('MainApp', result)
    end)
  end)

  describe('list_schemes', function()
    it('returns empty list for non-existent project', function()
      -- Mock utils.dir_exists to return false
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      
      utils.dir_exists = function(path)
        return false
      end
      
      local result = schemes.list_schemes('/non/existent/project.xcodeproj')
      assert.same({}, result)
      
      -- Restore original function
      utils.dir_exists = original_dir_exists
    end)

    it('uses -project flag for xcodeproj', function()
      -- Mock utils functions
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      local original_execute_command = utils.execute_command
      
      utils.dir_exists = function(path)
        return true
      end
      
      utils.execute_command = function(cmd, opts)
        assert.is_not_nil(cmd:find('-project'))
        assert.is_not_nil(cmd:find('TestApp.xcodeproj'))
        assert.is_not_nil(cmd:find('-list'))
        return 'Schemes:\n    TestApp\n', nil
      end
      
      local original_parse = schemes.parse_schemes_output
      schemes.parse_schemes_output = function(output)
        return {'TestApp'}
      end
      
      local result = schemes.list_schemes('/path/to/TestApp.xcodeproj')
      assert.same({'TestApp'}, result)
      
      -- Restore original functions
      utils.dir_exists = original_dir_exists
      utils.execute_command = original_execute_command
      schemes.parse_schemes_output = original_parse
    end)

    it('uses -workspace flag for xcworkspace', function()
      -- Mock utils functions
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      local original_execute_command = utils.execute_command
      
      utils.dir_exists = function(path)
        return true
      end
      
      utils.execute_command = function(cmd, opts)
        assert.is_not_nil(cmd:find('-workspace'))
        assert.is_not_nil(cmd:find('TestApp.xcworkspace'))
        assert.is_not_nil(cmd:find('-list'))
        return 'Schemes:\n    TestApp\n', nil
      end
      
      local original_parse = schemes.parse_schemes_output
      schemes.parse_schemes_output = function(output)
        return {'TestApp'}
      end
      
      local result = schemes.list_schemes('/path/to/TestApp.xcworkspace')
      assert.same({'TestApp'}, result)
      
      -- Restore original functions
      utils.dir_exists = original_dir_exists
      utils.execute_command = original_execute_command
      schemes.parse_schemes_output = original_parse
    end)

    it('returns empty list when command fails', function()
      -- Mock utils functions
      local utils = require('xcode-build-server.utils')
      local original_dir_exists = utils.dir_exists
      local original_execute_command = utils.execute_command
      
      utils.dir_exists = function(path)
        return true
      end
      
      utils.execute_command = function(cmd, opts)
        return nil, 'Command failed'
      end
      
      local result = schemes.list_schemes('/path/to/TestApp.xcodeproj')
      assert.same({}, result)
      
      -- Restore original functions
      utils.dir_exists = original_dir_exists
      utils.execute_command = original_execute_command
    end)
  end)

  describe('validate_scheme', function()
    it('returns true for valid scheme', function()
      -- Mock list_schemes to return test schemes
      local original_list_schemes = schemes.list_schemes
      schemes.list_schemes = function(project_path)
        return {'TestApp', 'TestAppTests', 'WidgetExtension'}
      end
      
      local result = schemes.validate_scheme('/path/to/project.xcodeproj', 'TestApp')
      assert.is_true(result)
      
      -- Restore original function
      schemes.list_schemes = original_list_schemes
    end)

    it('returns false for invalid scheme', function()
      -- Mock list_schemes to return test schemes
      local original_list_schemes = schemes.list_schemes
      schemes.list_schemes = function(project_path)
        return {'TestApp', 'TestAppTests', 'WidgetExtension'}
      end
      
      local result = schemes.validate_scheme('/path/to/project.xcodeproj', 'NonExistentScheme')
      assert.is_false(result)
      
      -- Restore original function
      schemes.list_schemes = original_list_schemes
    end)

    it('returns false when no schemes available', function()
      -- Mock list_schemes to return empty list
      local original_list_schemes = schemes.list_schemes
      schemes.list_schemes = function(project_path)
        return {}
      end
      
      local result = schemes.validate_scheme('/path/to/project.xcodeproj', 'TestApp')
      assert.is_false(result)
      
      -- Restore original function
      schemes.list_schemes = original_list_schemes
    end)
  end)

  describe('parse_build_settings', function()
    it('parses build settings from xcodebuild output', function()
      local output = [[
Build settings for action build and target TestApp:
    ARCHS = arm64
    BUILD_DIR = /Users/user/Library/Developer/Xcode/DerivedData/TestApp
    CONFIGURATION = Debug
    PRODUCT_NAME = TestApp
    SWIFT_VERSION = 5.0
]]
      
      local result = schemes.parse_build_settings(output)
      assert.equals('arm64', result.ARCHS)
      assert.equals('/Users/user/Library/Developer/Xcode/DerivedData/TestApp', result.BUILD_DIR)
      assert.equals('Debug', result.CONFIGURATION)
      assert.equals('TestApp', result.PRODUCT_NAME)
      assert.equals('5.0', result.SWIFT_VERSION)
    end)

    it('handles empty output', function()
      local result = schemes.parse_build_settings('')
      assert.same({}, result)
    end)

    it('ignores invalid lines', function()
      local output = [[
Build settings for action build and target TestApp:
    ARCHS = arm64
    Invalid line without equals sign
    PRODUCT_NAME = TestApp
    Another invalid line
]]
      
      local result = schemes.parse_build_settings(output)
      assert.equals('arm64', result.ARCHS)
      assert.equals('TestApp', result.PRODUCT_NAME)
      assert.is_nil(result['Invalid line without equals sign'])
    end)

    it('trims whitespace from values', function()
      local output = [[
Build settings:
    ARCHS =   arm64   
    PRODUCT_NAME = TestApp 
]]
      
      local result = schemes.parse_build_settings(output)
      assert.equals('arm64', result.ARCHS)
      assert.equals('TestApp', result.PRODUCT_NAME)
    end)
  end)

  describe('get_scheme_info', function()
    it('uses -workspace flag for xcworkspace', function()
      -- Mock utils.execute_command
      local utils = require('xcode-build-server.utils')
      local original_execute_command = utils.execute_command
      
      utils.execute_command = function(cmd, opts)
        assert.is_not_nil(cmd:find('-workspace'))
        assert.is_not_nil(cmd:find('TestApp.xcworkspace'))
        assert.is_not_nil(cmd:find('-scheme'))
        assert.is_not_nil(cmd:find('TestScheme'))
        assert.is_not_nil(cmd:find('-showBuildSettings'))
        return 'ARCHS = arm64', nil
      end
      
      local original_parse = schemes.parse_build_settings
      schemes.parse_build_settings = function(output)
        return {ARCHS = 'arm64'}
      end
      
      local result = schemes.get_scheme_info('/path/to/TestApp.xcworkspace', 'TestScheme')
      assert.same({ARCHS = 'arm64'}, result)
      
      -- Restore original functions
      utils.execute_command = original_execute_command
      schemes.parse_build_settings = original_parse
    end)

    it('uses -project flag for xcodeproj', function()
      -- Mock utils.execute_command
      local utils = require('xcode-build-server.utils')
      local original_execute_command = utils.execute_command
      
      utils.execute_command = function(cmd, opts)
        assert.is_not_nil(cmd:find('-project'))
        assert.is_not_nil(cmd:find('TestApp.xcodeproj'))
        assert.is_not_nil(cmd:find('-scheme'))
        assert.is_not_nil(cmd:find('TestScheme'))
        assert.is_not_nil(cmd:find('-showBuildSettings'))
        return 'ARCHS = arm64', nil
      end
      
      local original_parse = schemes.parse_build_settings
      schemes.parse_build_settings = function(output)
        return {ARCHS = 'arm64'}
      end
      
      local result = schemes.get_scheme_info('/path/to/TestApp.xcodeproj', 'TestScheme')
      assert.same({ARCHS = 'arm64'}, result)
      
      -- Restore original functions
      utils.execute_command = original_execute_command
      schemes.parse_build_settings = original_parse
    end)

    it('returns nil when command fails', function()
      -- Mock utils.execute_command to fail
      local utils = require('xcode-build-server.utils')
      local original_execute_command = utils.execute_command
      
      utils.execute_command = function(cmd, opts)
        return nil, 'Command failed'
      end
      
      local result = schemes.get_scheme_info('/path/to/TestApp.xcodeproj', 'TestScheme')
      assert.is_nil(result)
      
      -- Restore original function
      utils.execute_command = original_execute_command
    end)
  end)
end)