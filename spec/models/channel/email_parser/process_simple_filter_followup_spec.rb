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
end
