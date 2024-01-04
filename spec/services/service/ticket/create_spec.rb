# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Create, current_user_id: -> { user.id } do
  subject(:service) { described_class.new(current_user: user) }

  let(:user)     { create(:agent, groups: [group]) }
  let(:group)    { create(:group) }
  let(:customer) { create(:customer) }

  describe '#execute' do
    let(:sample_title) { Faker::Lorem.sentence }

    let(:ticket_data) do
      {
        title:    sample_title,
        group:    group,
        customer: customer
      }
    end

    it 'creates a ticket with given metadata' do
      service.execute(ticket_data:)

      expect(Ticket.last)
        .to have_attributes(
          title:    sample_title,
          group:    group,
          customer: customer
        )
    end

    it 'fails to create ticket without access' do
      allow_any_instance_of(TicketPolicy)
        .to receive(:create?).and_return(false)

      expect { service.execute(ticket_data:) }
        .to raise_error(Pundit::NotAuthorizedError)
    end

    it 'adds article when present' do
      sample_body = Faker::Lorem.sentence
      ticket_data[:article] = {
        body: sample_body
      }

      service.execute(ticket_data:)

      expect(Ticket.last.articles.first)
        .to have_attributes(
          body: sample_body
        )
    end

    it 'adds tags when present' do
      sample_tags = [Faker::Lorem.word]

      ticket_data[:tags] = sample_tags

      service.execute(ticket_data:)

      expect(Ticket.last.tag_list)
        .to eq sample_tags
    end

    context 'when tag creation is disabled' do
      before do
        Setting.set('tag_new', false)
      end

      it 'does not adds tags when present' do
        sample_tags = [Faker::Lorem.word]

        ticket_data[:tags] = sample_tags

        service.execute(ticket_data:)

        expect(Ticket.last.tag_list).to eq([])
      end
    end
  end
end
