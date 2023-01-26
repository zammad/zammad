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

    include_examples 'reply article', type_label: 'Sms', internal: false, attachments: false
  end
end
