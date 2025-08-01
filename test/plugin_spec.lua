local xcode_build_server = require('xcode-build-server')

describe('xcode-build-server', function()
  it('can be loaded', function()
    assert.is_not_nil(xcode_build_server)
    assert.is_function(xcode_build_server.setup)
    assert.is_function(xcode_build_server.setup_interactive)
    assert.is_function(xcode_build_server.status)
    assert.is_function(xcode_build_server.restart_lsp)
    assert.is_function(xcode_build_server.health)
  end)

  describe('setup', function()
    it('accepts configuration options', function()
      assert.has_no_error(function()
        xcode_build_server.setup({
          search_depth = 2,
          timeout = 5000,
          auto_setup = false,
        })
      end)
    end)
  end)

  describe('health', function()
    it('returns health check results', function()
      local results = xcode_build_server.health()
      assert.is_table(results)
      assert.is_true(#results > 0)
      
      for _, result in ipairs(results) do
        assert.is_string(result.name)
        assert.is_string(result.status)
        assert.is_string(result.message)
      end
    end)
  end)
end)