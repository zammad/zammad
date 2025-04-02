# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Update, current_user_id: -> { user.id } do
  subject(:service) { described_class.new(current_user: user) }

  let(:user)        { create(:agent, groups: [group]) }
  let(:ticket)      { create(:ticket) }
  let(:group)       { ticket.group }
  let(:new_title)   { Faker::Lorem.word }
  let(:new_body)    { Faker::Lorem.sentence }
  let(:ticket_data) { { title: new_title, time_unit: 2 } }

  let(:ticket_data_with_article) do
    ticket_data.merge(article: { body: new_body })
  end

  describe '#execute' do
    it 'updates a ticket with given metadata' do
      service.execute(ticket: ticket, ticket_data:)

      expect(ticket)
        .to have_attributes(
          title: new_title,
        )
    end

    it 'fails to update ticket without access' do
      allow_any_instance_of(TicketPolicy)
        .to receive(:update?).and_return(false)

      expect { service.execute(ticket: ticket, ticket_data:) }
        .to raise_error(Pundit::NotAuthorizedError)
    end

    it 'adds article when present' do
      service.execute(ticket: ticket, ticket_data: ticket_data_with_article)

      expect(Ticket.last.articles.last)
        .to have_attributes(
          body: new_body,
        )
    end

    it 'adds article accounted time to ticket' do
      expect(service.execute(ticket: ticket, ticket_data: ticket_data_with_article).time_unit).to eq(2)
    end

    it 'updates ticket with given macro' do
      macro = create(:macro, perform: { 'ticket.title' => { 'value' => new_title } })

      service.execute(ticket: ticket, ticket_data:, macro:)

      expect(ticket)
        .to have_attributes(
          title: new_title,
        )
    end

    it 'adds article note via macro' do
      macro = create(:macro, perform: {
                       'article.note' => { 'body' => 'note body', 'internal' => 'true', 'subject' => 'test' }
                     })

      service.execute(ticket: ticket, ticket_data: ticket_data_with_article, macro:)

      expect(ticket.articles.reload)
        .to contain_exactly(
          have_attributes(body: new_body),
          have_attributes(body: 'note body'),
        )
    end
  end
end
