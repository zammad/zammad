require 'benchmark'
require 'power_assert'

def assertion_message(source = nil, source_binding = TOPLEVEL_BINDING, &blk)
  ::PowerAssert.start(source || blk, assertion_method: __callee__, source_binding: source_binding) do |pa|
    pa.message unless pa.yield
  end
end
