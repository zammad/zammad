# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with simple filter and followup message', aggregate_failures: true, type: :model do
  before do
    PostmasterFilter.destroy_all
    PostmasterFilter.create!(filter)
  end

  let(:group_default) { Group.lookup(name: 'Users') }
  let(:group_first)   { create(:group, name: 'First group') }
  let(:group_second)  { create(:group, name: 'Second group') }
  let(:email)         { Channel::EmailParser.new.process({ group_id: group_default.id, trusted: false }, data) }
  let(:ticket)        { email[0] }
  let(:article)       { email[1] }

  let(:filter) do
    {
      name:          'RSpec: Channel::EmailParser#process',
      match:         {
        from: {
          operator: 'contains',
          value:    'example.com',
        },
      },
      perform:       {
        'X-Zammad-Ticket-group_id' => {
          value: group_second.id,
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
      Subject: follow-up with create post master filter test

      Some Text
    MAIL
  end
  let(:modified_ticket) do
    ticket.group = group_first
    ticket.save
    TransactionDispatcher.commit
    ticket
  end
  let(:followup_data) do
    <<~MAIL
      From: me@example.com
      To: customer@example.com
      Subject: #{modified_ticket.subject_build('some new subject')}

      Some Text
    MAIL
  end
  let(:followup_email) do
    Channel::EmailParser.new.process({ group_id: group_default.id, trusted: false }, followup_data)
  end
  let(:followup_ticket)  { followup_email[0] }
  let(:followup_article) { followup_email[1] }

  it 'modifies followup ticket' do
    expect(followup_ticket.id).to eql(ticket.id)
    expect(followup_ticket.group.name).to match(group_first.name)
    expect(followup_ticket.priority.name).to match('2 normal')
    expect(followup_ticket.title).to match('follow-up with create post master filter test')
  end

  it 'modifies followup article' do
    expect(followup_ticket.articles.count).to eq(ticket.articles.count)
    expect(article.sender.name).to match('Customer')
    expect(article.type.name).to match('email')
    expect(article.internal).to be false
  end

  describe 'Log Trigger and Scheduler in Ticket History #4604' do
    it 'add history entries for the postmaster filter manipulation' do
      followup_ticket
      expect(History.find(followup_ticket.history_get.first['id'])).to have_attributes(
        o_id:       ticket.id,
        sourceable: PostmasterFilter.first,
        value_from: '',
        value_to:   group_second.name,
        id_from:    nil,
        id_to:      group_second.id,
      )
    end

    it 'does not have a sourceable for the ticket creation entry' do
      followup_ticket
      expect(History.find(followup_ticket.history_get.detect { |h| h['type'] == 'created' }['id']).sourceable).to be_nil
    end

    context 'when filter does add tags' do
      let(:tag) { SecureRandom.uuid }
      let(:filter) do
        {
          name:          'RSpec: Channel::EmailParser#process',
          match:         {
            from: {
              operator: 'contains',
              value:    'example.com',
            },
          },
          perform:       {
            'x-zammad-ticket-tags' => { 'operator' => 'add', 'value' => tag }
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        }
      end

      it 'does work for tags' do
        followup_ticket
        history_id = followup_ticket.history_get.detect { |h| h['sourceable_type'] == 'PostmasterFilter' }['id']
        expect(History.find(history_id)).to have_attributes(
          history_type_id: History::Type.find_by(name: 'added').id,
          o_id:            ticket.id,
          sourceable:      PostmasterFilter.first,
          value_from:      nil,
          value_to:        tag,
          id_from:         nil,
          id_to:           nil,
        )
      end
    end

    context 'when filter contains followup headers' do
      let(:filter) do
        {
          name:          'RSpec: Channel::EmailParser#process',
          match:         {
            from: {
              operator: 'contains',
              value:    'example.com',
            },
          },
          perform:       {
            'x-zammad-ticket-followup-group_id' => {
              value: group_second.id,
            },
          },
          channel:       'email',
          active:        true,
          created_by_id: 1,
          updated_by_id: 1,
        }
      end

      it 'does work for the followup headers' do
        followup_ticket
        history_id = followup_ticket.history_get.detect { |h| h['sourceable_type'] == 'PostmasterFilter' }['id']
        expect(History.find(history_id)).to have_attributes(
          o_id:       ticket.id,
          sourceable: PostmasterFilter.first,
          value_from: group_first.name,
          value_to:   group_second.name,
          id_from:    group_first.id,
          id_to:      group_second.id,
        )
      end
    end
  end
end
