# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::FollowUpPossibleCheck, type: :channel_filter do

  context 'new_ticket follow_up_possible for group' do

    let(:group) { create(:group, follow_up_possible: 'new_ticket') }

    context 'ticket closed' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed')) }

      it 'prevents follow up' do
        mail = {
          'x-zammad-ticket-id': ticket.id
        }

        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).not_to eq(ticket.id)
      end
    end

    context 'ticket open' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'new')) }

      it 'allows follow up' do
        mail = {
          'x-zammad-ticket-id': ticket.id
        }

        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).to eq(ticket.id)
      end
    end
  end
end
