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
      ticket = service.execute(ticket_data:)

      expect(ticket)
        .to have_attributes(
          title:    sample_title,
          group:    group,
          customer: customer
        )
    end

    it 'creates a ticket with customer email address' do
      test_email = Faker::Internet.unique.email
      ticket_data[:customer] = test_email

      ticket = service.execute(ticket_data:)

      expect(ticket.customer).to have_attributes(
        email:    test_email,
        role_ids: Role.signup_role_ids
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

      ticket = service.execute(ticket_data:)

      expect(ticket.articles.first)
        .to have_attributes(
          body: sample_body
        )
    end

    it 'adds tags when present' do
      sample_tags = [Faker::Lorem.word]

      ticket_data[:tags] = sample_tags

      ticket = service.execute(ticket_data:)

      expect(ticket.tag_list)
        .to eq sample_tags
    end

    context 'when adding links' do
      let!(:other_ticket) { create(:ticket, customer: customer) }
      let(:links) do
        [
          { link_object: other_ticket, link_type: 'child' },
          { link_object: other_ticket, link_type: 'normal' },
        ]
      end

      it 'adds links correctly' do
        ticket_data[:links] = links
        ticket = service.execute(ticket_data:)
        expect(Link.list(link_object: 'Ticket', link_object_value: ticket.id)).to contain_exactly(
          { 'link_object' => 'Ticket', 'link_object_value' => other_ticket.id, 'link_type' => 'parent' },
          { 'link_object' => 'Ticket', 'link_object_value' => other_ticket.id, 'link_type' => 'normal' },
        )
      end
    end

    context 'when tag creation is disabled' do
      before do
        Setting.set('tag_new', false)
      end

      it 'does not adds tags when present' do
        sample_tags = [Faker::Lorem.word]

        ticket_data[:tags] = sample_tags

        ticket = service.execute(ticket_data:)

        expect(ticket.tag_list).to be_empty
      end
    end

    describe 'shared draft handling' do
      let(:shared_draft) { create(:ticket_shared_draft_start, group:) }

      before { ticket_data[:shared_draft] = shared_draft }

      it 'destroys given shared draft' do
        service.execute(ticket_data:)

        expect(Ticket::SharedDraftStart).not_to exist(shared_draft.id)
      end

      it 'raises error if shared drafts are disabled on that group' do
        group.update! shared_drafts: false

        expect { service.execute(ticket_data:) }
          .to raise_error(Exceptions::UnprocessableEntity)
      end

      it 'raises error if shared draft group does not match ticket group' do
        shared_draft.update! group: create(:group)

        group.update! shared_drafts: false

        expect { service.execute(ticket_data:) }
          .to raise_error(Exceptions::UnprocessableEntity)
      end
    end
  end
end
