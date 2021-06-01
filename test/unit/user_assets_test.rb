# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# NOTE: This test file is _almost_ fully migrated to RSpec, as of 4cc64d0ce.
# It may be deleted once all missing spec coverage has been added.
#
# What's missing is coverage for
# the non-standard implementation of #assets on the User class.
# (It adds an { accounts: {} } key-value pair
# to the resulting User attributes hash;
# see lines 75:83:91:109:123:131:139 of this file).
#
# This omission is discussed in detail in
# https://git.znuny.com/zammad/zammad/merge_requests/363

require 'test_helper'

class UserAssetsTest < ActiveSupport::TestCase
  test 'assets' do

    roles  = Role.where(name: %w[Agent Admin])
    groups = Group.all
    org1   = Organization.create_or_update(
      name:          'some user org',
      updated_by_id: 1,
      created_by_id: 1,
    )

    user1 = User.create_or_update(
      login:           'assets1@example.org',
      firstname:       'assets1',
      lastname:        'assets1',
      email:           'assets1@example.org',
      password:        'some_pass',
      active:          true,
      updated_by_id:   1,
      created_by_id:   1,
      organization_id: org1.id,
      roles:           roles,
      groups:          groups,
    )

    user2 = User.create_or_update(
      login:         'assets2@example.org',
      firstname:     'assets2',
      lastname:      'assets2',
      email:         'assets2@example.org',
      password:      'some_pass',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      roles:         roles,
      groups:        groups,
    )

    user3 = User.create_or_update(
      login:         'assets3@example.org',
      firstname:     'assets3',
      lastname:      'assets3',
      email:         'assets3@example.org',
      password:      'some_pass',
      active:        true,
      updated_by_id: user1.id,
      created_by_id: user2.id,
      roles:         roles,
      groups:        groups,
    )
    user3 = User.find(user3.id)
    assets = user3.assets({})

    org1 = Organization.find(org1.id)
    attributes = org1.attributes_with_association_ids
    attributes.delete('user_ids')
    assert(diff(attributes, assets[:Organization][org1.id]), 'check assets')

    user1 = User.find(user1.id)
    attributes = user1.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert(diff(attributes, assets[:User][user1.id]), 'check assets')

    user2 = User.find(user2.id)
    attributes = user2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert(diff(attributes, assets[:User][user2.id]), 'check assets')

    user3 = User.find(user3.id)
    attributes = user3.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert(diff(attributes, assets[:User][user3.id]), 'check assets')

    user3.destroy!
    user2.destroy!
    user1.destroy!
    org1.destroy!
  end

  def diff(object1, object2)
    return true if object1 == object2

    %w[updated_at created_at].each do |item|
      if object1[item]
        object1[item] = object1[item].to_s
      end
      if object2[item]
        object2[item] = object2[item].to_s
      end
    end
    return true if (object1.to_a - object2.to_a).blank?

    #puts "ERROR: difference \n1: #{object1.inspect}\n2: #{object2.inspect}\ndiff: #{(object1.to_a - object2.to_a).inspect}"
    false
  end

end
