rockspec_format = '3.0'

package = 'xcode-build-server'
version = 'scm-1'
source = {
  url = 'https://github.com/okwasniewski/xcode-build-server.nvim',
}

dependencies = {}

test_dependencies = {
  'nlua',
  'busted',
}

build = {
  type = 'builtin',
  copy_directories = {},
}
