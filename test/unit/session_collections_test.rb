require 'test_helper'

class SessionCollectionsTest < ActiveSupport::TestCase

  test 'a collections' do

    UserInfo.current_user_id = 1

    # create users
    roles  = Role.where(name: %w[Agent Admin])
    groups = Group.all

    agent1 = User.create_or_update(
      login:           'session-collections-agent-1',
      firstname:       'Session',
      lastname:        'collections 1',
      email:           'session-collections-agent-1@example.com',
      password:        'agentpw',
      organization_id: nil,
      active:          true,
      roles:           roles,
      groups:          groups,
    )
    agent1.save!

    roles  = Role.where(name: ['Agent'])
    groups = Group.all

    agent2 = User.create_or_update(
      login:           'session-collections-agent-2',
      firstname:       'Session',
      lastname:        'collections 2',
      email:           'session-collections-agent-2@example.com',
      password:        'agentpw',
      organization_id: nil,
      active:          true,
      roles:           roles,
      groups:          groups,
    )
    agent2.save!

    roles = Role.where(name: ['Customer'])
    customer1 = User.create_or_update(
      login:           'session-collections-customer-1',
      firstname:       'Session',
      lastname:        'collections 2',
      email:           'session-collections-customer-1@example.com',
      password:        'customerpw',
      organization_id: nil,
      active:          true,
      roles:           roles,
    )
    customer1.save!
    collection_client1 = Sessions::Backend::Collections.new(agent1, {}, nil, 'aaa-1', 2)
    collection_client2 = Sessions::Backend::Collections.new(agent2, {}, nil, 'bbb-2', 2)
    collection_client3 = Sessions::Backend::Collections.new(customer1, {}, nil, 'ccc-2', 2)

    # get whole collections
    result1 = collection_client1.push
    assert(result1, 'check collections')
    assert(check_if_collection_exists(result1, :Group), 'check collections - after init')
    assert(check_if_collection_exists(result1, :Role), 'check collections - after init')
    assert(check_if_collection_exists(result1, :Signature), 'check collections - after init')
    assert(check_if_collection_exists(result1, :EmailAddress), 'check collections - after init')
    travel 1.second
    result2 = collection_client2.push
    assert(result2, 'check collections')
    assert(check_if_collection_exists(result2, :Group), 'check collections - after init')
    assert(check_if_collection_exists(result2, :Role), 'check collections - after init')
    assert(check_if_collection_exists(result2, :Signature), 'check collections - after init')
    assert(check_if_collection_exists(result2, :EmailAddress), 'check collections - after init')

    assert_equal(result1.length, result2.length, 'check collections')
    assert_equal(result1[0], result2[0], 'check collections')
    assert_equal(result1[1], result2[1], 'check collections')
    assert_equal(result1[2], result2[2], 'check collections')
    assert_equal(result1[3], result2[3], 'check collections')
    assert_equal(result1[4], result2[4], 'check collections')
    assert_equal(result1[5], result2[5], 'check collections')
    assert_equal(result1[6], result2[6], 'check collections')
    assert_equal(result1[7], result2[7], 'check collections')
    assert_equal(result1[8], result2[8], 'check collections')
    assert_equal(result1[9], result2[9], 'check collections')

    assert_equal(result1, result2, 'check collections')

    result3 = collection_client3.push
    assert(result3, 'check collections')
    assert(check_if_collection_exists(result3, :Group), 'check collections - after init')
    assert(check_if_collection_exists(result3, :Role), 'check collections - after init')
    assert_not(check_if_collection_exists(result3, :Signature), 'check collections - after init')
    assert_not(check_if_collection_exists(result3, :EmailAddress), 'check collections - after init')

    # next check should be empty
    result1 = collection_client1.push
    assert(result1.blank?, 'check collections - recall')
    travel 0.4.seconds
    result2 = collection_client2.push
    assert(result2.blank?, 'check collections - recall')
    result3 = collection_client3.push
    assert(result3.blank?, 'check collections - recall')

    # change collection
    group = Group.first
    travel 6.seconds
    group.touch
    travel 6.seconds

    # get whole collections
    result1 = collection_client1.push

    assert(result1, 'check collections - after touch')
    assert(check_if_collection_exists(result1, :Group), 'check collections - after touch')
    travel 0.1.seconds
    result2 = collection_client2.push
    assert(result2, 'check collections - after touch')
    assert(check_if_collection_exists(result2, :Group), 'check collections - after touch')
    result3 = collection_client3.push
    assert(result3, 'check collections - after touch')
    assert(check_if_collection_exists(result3, :Group), 'check collections - after touch')

    # next check should be empty
    travel 0.5.seconds
    result1 = collection_client1.push
    assert(result1.blank?, 'check collections - recall')
    result2 = collection_client2.push
    assert(result2.blank?, 'check collections - recall')
    result3 = collection_client3.push
    assert(result3.blank?, 'check collections - recall')

    travel 10.seconds
    Sessions.destroy_idle_sessions(3)

    travel_back
  end

  def check_if_collection_exists(results, collection, attributes = nil)
    results.each do |result|
      next if !result
      next if !result[:collection]
      next if !result[:collection][collection]

      # check just if collection exists
      return true if !attributes

      # check if objetc with attributes in collection exists
      result[:collection][collection].each do |item|
        match_all = true
        attributes.each do |key, value|

          # sort array, database result maybe unsorted
          item_attributes = item[ key.to_s ]
          if item[ key.to_s ].class == Array
            item_attributes.sort!
          end
          if value.class == Array
            value.sort!
          end

          # compare values
          if item_attributes != value
            #p "FAILED: #{key} -> #{item_attributes.inspect} vs. #{value.inspect}"
            match_all = false
          end
        end
        return true if match_all
      end
    end
    nil
  end

  test 'b assets' do
    roles  = Role.where(name: %w[Agent Admin])
    groups = Group.all.order(id: :asc)

    UserInfo.current_user_id = 2
    agent1 = User.create_or_update(
      login:     "sessions-assets-1-#{rand(99_999)}",
      firstname: 'Session',
      lastname:  "sessions assets #{rand(99_999)}",
      email:     'sessions-assets1@example.com',
      password:  'agentpw',
      active:    true,
      roles:     roles,
      groups:    groups,
    )
    assert(agent1.save!, 'create/update agent1')

    assets = {}
    client1 = Sessions::Backend::Collections::Group.new(agent1, assets, false, '123-1', 4)
    data = client1.push
    assert_equal(data[:collection][:Group][0]['id'], groups[0].id)
    assert(data[:assets][:Group][groups.first.id])
    travel 10.seconds

    client1 = Sessions::Backend::Collections::Group.new(agent1, assets, false, '123-1', 4)
    data = client1.push
    assert_equal(data[:collection][:Group][0]['id'], groups[0].id)
    assert(data[:assets])
    assert_not(data[:assets][:Group])

    travel 125.minutes

    client1 = Sessions::Backend::Collections::Group.new(agent1, assets, false, '123-1', 4)
    data = client1.push
    assert_equal(data[:collection][:Group][0]['id'], groups[0].id)
    assert(data[:assets][:Group][groups.first.id])

    travel 2.minutes
    client1 = Sessions::Backend::Collections::Group.new(agent1, assets, false, '123-1', 4)
    data = client1.push
    assert_equal(data[:collection][:Group][0]['id'], groups[0].id)
    assert_nil(data[:assets][:Group])

    travel 10.seconds
    Sessions.destroy_idle_sessions(3)

    travel_back
  end

end
