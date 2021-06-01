# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketScreenOptionsTest < ActiveSupport::TestCase

  test 'base' do

    group1 = Group.create!(
      name:          'Group 1',
      active:        true,
      email_address: EmailAddress.first,
      created_by_id: 1,
      updated_by_id: 1,
    )
    group2 = Group.create!(
      name:          'Group 2',
      active:        true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    group3 = Group.create!(
      name:          'Group 3',
      active:        true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    agent1 = User.create!(
      login:         'agent1@example.com',
      firstname:     'Role',
      lastname:      'Agent1',
      email:         'agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent1.group_names_access_map = {
      group1.name => 'full',
      group2.name => %w[read change],
      group3.name => 'full',
    }

    agent2 = User.create!(
      login:         'agent2@example.com',
      firstname:     'Role',
      lastname:      'Agent2',
      email:         'agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2.group_names_access_map = {
      group1.name => 'full',
      group2.name => %w[read change],
      group3.name => ['create'],
    }

    agent3 = User.create!(
      login:         'agent3@example.com',
      firstname:     'Role',
      lastname:      'Agent3',
      email:         'agent3@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent3.group_names_access_map = {
      group1.name => 'full',
      group2.name => ['full'],
    }

    agent4 = User.create!(
      login:         'agent4@example.com',
      firstname:     'Role',
      lastname:      'Agent4',
      email:         'agent4@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent4.group_names_access_map = {
      group1.name => 'full',
      group2.name => %w[read overview change],
    }

    agent5 = User.create!(
      login:         'agent5@example.com',
      firstname:     'Role',
      lastname:      'Agent5',
      email:         'agent5@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent5.group_names_access_map = {
      group3.name => 'full',
    }

    User.create!(
      login:         'agent6@example.com',
      firstname:     'Role',
      lastname:      'Agent6',
      email:         'agent6@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    result = Ticket::ScreenOptions.attributes_to_change(
      current_user: agent1,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id, group3.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id])
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id])
    assert_equal(2, result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent5.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      current_user: agent2,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id, group3.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert_equal(2, result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent5.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      current_user: agent3,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(3, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))

    ticket1 = Ticket.create!(
      title:         'some title 1',
      group:         group1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket2 = Ticket.create!(
      title:         'some title 2',
      group:         group2,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id:     ticket2.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    result = Ticket::ScreenOptions.attributes_to_change(
      ticket_id:    ticket1.id,
      current_user: agent1,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'new').id,
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([
                   Ticket::Article::Type.lookup(name: 'email').id,
                   Ticket::Article::Type.lookup(name: 'phone').id,
                   Ticket::Article::Type.lookup(name: 'note').id,
                 ], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id, group3.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert(result[:form_meta][:dependencies][:group_id][group2.id])
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id])
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id])
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id])
    assert_equal(2, result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent5.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      ticket_id:    ticket2.id,
      current_user: agent1,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'new').id,
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([
                   Ticket::Article::Type.lookup(name: 'phone').id,
                   Ticket::Article::Type.lookup(name: 'note').id,
                 ], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id, group3.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert(result[:form_meta][:dependencies][:group_id][group2.id])
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id])
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id])
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id])
    assert_equal(2, result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent5.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      ticket_id:    ticket2.id,
      current_user: agent1,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'new').id,
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([
                   Ticket::Article::Type.lookup(name: 'phone').id,
                   Ticket::Article::Type.lookup(name: 'note').id,
                 ], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id, group3.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert(result[:form_meta][:dependencies][:group_id][group2.id])
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id])
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id])
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id])
    assert_equal(2, result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group3.id][:owner_id].include?(agent5.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      ticket_id:    ticket1.id,
      current_user: agent2,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'new').id,
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([
                   Ticket::Article::Type.lookup(name: 'email').id,
                   Ticket::Article::Type.lookup(name: 'phone').id,
                   Ticket::Article::Type.lookup(name: 'note').id,
                 ], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id, group3.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert(result[:form_meta][:dependencies][:group_id][group2.id])
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id])
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      ticket_id:    ticket2.id,
      current_user: agent2,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'new').id,
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([
                   Ticket::Article::Type.lookup(name: 'phone').id,
                   Ticket::Article::Type.lookup(name: 'note').id,
                 ], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id, group3.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert(result[:form_meta][:dependencies][:group_id][group2.id])
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id])
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      ticket_id:    ticket1.id,
      current_user: agent3,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'new').id,
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([
                   Ticket::Article::Type.lookup(name: 'email').id,
                   Ticket::Article::Type.lookup(name: 'phone').id,
                   Ticket::Article::Type.lookup(name: 'note').id,
                 ], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(3, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))

    result = Ticket::ScreenOptions.attributes_to_change(
      ticket_id:    ticket2.id,
      current_user: agent3,
    )

    assert(result[:form_meta])
    assert(result[:form_meta][:filter])
    assert(result[:form_meta][:filter][:state_id])
    assert_equal([
                   Ticket::State.lookup(name: 'new').id,
                   Ticket::State.lookup(name: 'open').id,
                   Ticket::State.lookup(name: 'pending reminder').id,
                   Ticket::State.lookup(name: 'closed').id,
                   Ticket::State.lookup(name: 'pending close').id,
                 ], result[:form_meta][:filter][:state_id].sort)
    assert(result[:form_meta][:filter][:priority_id])
    assert_equal([
                   Ticket::Priority.lookup(name: '1 low').id,
                   Ticket::Priority.lookup(name: '2 normal').id,
                   Ticket::Priority.lookup(name: '3 high').id,
                 ], result[:form_meta][:filter][:priority_id].sort)
    assert(result[:form_meta][:filter][:type_id])
    assert_equal([
                   Ticket::Article::Type.lookup(name: 'phone').id,
                   Ticket::Article::Type.lookup(name: 'note').id,
                 ], result[:form_meta][:filter][:type_id].sort)
    assert(result[:form_meta][:filter][:group_id])
    assert_equal([group1.id, group2.id], result[:form_meta][:filter][:group_id].sort)
    assert(result[:form_meta][:dependencies])
    assert(result[:form_meta][:dependencies][:group_id])
    assert_equal(3, result[:form_meta][:dependencies][:group_id].count)
    assert(result[:form_meta][:dependencies][:group_id][''])
    assert(result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert_equal([], result[:form_meta][:dependencies][:group_id][''][:owner_id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id])
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id])
    assert_equal(4, result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent1.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent2.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent3.id))
    assert(result[:form_meta][:dependencies][:group_id][group1.id][:owner_id].include?(agent4.id))
    assert_equal(1, result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].count)
    assert(result[:form_meta][:dependencies][:group_id][group2.id][:owner_id].include?(agent3.id))

  end

end
