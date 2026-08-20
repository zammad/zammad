# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Assets do
  describe '#authorized_asset?' do
    subject(:ticket) { create(:ticket) }

    let(:customer) { create(:customer) }

    # Without this a lost user context put any ticket into an asset payload, no matter what
    # TicketPolicy says about it.
    context 'without a user context' do
      before { UserInfo.reset }

      it { is_expected.not_to be_authorized_asset }

      it 'is authorized in a system context' do
        UserInfo.with_system_context do
          expect(ticket).to be_authorized_asset
        end
      end
    end

    context 'with a user who may not see the ticket' do
      before { UserInfo.current_user_id = customer.id }

      it { is_expected.not_to be_authorized_asset }
    end

    context 'with a user who may see the ticket' do
      before { UserInfo.current_user_id = ticket.customer_id }

      it { is_expected.to be_authorized_asset }
    end
  end
end
