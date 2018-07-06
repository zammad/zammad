
require 'test_helper'

class OrganizationAssetsTest < ActiveSupport::TestCase
  test 'assets' do

    roles  = Role.where( name: %w[Agent Admin] )
    admin1 = User.create_or_update(
      login: 'admin1@example.org',
      firstname: 'admin1',
      lastname: 'admin1',
      email: 'admin1@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      roles: roles,
    )

    roles = Role.where( name: %w[Customer] )
    org   = Organization.create_or_update(
      name: 'some customer org',
      updated_by_id: admin1.id,
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
      organization_id: org.id,
      roles: roles,
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
    )

    org = Organization.find(org.id)
    assets = org.assets({})
    attributes = org.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( diff(attributes, assets[:Organization][org.id]), 'check assets' )

    admin1 = User.find(admin1.id)
    attributes = admin1.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][admin1.id]), 'check assets' )

    user1 = User.find(user1.id)
    attributes = user1.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user1.id]), 'check assets' )

    user2 = User.find(user2.id)
    attributes = user2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user2.id]), 'check assets' )

    user3 = User.find(user3.id)
    attributes = user3.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert_nil( assets[:User][user3.id], 'check assets' )

    # touch user 2, check if org has changed
    travel 2.seconds
    user_new_2 = User.find(user2.id)
    user_new_2.lastname = 'assets2'
    user_new_2.save!

    org_new = Organization.find(org.id)
    attributes = org_new.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( !diff(attributes, assets[:Organization][org_new.id]), 'check assets' )

    attributes = user_new_2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user_new_2.id]), 'check assets' )

    # check new assets lookup
    assets = org_new.assets({})
    attributes = org_new.attributes_with_association_ids
    attributes.delete('user_ids')
    assert( diff(attributes, assets[:Organization][org_new.id]), 'check assets' )

    attributes = user_new_2.attributes_with_association_ids
    attributes['accounts'] = {}
    attributes.delete('password')
    attributes.delete('token_ids')
    attributes.delete('authorization_ids')
    assert( diff(attributes, assets[:User][user_new_2.id]), 'check assets' )
    travel_back

    user3.destroy!
    user2.destroy!
    user1.destroy!
    org.destroy!
    assert_not(Organization.find_by(id: org_new.id))
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
