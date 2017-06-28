require 'rails_helper'

RSpec.describe Ticket do

  describe '.merge_to' do

    it 'prevents cross merging tickets' do
      source_ticket     = create(:ticket)
      target_ticket     = create(:ticket)

      result = source_ticket.merge_to(
        ticket_id: target_ticket.id,
        user_id:   1,
      )
      expect(result).to be(true)

      expect {
        result = target_ticket.merge_to(
          ticket_id: source_ticket.id,
          user_id:   1,
        )
      }.to raise_error('ticket already merged, no merge into merged ticket possible')
    end

    it 'prevents merging ticket in it self' do
      source_ticket = create(:ticket)

      expect {
        result = source_ticket.merge_to(
          ticket_id: source_ticket.id,
          user_id:   1,
        )
      }.to raise_error('Can\'t merge ticket with it self!')
    end

  end

  context 'callbacks' do

    describe '#reset_pending_time' do

      it 'resets the pending time on state change' do
        ticket = create(:ticket,
                        state:        Ticket::State.lookup(name: 'pending reminder'),
                        pending_time: Time.zone.now + 2.days)
        expect(ticket.pending_time).not_to be nil

        ticket.update_attribute(:state, Ticket::State.lookup(name: 'open'))
        expect(ticket.pending_time).to be nil
      end

      it 'lets handle ActiveRecord nil as new value' do
        ticket = create(:ticket)
        expect do
          ticket.update_attribute(:state, nil)
        end.to raise_error(ActiveRecord::StatementInvalid)
      end

    end
  end
end
