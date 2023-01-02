# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with auto-submitted filter', aggregate_failures: true, type: :model do

  before do
    PostmasterFilter.destroy_all
    PostmasterFilter.create!(filter)
  end

  let(:group_default) { Group.lookup(name: 'Users') }
  let(:email)         { Channel::EmailParser.new.process({ group_id: group_default.id, trusted: false }, data) }
  let(:ticket)        { email[0] }
  let(:article)       { email[1] }

  shared_examples 'modifies ticket' do
    it 'modifies ticket' do
      expect(ticket.group.name).to match(group_default.name)
      expect(ticket.priority.name).to match('2 normal')
      expect(ticket.title).to match('some subject')
      expect(ticket.customer.email).to match('me@example.com')
    end
  end

  shared_examples 'article is note' do
    it 'modifies article note' do
      expect(article.sender.name).to match('Customer')
      expect(article.type.name).to match('note')
      expect(article.internal).to be true
    end
  end

  shared_examples 'article is email' do
    it 'modifies article email' do
      expect(article.sender.name).to match('Customer')
      expect(article.type.name).to match('email')
      expect(article.internal).to be false
    end
  end

  context 'when from match value: @example.com and auto-submitted contains not: auto-generated' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          'auto-submitted' => {
            'operator' => 'contains not',
            'value'    => 'auto-generated',
          },
          'from'           => {
            'operator' => 'contains',
            'value'    => '@example.com',
          }
        },
        perform:       {
          'x-zammad-article-internal' => {
            'value' => 'true',
          },
          'x-zammad-article-type_id'  => {
            'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
          },
          'x-zammad-ignore'           => {
            'value' => 'false',
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

    include_examples 'modifies ticket'
    include_examples 'article is note'
  end

  context 'when from match value: @example.com and auto-submitted contains: auto-generated' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          'auto-submitted' => {
            'operator' => 'contains',
            'value'    => 'auto-generated',
          },
          'from'           => {
            'operator' => 'contains',
            'value'    => '@example.com',
          }
        },
        perform:       {
          'x-zammad-article-internal' => {
            'value' => 'true',
          },
          'x-zammad-article-type_id'  => {
            'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
          },
          'x-zammad-ignore'           => {
            'value' => 'false',
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

    include_examples 'modifies ticket'
    include_examples 'article is email'
  end

  context 'when to match value: customer@example.com and auto-submitted contains not: auto-generated' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          'auto-submitted' => {
            'operator' => 'contains not',
            'value'    => 'auto-generated',
          },
          'to'             => {
            'operator' => 'contains',
            'value'    => 'customer@example.com',
          },
          'from'           => {
            'operator' => 'contains',
            'value'    => '@example.com',
          }
        },
        perform:       {
          'x-zammad-article-internal' => {
            'value' => 'true',
          },
          'x-zammad-article-type_id'  => {
            'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
          },
          'x-zammad-ignore'           => {
            'value' => 'false',
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

    include_examples 'modifies ticket'
    include_examples 'article is note'
  end

  context 'when from match value: @example.com, to match value: customer1@example.com and auto-submitted contains: auto-generated' do
    let(:filter) do
      {
        name:          'RSpec: Channel::EmailParser#process',
        match:         {
          'auto-submitted' => {
            'operator' => 'contains',
            'value'    => 'auto-generated',
          },
          'to'             => {
            'operator' => 'contains',
            'value'    => 'customer1@example.com',
          },
          'from'           => {
            'operator' => 'contains',
            'value'    => '@example.com',
          }
        },
        perform:       {
          'x-zammad-article-internal' => {
            'value' => 'true',
          },
          'x-zammad-article-type_id'  => {
            'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
          },
          'x-zammad-ignore'           => {
            'value' => 'false',
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

    include_examples 'modifies ticket'
    include_examples 'article is email'
  end

end
