# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ElasticsearchActiveTest < ActiveSupport::TestCase
  include SearchindexHelper

  setup do

    configure_elasticsearch(required: true)

    rebuild_searchindex

    roles = Role.where(name: 'Agent')

    @agent = User.create!(
      login:         'es-agent@example.com',
      firstname:     'E',
      lastname:      'S',
      email:         'es-agent@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    roles = Role.where(name: 'Customer')

    (1..6).each do |i|
      name = i.even? ? "Active-#{i}" : "Inactive-#{i}"
      User.create!(
        login:         "#{name}-customer#{i}@example.com",
        firstname:     'ActiveTest',
        lastname:      name,
        active:        i.even?,
        roles:         roles,
        updated_by_id: 1,
        created_by_id: 1,
      )
      Organization.create!(
        name:          "TestOrg-#{name}",
        active:        i.even?,
        updated_by_id: 1,
        created_by_id: 1,
      )
      travel 10.seconds
    end

    # execute background jobs to index created/changed objects
    Scheduler.worker(true)
    sleep 2 # for ES to come ready/indexed
  end

  test 'active users appear before inactive users in search results' do
    result = User.search(
      current_user: @agent,
      query:        'ActiveTest',
      limit:        15,
    )
    assert(result.present?, 'result should not be empty')

    names = result.map(&:lastname)
    correct_names = %w[Active-2 Active-4 Active-6 Inactive-1 Inactive-3 Inactive-5]
    assert_equal(correct_names[0, 3], names[0, 3].sort)
    assert_equal(correct_names[3, 6], names[3, 6].sort)
  end

  test 'active organizations appear before inactive organizations in search results' do
    result = Organization.search(
      current_user: @agent,
      query:        'TestOrg',
      limit:        15,
    )
    assert(result.present?, 'result should not be empty')

    names = result.map(&:name)
    correct_names = %w[TestOrg-Active-2
                       TestOrg-Active-4
                       TestOrg-Active-6
                       TestOrg-Inactive-1
                       TestOrg-Inactive-3
                       TestOrg-Inactive-5]
    assert_equal(correct_names[0, 3], names[0, 3].sort)
    assert_equal(correct_names[3, 6], names[3, 6].sort)
  end

  test 'ordering of tickets are not affected by the lack of active flags' do
    ticket_setup

    result = Ticket.search(
      current_user: User.find(1),
      query:        'ticket',
      limit:        15,
    )
    assert(result.present?, 'result should not be empty')

    names = result.map(&:title)
    correct_names = %w[Ticket-6 Ticket-5 Ticket-4 Ticket-3 Ticket-2 Ticket-1]
    assert_equal(correct_names, names)
  end

  def ticket_setup
    result = Ticket.search(
      current_user: User.find(1),
      query:        'ticket',
      limit:        15,
    )
    return if result.present?

    (1..6).each do |i|
      Ticket.create!(
        title:         "Ticket-#{i}",
        group:         Group.lookup(name: 'Users'),
        customer_id:   1,
        state:         Ticket::State.lookup(name: 'new'),
        priority:      Ticket::Priority.lookup(name: '2 normal'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      travel 10.seconds
    end

    # execute background jobs to index created/changed objects
    Scheduler.worker(true)
    sleep 2 # for ES to come ready/indexed
  end
end
