# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process tag filter', type: :model do

  before do
    PostmasterFilter.destroy_all
    filters.each do |filter|
      PostmasterFilter.create!(filter)
    end
  end

  let(:extra_filter)  { [] }
  let(:group_default) { Group.lookup(name: 'Users') }
  let(:group_first)   { create(:group, name: 'First group') }
  let(:group_second)  { create(:group, name: 'Second group') }
  let(:email)         { Channel::EmailParser.new.process({ group_id: group_default.id, trusted: false }, data) }
  let(:ticket)        { email[0] }
  let(:article)       { email[1] }

  context 'with multiple filters' do
    let(:filters) do
      [
        {
          name:          'RSpec: Channel::EmailParser#process',
          match:         {
            from: {
              operator: 'contains',
              value:    'nobody@example.com',
            },
          },
          perform:       {
            'x-zammad-ticket-tags' => {
              operator: 'add',
              value:    'test1, test2, test3',
            },
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        },
        {
          name:          'RSpec: Channel::EmailParser#process',
          match:         {
            from: {
              operator: 'contains',
              value:    'nobody@example.com',
            },
          },
          perform:       {
            'x-zammad-ticket-tags' => {
              operator: 'remove',
              value:    'test2, test3',
            },
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        },
        {
          name:          'RSpec: Channel::EmailParser#process',
          match:         {
            from: {
              operator: 'contains',
              value:    'nobody@example.com',
            },
          },
          perform:       {
            'x-zammad-ticket-tags' => {
              operator: 'add',
              value:    'test3',
            },
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        },
        {
          name:          'RSpec: Channel::EmailParser#process',
          match:         {
            from: {
              operator: 'contains',
              value:    'nobody@example.com',
            },
          },
          perform:       {
            'x-zammad-ticket-tags' => {
              operator: 'add',
              value:    'abc1  ,   abc2   ',
            },
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        }
      ]
    end

    let(:data) do
      <<~MAIL
        From: ME BOB <nobody@example.com>
        To: customer@example.com
        Subject: some subject

        Some Text
      MAIL
    end

    it 'modifies ticket', :aggregate_failures do
      expect(ticket.group.name).to match(group_default.name)
      expect(ticket.priority.name).to match('2 normal')
      expect(ticket.title).to match('some subject')
      expect(ticket.customer.email).to match('nobody@example.com')
    end

    it 'include tags' do
      tags = Tag.tag_list(object: 'Ticket', o_id: ticket.id)
      expect(tags).to match_array(%w[test1 test3 abc1 abc2])
    end
  end
end
