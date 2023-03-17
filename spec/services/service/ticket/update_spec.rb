# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Update, current_user_id: -> { user.id } do
  subject(:service) { described_class.new(current_user: user) }

  let(:user)        { create(:agent, groups: [group]) }
  let(:ticket)      { create(:ticket) }
  let(:group)       { ticket.group }
  let(:new_title)   { Faker::Lorem.word }
  let(:ticket_data) { { title: new_title } }

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
      sample_body = Faker::Lorem.sentence
      ticket_data[:article] = {
        body: sample_body
      }

      service.execute(ticket: ticket, ticket_data:)

      expect(Ticket.last.articles.last)
        .to have_attributes(
          body: sample_body
        )
    end
  end
end
