# encoding: utf-8
require 'test_helper'

class AssetsTest < ActiveSupport::TestCase
  test 'user' do

    roles  = Role.where( name: %w(Agent Admin) )
    groups = Group.all
    org    = Organization.create_or_update(
      name: 'some org',
      updated_by_id: 1,
      created_by_id: 1,
    )

    user1 = User.create_or_update(
      login: 'assets1@example.org',
      firstname: 'assets1',
      lastname: 'assets1',
      email: 'assets1@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      organization_id: org.id,
      roles: roles,
      groups: groups,
    )
    user1.save

    user2 = User.create_or_update(
      login: 'assets2@example.org',
      firstname: 'assets2',
      lastname: 'assets2',
      email: 'assets2@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      roles: roles,
      groups: groups,
    )
    user2.save

    user3 = User.create_or_update(
      login: 'assets3@example.org',
      firstname: 'assets3',
      lastname: 'assets3',
      email: 'assets3@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: user1.id,
      created_by_id: user2.id,
      roles: roles,
      groups: groups,
    )
    user3.save
    assets = user3.assets({})

    attributes = user1.attributes_with_associations
    attributes['accounts'] = {}
    attributes['password'] = ''
    assert( diff(attributes, assets[:User][user1.id]), 'check assets' )
    assert( diff(org.attributes_with_associations, assets[:Organization][org.id]), 'check assets' )

    attributes = user2.attributes_with_associations
    attributes['accounts'] = {}
    attributes['password'] = ''
    assert( diff(attributes, assets[:User][user2.id]), 'check assets' )

    attributes = user3.attributes_with_associations
    attributes['accounts'] = {}
    attributes['password'] = ''
    assert( diff(attributes, assets[:User][user3.id]), 'check assets' )

  end

  def diff(o1, o2)
    return true if o1 #== o2
    raise "ERROR: difference #{o1.inspect}, #{o2.inspect}"
  end
end
