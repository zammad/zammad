# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with simple filter', aggregate_failures: true, type: :model do

  before do
    PostmasterFilter.destroy_all
    PostmasterFilter.create!(filter)
  end

  let(:group_default) { Group.lookup(name: 'Users') }
  let(:group_first)   { create(:group, name: 'First group') }
  let(:email)         { Channel::EmailParser.new.process({ group_id: group_default.id, trusted: false }, data) }
  let(:ticket)        { email[0] }
  let(:article)       { email[1] }
  let(:filter) do
    {
      name:          'RSpec: Channel::EmailParser#process',
      match:         matcher,
      perform:       {
        'X-Zammad-Ticket-group_id'    => {
          value: group.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal'   => {
          value: true,
        },
      },
      channel:       'email',
      active:        true,
      created_by_id: 1,
      updated_by_id: 1,
    }
  end

  shared_examples 'filtered' do |params|
    it 'modifies ticket' do
      expect(ticket.group.name).to match(group.name)
      expect(ticket.priority.name).to match(params[:priority])
      expect(ticket.title).to match(params[:title])
    end

    it 'modifies article' do
      expect(article.sender.name).to match('Customer')
      expect(article.type.name).to match('email')
      expect(article.internal).to be true
    end
  end

  shared_examples 'not_filtered' do |params|
    it 'not modifies ticket' do
      expect(ticket.group.name).to match(group_default.name)
      expect(ticket.priority.name).to match('2 normal')
      expect(ticket.title).to match(params[:title])
    end

    it 'not modifies article' do
      expect(article.sender.name).to match('Customer')
      expect(article.type.name).to match('email')
      expect(article.internal).to be false
    end
  end

  context 'when from match value: regex:.*' do
    let(:data) do
      <<~MAIL
        From: Some Body <somebody@example.com>
        To: Bob <bod@example.com>
        Cc: any@example.com
        Subject: some subject - no selector

        Some Text
      MAIL
    end
    let(:group) { group_first }
    let(:matcher) do
      {
        from: {
          operator: 'contains',
          value:    'regex:.*',
        }
      }
    end

    include_examples('filtered', title:    'some subject - no selector',
                                 priority: '1 low')
  end

  context 'when from match value: *' do
    let(:data) do
      <<~MAIL
        From: Some Body <somebody@example.com>
        To: Bob <bod@example.com>
        Cc: any@example.com
        Subject: some subject - no selector

        Some Text
      MAIL
    end
    let(:group) { group_first }
    let(:matcher) do
      {
        from: {
          operator: 'contains',
          value:    '*',
        }
      }
    end

    include_examples('filtered',
                     title:    'some subject - no selector',
                     priority: '1 low')
  end

  context 'when subject match value: *me*' do
    let(:data) do
      <<~MAIL
        From: Some Body <somebody@example.com>
        To: Bob <bod@example.com>
        Cc: any@example.com
        Subject: *me*

        Some Text
      MAIL
    end
    let(:group) { group_first }
    let(:matcher) do
      {
        subject: {
          operator: 'contains',
          value:    '*me*',
        }
      }
    end

    include_examples('filtered', title:    '*me*',
                                 priority: '1 low')

  end

  context 'when not subject match value: *me* and email subject: *mo*' do
    let(:data) do
      <<~MAIL
        From: Some Body <somebody@example.com>
        To: Bob <bod@example.com>
        Cc: any@example.com
        Subject: *mo*

        Some Text
      MAIL
    end
    let(:group) { group_first }
    let(:matcher) do
      {
        subject: {
          operator: 'contains not',
          value:    '*me*',
        }
      }
    end

    include_examples('filtered', title:    '*mo*',
                                 priority: '1 low')

  end

  context 'when not subject match value: *me* and email subject: *me*' do
    let(:data) do
      <<~MAIL
        From: Some Body <somebody@example.com>
        To: Bob <bod@example.com>
        Cc: any@example.com
        Subject: *me*

        Some Text
      MAIL
    end
    let(:group) { group_first }
    let(:matcher) do
      {
        subject: {
          operator: 'contains not',
          value:    '*me*',
        }
      }
    end

    include_examples('not_filtered', title: '*me*')
  end

  context 'when message-id match value: @sombody.domain' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          'message-id': {
            operator: 'contains',
            value:    '@sombody.domain>',
          },
        },
        perform:       {
          'X-Zammad-Ticket-priority_id' => {
            value: '1',
          },
          'x-Zammad-Article-Internal'   => {
            value: true,
          },
        },
        channel:       'email',
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      }
    end
    let(:data) do
      <<~MAIL
        From: Some Body <somebody@example.com>
        To: Bob <bod@example.com>
        Cc: any@example.com
        Subject: *me*
        Message-Id: <1520781034.17887@sombody.domain>

        Some Text
      MAIL
    end
    let(:group) { group_default }

    include_examples('filtered', title:    '*me*',
                                 priority: '1 low')
  end

  context 'when perform customer_id empty and from match value: me@example.com' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          from: {
            operator: 'contains',
            value:    'me@example.com',
          },
        },
        perform:       {
          'X-Zammad-Ticket-group_id'    => {
            value: group.id,
          },
          'x-Zammad-Article-Internal'   => {
            value: true,
          },
          'x-Zammad-Ticket-customer_id' => {
            value:            '',
            value_completion: '',
          },
        },
        channel:       'email',
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      }
    end
    let(:data) do
      <<~MAIL
        From: ME Bob <me@example.com>
        To: customer@example.com
        Subject: some subject

        Some Text
      MAIL
    end
    let(:group) { group_first }

    include_examples('filtered', title:    'some subject',
                                 priority: '2 normal')

    it 'modifies customer email' do
      expect(ticket.customer.email).to match('me@example.com')
    end
  end

  context 'when perform customer_id has high value and from match value: me@example.com' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          from: {
            operator: 'contains',
            value:    'me@example.com',
          },
        },
        perform:       {
          'X-Zammad-Ticket-group_id'    => {
            value: group.id,
          },
          'x-Zammad-Article-Internal'   => {
            value: true,
          },
          'x-Zammad-Ticket-customer_id' => {
            value:            999_999,
            value_completion: 'xxx',
          },
        },
        channel:       'email',
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      }
    end
    let(:data) do
      <<~MAIL
        From: ME Bob <me@example.com>
        To: customer@example.com
        Subject: some subject

        Some Text
      MAIL
    end
    let(:group) { group_first }

    include_examples('filtered', title:    'some subject',
                                 priority: '2 normal')

    it 'modifies customer email' do
      expect(ticket.customer.email).to match('me@example.com')
    end
  end

  context 'when perform customer_id and priority_id has high value and from match value: me@example.com' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          from: {
            operator: 'contains',
            value:    'me@example.com',
          },
        },
        perform:       {
          'X-Zammad-Ticket-group_id'    => {
            value: group.id,
          },
          'X-Zammad-Ticket-priority_id' => {
            value: 888_888,
          },
          'x-Zammad-Article-Internal'   => {
            value: true,
          },
          'x-Zammad-Ticket-customer_id' => {
            value:            999_999,
            value_completion: 'xxx',
          },
        },
        channel:       'email',
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      }
    end
    let(:data) do
      <<~MAIL
        From: ME Bob <me@example.com>
        To: customer@example.com
        Subject: some subject

        Some Text
      MAIL
    end
    let(:group) { group_first }

    include_examples('filtered', title:    'some subject',
                                 priority: '2 normal')

    it 'modifies customer email' do
      expect(ticket.customer.email).to match('me@example.com')
    end
  end
end
