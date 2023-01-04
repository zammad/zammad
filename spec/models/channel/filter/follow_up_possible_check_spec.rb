# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::FollowUpPossibleCheck, type: :channel_filter do
  let(:mail) { { 'x-zammad-ticket-id': ticket.id } }

  context 'new_ticket follow_up_possible for group' do

    let(:group) { create(:group, follow_up_possible: 'new_ticket') }

    context 'ticket closed' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed')) }

      it 'prevents follow up' do
        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).not_to eq(ticket.id)
      end
    end

    context 'ticket open' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'new')) }

      it 'allows follow up' do
        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).to eq(ticket.id)
      end
    end
  end

  context 'new_ticket_after_certain_time follow_up_possible for group' do
    let(:group) { create(:group, follow_up_possible: 'new_ticket_after_certain_time', reopen_time_in_days: 2) }

    context 'ticket closed that is able to get reopened' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed')) }

      it 'allow follow up' do
        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).to eq(ticket.id)
      end
    end

    context 'ticket closed that is not able to get reopened' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed')) }

      it 'prevents follow up' do
        mail

        travel_to 5.days.from_now

        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).not_to eq(ticket.id)
      end
    end

    context 'ticket closed two times that is able to get reopened' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed')) }

      let(:reopen_and_close_ticket) do
        travel_to 5.days.from_now
        ticket.state = Ticket::State.find_by(name: 'open')
        ticket.save!

        travel_to 1.day.from_now
        ticket.state = Ticket::State.find_by(name: 'closed')
        ticket.save!
      end

      it 'allow follow up' do
        mail

        reopen_and_close_ticket

        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).to eq(ticket.id)
      end
    end

    context 'ticket open' do
      let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'new')) }

      it 'allows follow up' do
        filter(mail)

        expect(mail[:'x-zammad-ticket-id']).to eq(ticket.id)
      end
    end
  end

end
