# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ActivityStreamTest < ActiveSupport::TestCase

  setup do
    roles = Role.where(name: %w[Admin Agent])
    groups = Group.where(name: 'Users')
    @admin_user = User.create_or_update(
      login:         'admin',
      firstname:     'Bob',
      lastname:      'Smith',
      email:         'bob+active_stream@example.com',
      password:      'some_pass',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1
    )
    @current_user = User.lookup(email: 'nicole.braun@zammad.org')
    ActivityStream.delete_all
  end

  test 'ticket+user' do
    ticket = Ticket.create!(
      group_id:      Group.lookup(name: 'Users').id,
      customer_id:   @current_user.id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Unit Test 1 (äöüß)!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: @current_user.id,
      created_by_id: @current_user.id,
    )
    travel 2.seconds

    article = Ticket::Article.create!(
      ticket_id:     ticket.id,
      updated_by_id: @current_user.id,
      created_by_id: @current_user.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Unit Test <unittest@example.com>',
      body:          'Unit Test 123',
      internal:      false,
    )

    travel 100.seconds
    ticket.update!(
      title:       'Unit Test 1 (äöüß) - update!',
      state_id:    Ticket::State.lookup(name: 'open').id,
      priority_id: Ticket::Priority.lookup(name: '1 low').id,
    )
    updated_at = ticket.updated_at

    travel 1.second
    ticket.update!(
      title:       'Unit Test 2 (äöüß) - update!',
      priority_id: Ticket::Priority.lookup(name: '2 normal').id,
    )

    # check activity_stream
    stream = @admin_user.activity_stream(4)
    assert_equal(stream[0].group_id, ticket.group_id)
    assert_equal(stream[0].o_id, ticket.id)
    assert_equal(stream[0].created_by_id, @current_user.id)
    assert_equal(stream[0].created_at.to_s, updated_at.to_s)
    assert_equal(stream[0].object.name, 'Ticket')
    assert_equal(stream[0].type.name, 'update')
    assert_equal(stream[1].group_id, ticket.group_id)
    assert_equal(stream[1].o_id, article.id)
    assert_equal(stream[1].created_by_id, @current_user.id)
    assert_equal(stream[1].created_at.to_s, article.created_at.to_s)
    assert_equal(stream[1].object.name, 'Ticket::Article')
    assert_equal(stream[1].type.name, 'create')
    assert_equal(stream[2].group_id, ticket.group_id)
    assert_equal(stream[2].o_id, ticket.id)
    assert_equal(stream[2].created_by_id, @current_user.id)
    assert_equal(stream[2].created_at.to_s, ticket.created_at.to_s)
    assert_equal(stream[2].object.name, 'Ticket')
    assert_equal(stream[2].type.name, 'create')
    assert_not(stream[3])

    stream = @current_user.activity_stream(4)
    assert(stream.blank?)

    # delete article and check if entry has gone
    article.destroy!

    # check activity_stream
    stream = @admin_user.activity_stream(4)
    assert_equal(stream[0].group_id, ticket.group_id)
    assert_equal(stream[0].o_id, ticket.id)
    assert_equal(stream[0].created_by_id, @current_user.id)
    assert_equal(stream[0].created_at.to_s, updated_at.to_s)
    assert_equal(stream[0].object.name, 'Ticket')
    assert_equal(stream[0].type.name, 'update')
    assert_equal(stream[1].group_id, ticket.group_id)
    assert_equal(stream[1].o_id, ticket.id)
    assert_equal(stream[1].created_by_id, @current_user.id)
    assert_equal(stream[1].created_at.to_s, ticket.created_at.to_s)
    assert_equal(stream[1].object.name, 'Ticket')
    assert_equal(stream[1].type.name, 'create')
    assert_not(stream[2])

    stream = @current_user.activity_stream(4)
    assert(stream.blank?)

    # cleanup
    ticket.destroy!
    travel_back
  end

  test 'organization' do
    organization = Organization.create!(
      name:          'some name',
      updated_by_id: @current_user.id,
      created_by_id: @current_user.id,
    )
    travel 100.seconds
    assert_equal(organization.class, Organization)

    organization.update!(name: 'some name (äöüß)')
    updated_at = organization.updated_at

    travel 10.seconds
    organization.update!(name: 'some name 2 (äöüß)')

    # check activity_stream
    stream = @admin_user.activity_stream(3)
    assert_not(stream[0].group_id)
    assert_equal(stream[0].o_id, organization.id)
    assert_equal(stream[0].created_by_id, @current_user.id)
    assert_equal(stream[0].created_at.to_s, updated_at.to_s)
    assert_equal(stream[0].object.name, 'Organization')
    assert_equal(stream[0].type.name, 'update')
    assert_not(stream[1].group_id)
    assert_equal(stream[1].o_id, organization.id)
    assert_equal(stream[1].created_by_id, @current_user.id)
    assert_equal(stream[1].created_at.to_s, organization.created_at.to_s)
    assert_equal(stream[1].object.name, 'Organization')
    assert_equal(stream[1].type.name, 'create')
    assert_not(stream[2])

    stream = @current_user.activity_stream(4)
    assert(stream.blank?)

    # cleanup
    organization.destroy!
    travel_back
  end

  test 'user with update check false' do
    user = User.create!(
      login:         'someemail@example.com',
      email:         'someemail@example.com',
      firstname:     'Bob Smith II',
      updated_by_id: @current_user.id,
      created_by_id: @current_user.id,
    )
    assert_equal(user.class, User)
    user.update!(
      firstname: 'Bob U',
      lastname:  'Smith U',
    )

    # check activity_stream
    stream = @admin_user.activity_stream(3)
    assert_not(stream[0].group_id)
    assert_equal(stream[0].o_id, user.id)
    assert_equal(stream[0].created_by_id, @current_user.id)
    assert_equal(stream[0].created_at.to_s, user.created_at.to_s)
    assert_equal(stream[0].object.name, 'User')
    assert_equal(stream[0].type.name, 'create')
    assert_not(stream[1])

    stream = @current_user.activity_stream(4)
    assert(stream.blank?)

    # cleanup
    user.destroy!
    travel_back
  end

  test 'user with update check true' do
    user = User.create!(
      login:         'someemail@example.com',
      email:         'someemail@example.com',
      firstname:     'Bob Smith II',
      updated_by_id: @current_user.id,
      created_by_id: @current_user.id,
    )
    travel 100.seconds
    assert_equal(user.class, User)

    user.update!(
      firstname: 'Bob U',
      lastname:  'Smith U',
    )
    updated_at = user.updated_at

    travel 10.seconds
    user.update!(
      firstname: 'Bob',
      lastname:  'Smith',
    )

    # check activity_stream
    stream = @admin_user.activity_stream(3)
    assert_not(stream[0].group_id)
    assert_equal(stream[0].o_id, user.id)
    assert_equal(stream[0].created_by_id, @current_user.id)
    assert_equal(stream[0].created_at.to_s, updated_at.to_s)
    assert_equal(stream[0].object.name, 'User')
    assert_equal(stream[0].type.name, 'update')
    assert_not(stream[1].group_id)
    assert_equal(stream[1].o_id, user.id)
    assert_equal(stream[1].created_by_id, @current_user.id)
    assert_equal(stream[1].created_at.to_s, user.created_at.to_s)
    assert_equal(stream[1].object.name, 'User')
    assert_equal(stream[1].type.name, 'create')
    assert_not(stream[2])

    stream = @current_user.activity_stream(4)
    assert(stream.blank?)

    # cleanup
    user.destroy!
    travel_back
  end

end
