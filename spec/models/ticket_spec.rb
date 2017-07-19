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
      }.to raise_error('invalid state for target ticket')
    end

  end

end
