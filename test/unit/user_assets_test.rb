
require 'test_helper'

class UserAssetsTest < ActiveSupport::TestCase
  test 'assets' do

    roles  = Role.where(name: %w(Agent Admin))
    groups = Group.all
    org1   = Organization.create_or_update(
      name: 'some user org',
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
      organization_id: org1.id,
      roles: roles,
      groups: groups,
    )

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

    # touch org, check if user1 has changed
    travel 2.seconds
    org2 = Organization.find(org1.id)
    org2.note = "some note...#{rand(9_999_999_999_999)}"
    org2.save!

    attributes = org2.attributes_with_association_ids
    attributes.delete('user_ids')
    assert_not(diff(attributes, assets[:Organization][org2.id]), 'check assets')

    user1_new = User.find(user1.id)
    attributes = user1_new.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert_not(diff(attributes, assets[:User][user1_new.id]), 'check assets')

    # check new assets lookup
    assets = user3.assets({})
    attributes = org2.attributes_with_association_ids
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
    travel_back

    user3.destroy!
    user2.destroy!
    user1.destroy!
    org1.destroy!
    assert_not(Organization.find_by(id: org2.id))
  end

  def diff(o1, o2)
    return true if o1 == o2
    %w(updated_at created_at).each do |item|
      if o1[item]
        o1[item] = o1[item].to_s
      end
      if o2[item]
        o2[item] = o2[item].to_s
      end
    end
    return true if (o1.to_a - o2.to_a).blank?
    #puts "ERROR: difference \n1: #{o1.inspect}\n2: #{o2.inspect}\ndiff: #{(o1.to_a - o2.to_a).inspect}"
    false
  end

end
