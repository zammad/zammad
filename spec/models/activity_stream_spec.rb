# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActivityStream, type: :model do
  let(:roles)        { Role.where(name: %w[Admin Agent]) }
  let(:groups)       { Group.where(name: 'Users') }
  let(:admin_user) do
    User.create_or_update(
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
  end
  let(:current_user) { User.lookup(email: 'nicole.braun@zammad.org') }

  before do
    Setting.set('system_init_done', true)
    admin_user
    described_class.delete_all
  end

  describe 'ticket + ticket article', :aggregate_failures do
    it 'records create, update and destroy events in the correct order' do # rubocop:disable RSpec/ExampleLength
      ticket = Ticket.create!(
        group_id:      Group.lookup(name: 'Users').id,
        customer_id:   current_user.id,
        owner_id:      User.lookup(login: '-').id,
        title:         'Unit Test 1 (äöüß)!',
        state_id:      Ticket::State.lookup(name: 'new').id,
        priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
        updated_by_id: current_user.id,
        created_by_id: current_user.id,
      )
      travel 2.seconds

      article = Ticket::Article.create!(
        ticket_id:     ticket.id,
        updated_by_id: current_user.id,
        created_by_id: current_user.id,
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
      stream = admin_user.activity_stream(4)
      expect(stream[0].group_id).to       eq(ticket.group_id)
      expect(stream[0].o_id).to           eq(ticket.id)
      expect(stream[0].created_by_id).to  eq(current_user.id)
      expect(stream[0].created_at.to_s).to eq(updated_at.to_s)
      expect(stream[0].object.name).to    eq('Ticket')
      expect(stream[0].type.name).to      eq('update')
      expect(stream[1].group_id).to       eq(ticket.group_id)
      expect(stream[1].o_id).to           eq(article.id)
      expect(stream[1].created_by_id).to  eq(current_user.id)
      expect(stream[1].created_at.to_s).to eq(article.created_at.to_s)
      expect(stream[1].object.name).to    eq('Ticket::Article')
      expect(stream[1].type.name).to      eq('create')
      expect(stream[2].group_id).to       eq(ticket.group_id)
      expect(stream[2].o_id).to           eq(ticket.id)
      expect(stream[2].created_by_id).to  eq(current_user.id)
      expect(stream[2].created_at.to_s).to eq(ticket.created_at.to_s)
      expect(stream[2].object.name).to    eq('Ticket')
      expect(stream[2].type.name).to      eq('create')
      expect(stream[3]).to be_nil

      stream = current_user.activity_stream(4)
      expect(stream).to be_blank

      # delete article and check if entry has gone
      article.destroy!

      # check activity_stream
      stream = admin_user.activity_stream(4)
      expect(stream[0].group_id).to       eq(ticket.group_id)
      expect(stream[0].o_id).to           eq(ticket.id)
      expect(stream[0].created_by_id).to  eq(current_user.id)
      expect(stream[0].created_at.to_s).to eq(updated_at.to_s)
      expect(stream[0].object.name).to    eq('Ticket')
      expect(stream[0].type.name).to      eq('update')
      expect(stream[1].group_id).to       eq(ticket.group_id)
      expect(stream[1].o_id).to           eq(ticket.id)
      expect(stream[1].created_by_id).to  eq(current_user.id)
      expect(stream[1].created_at.to_s).to eq(ticket.created_at.to_s)
      expect(stream[1].object.name).to    eq('Ticket')
      expect(stream[1].type.name).to      eq('create')
      expect(stream[2]).to be_nil

      stream = current_user.activity_stream(4)
      expect(stream).to be_blank

      # cleanup
      ticket.destroy!
      travel_back
    end
  end

  describe 'organization', :aggregate_failures do
    it 'records create and update events' do
      organization = Organization.create!(
        name:          'some name',
        updated_by_id: current_user.id,
        created_by_id: current_user.id,
      )
      travel 100.seconds
      expect(organization).to be_an(Organization)

      organization.update!(name: 'some name (äöüß)')
      updated_at = organization.updated_at

      travel 10.seconds
      organization.update!(name: 'some name 2 (äöüß)')

      # check activity_stream
      stream = admin_user.activity_stream(3)
      expect(stream[0].group_id).to       be_nil
      expect(stream[0].o_id).to           eq(organization.id)
      expect(stream[0].created_by_id).to  eq(current_user.id)
      expect(stream[0].created_at.to_s).to eq(updated_at.to_s)
      expect(stream[0].object.name).to    eq('Organization')
      expect(stream[0].type.name).to      eq('update')
      expect(stream[1].group_id).to       be_nil
      expect(stream[1].o_id).to           eq(organization.id)
      expect(stream[1].created_by_id).to  eq(current_user.id)
      expect(stream[1].created_at.to_s).to eq(organization.created_at.to_s)
      expect(stream[1].object.name).to    eq('Organization')
      expect(stream[1].type.name).to      eq('create')
      expect(stream[2]).to be_nil

      stream = current_user.activity_stream(4)
      expect(stream).to be_blank

      # cleanup
      organization.destroy!
      travel_back
    end
  end

  describe 'user with immediate update (no separate update entry)', :aggregate_failures do
    it 'records only the create event' do
      user = User.create!(
        login:         'someemail@example.com',
        email:         'someemail@example.com',
        firstname:     'Bob Smith II',
        updated_by_id: current_user.id,
        created_by_id: current_user.id,
      )
      expect(user).to be_an(User)
      user.update!(
        firstname: 'Bob U',
        lastname:  'Smith U',
      )

      # check activity_stream
      stream = admin_user.activity_stream(3)
      expect(stream[0].group_id).to       be_nil
      expect(stream[0].o_id).to           eq(user.id)
      expect(stream[0].created_by_id).to  eq(current_user.id)
      expect(stream[0].created_at.to_s).to eq(user.created_at.to_s)
      expect(stream[0].object.name).to    eq('User')
      expect(stream[0].type.name).to      eq('create')
      expect(stream[1]).to be_nil

      stream = current_user.activity_stream(4)
      expect(stream).to be_blank

      # cleanup
      user.destroy!
      travel_back
    end
  end

  describe 'user with delayed update', :aggregate_failures do
    it 'records both create and update events' do
      user = User.create!(
        login:         'someemail@example.com',
        email:         'someemail@example.com',
        firstname:     'Bob Smith II',
        updated_by_id: current_user.id,
        created_by_id: current_user.id,
      )
      travel 100.seconds
      expect(user).to be_an(User)

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
      stream = admin_user.activity_stream(3)
      expect(stream[0].group_id).to       be_nil
      expect(stream[0].o_id).to           eq(user.id)
      expect(stream[0].created_by_id).to  eq(current_user.id)
      expect(stream[0].created_at.to_s).to eq(updated_at.to_s)
      expect(stream[0].object.name).to    eq('User')
      expect(stream[0].type.name).to      eq('update')
      expect(stream[1].group_id).to       be_nil
      expect(stream[1].o_id).to           eq(user.id)
      expect(stream[1].created_by_id).to  eq(current_user.id)
      expect(stream[1].created_at.to_s).to eq(user.created_at.to_s)
      expect(stream[1].object.name).to    eq('User')
      expect(stream[1].type.name).to      eq('create')
      expect(stream[2]).to be_nil

      stream = current_user.activity_stream(4)
      expect(stream).to be_blank

      # cleanup
      user.destroy!
      travel_back
    end
  end
end
