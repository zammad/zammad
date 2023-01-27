# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile/examples/reply_article_examples'

RSpec.describe 'Mobile > Ticket > Article actions', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)     { Group.find_by(name: 'Users') }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:customer)  { create(:customer) }
  let(:ticket)    { create(:ticket, customer: customer, group: group) }

  context 'when article was created as sms' do
    let(:article) do
      create(
        :ticket_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        type:   Ticket::Article::Type.lookup(name: 'sms'),
        from:   '+41234567890'
      )
    end

    include_examples 'reply article', 'Sms', 'with default fields' do
      let(:to) { '+41234567890' }
    end

    # TODO: add custom "to" field, when frontend supports phone in "to"
  end

  context 'when article was created as a telegram message' do
    let(:article) do
      create(
        :ticket_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        type:   Ticket::Article::Type.lookup(name: 'telegram personal-message'),
      )
    end

    include_examples 'reply article', 'Telegram', attachments: true
  end

  context 'when article was created as a twitter status' do
    let(:article) do
      create(
        :twitter_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      )
    end

    include_examples 'reply article', 'Twitter', attachments: false do
      let(:current_text) { "#{article.from} " }
      let(:new_text)     { '' }
      let(:result_text)  { "#{article.from}&nbsp\n/#{agent.firstname.first}#{agent.lastname.first}" }
    end
  end

  context 'when article was created as a twitter dm' do
    include_examples 'reply article', 'Twitter', 'DM when sender is customer', attachments: false do
      let(:article) do
        create(
          :twitter_dm_article,
          ticket: ticket,
          sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        )
      end
      let(:result_text) { "#{new_text}\n/#{agent.firstname.first}#{agent.lastname.first}" }
      let(:to) { article.from }
    end

    include_examples 'reply article', 'Twitter', 'DM when sender is agent', attachments: false do
      let(:article) do
        create(
          :twitter_dm_article,
          ticket: ticket,
          sender: Ticket::Article::Sender.lookup(name: 'Agent'),
        )
      end
      let(:result_text) { "#{new_text}\n/#{agent.firstname.first}#{agent.lastname.first}" }
      let(:to) { article.to }
    end
  end

  context 'when article was created as a facebook post' do
    let(:article) do
      create(
        :ticket_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        type:   Ticket::Article::Type.lookup(name: 'facebook feed post'),
      )
    end

    include_examples 'reply article', 'Facebook', attachments: false do
      let(:type_id)     { Ticket::Article::Type.lookup(name: 'facebook feed comment').id }
      let(:in_reply_to) { nil }
    end
  end
end
