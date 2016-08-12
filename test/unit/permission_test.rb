# encoding: utf-8
require 'test_helper'

class PermissionTest < ActiveSupport::TestCase

  test 'permission' do
    permissions = Permission.with_parents('some_key.sub_key')
    assert_equal('some_key', permissions[0])
    assert_equal('some_key.sub_key', permissions[1])
    assert_equal(2, permissions.count)
  end

end
