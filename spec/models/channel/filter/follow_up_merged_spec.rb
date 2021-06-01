# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::FollowUpMerged, type: :channel_filter do

  context 'merged' do

    it 'handles ticket merged to one ticket' do
      ticket1 = create(:ticket)
      ticket2 = create(:ticket)

      ticket1.merge_to( ticket_id: ticket2.id, user_id: 1 )

      mail = {
        'x-zammad-ticket-id': ticket1.id
      }

      filter(mail)

      expect(mail[:'x-zammad-ticket-id']).to eq(ticket2.id)
    end

    it 'handles first merged chain' do
      ticket1 = create(:ticket)
      ticket2 = create(:ticket)
      ticket3 = create(:ticket)

      ticket1.merge_to( ticket_id: ticket2.id, user_id: 1 )
      ticket2.merge_to( ticket_id: ticket3.id, user_id: 1 )

      mail = {
        'x-zammad-ticket-id': ticket1.id
      }

      filter(mail)

      expect(mail[:'x-zammad-ticket-id']).to eq(ticket3.id)
    end

    it 'handles ticket in merged ticket chain' do
      ticket1 = create(:ticket)
      ticket2 = create(:ticket)
      ticket3 = create(:ticket)
      ticket4 = create(:ticket)

      ticket1.merge_to( ticket_id: ticket2.id, user_id: 1 )
      ticket2.merge_to( ticket_id: ticket3.id, user_id: 1 )
      ticket3.merge_to( ticket_id: ticket4.id, user_id: 1 )

      mail = {
        'x-zammad-ticket-id': ticket2.id
      }

      filter(mail)

      expect(mail[:'x-zammad-ticket-id']).to eq(ticket4.id)
    end
  end

  context 'ignored mails' do

    it 'ignores new tickets' do
      mail = {}

      expect do
        filter(mail)
      end.to not_change {
        mail
      }
    end

    it 'ignores unmerged tickets' do
      ticket = create(:ticket)

      mail = {
        'x-zammad-ticket-id': ticket.id
      }

      expect do
        filter(mail)
      end.to not_change {
        mail
      }
    end

    it 'ignores not existing tickets' do
      mail = {
        'x-zammad-ticket-id': 1_234_567_890
      }

      expect do
        filter(mail)
      end.to not_change {
        mail
      }
    end
  end
end
