# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with multiple filter', aggregate_failures: true, type: :model do

  before do
    PostmasterFilter.destroy_all
    filters.push(extra_filter) if !extra_filter.empty?
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

  shared_examples 'filtered' do |params|
    it 'modifies ticket' do
      expect(ticket.group.name).to match(group.name)
      expect(ticket.priority.name).to match(params[:priority])
      expect(ticket.title).to match(params[:title])
    end

    it 'modifies article' do
      expect(article.sender.name).to match('Customer')
      expect(article.type.name).to match('email')
      expect(article.internal).to be params[:internal]
    end
  end

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
            'X-Zammad-Ticket-priority' => {
              value: '3 high',
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
              value:    'me@example.com',
            },
          },
          perform:       {
            'X-Zammad-Ticket-group_id'  => {
              value: group_first.id,
            },
            'x-Zammad-Article-Internal' => {
              value: true,
            },
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        },
        {
          name:          'x-any-recipient match value any@example.com',
          match:         {
            'x-any-recipient' => {
              operator: 'contains',
              value:    'any@example.com',
            },
          },
          perform:       {
            'X-Zammad-Ticket-group_id'  => {
              value: group_second.id,
            },
            'x-Zammad-Article-Internal' => {
              value: true,
            },
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        }
      ]
    end

    context 'with from match value me@example.com' do
      let(:data) do
        <<~MAIL
          From: me@example.com
          To: customer@example.com
          Subject: some subject

          Some Text
        MAIL
      end
      let(:group) { group_first }

      include_examples('filtered', title:    'some subject',
                                   priority: '2 normal',
                                   internal: true)
    end

    context 'with x-any-recipient-match value any@example.com' do
      let(:data) do
        <<~MAIL
          From: Some Body <somebody@example.com>
          To: Bob <bob@example.com>
          To: any@example.com
          Subject: some subject

          Some Text
        MAIL
      end
      let(:group) { group_second }

      include_examples('filtered', title:    'some subject',
                                   priority: '2 normal',
                                   internal: true)

    end

    context 'with additional not x-any-recipient-match value any_not@example.com' do
      let(:extra_filter) do
        {
          name:          'x-any-recipient not match value any_not@example.com',
          match:         {
            'x-any-recipient' => {
              operator: 'contains not',
              value:    'any_not@example.com',
            },
          },
          perform:       {
            'X-Zammad-Ticket-group_id'    => {
              value: group_second.id,
            },
            'X-Zammad-Ticket-priority_id' => {
              value: '1',
            },
            'x-Zammad-Article-Internal'   => {
              value: 'false',
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
          To: Bob <bob@example.com>
          Cc: any@example.com
          Subject: some subject2

          Some Text
        MAIL
      end
      let(:group) { group_second }

      include_examples('filtered', title:    'some subject',
                                   priority: '1 low',
                                   internal: false)
    end
  end
end
