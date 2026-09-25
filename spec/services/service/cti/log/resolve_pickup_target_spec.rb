# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Cti::Log::ResolvePickupTarget do
  subject(:target) { described_class.execute(log:) }

  let(:customer) { create(:customer, :with_phone) }
  let(:log)      { create(:cti_log, :inbound, :connected, :with_from_users, from_users: [customer]) }

  context 'when the customer has a ticket updated within the window' do
    before { create(:ticket, customer:) }

    it 'targets the detail view of the customer' do
      expect(target).to eq(view: :user_detail, customer: customer, log: log)
    end
  end

  context 'when the last ticket of the customer is older than the window' do
    before { travel_to(31.days.ago) { create(:ticket, customer:) } }

    it 'targets the ticket create screen for the customer' do
      expect(target).to eq(view: :ticket_create, customer: customer, log: log)
    end
  end

  context 'when the customer has no ticket' do
    it 'targets the ticket create screen for the customer' do
      expect(target).to eq(view: :ticket_create, customer: customer, log: log)
    end
  end

  context 'when no customer was detected' do
    let(:log) { create(:cti_log, :inbound, :connected) }

    it 'targets the ticket create screen with the call only' do
      expect(target).to eq(view: :ticket_create, customer: nil, log: log)
    end
  end

  # The window is the admin setting, not a fixed 30 days.
  context 'when the window is shortened to a week' do
    before do
      Setting.set('cti_customer_last_activity', 7.days)
      travel_to(10.days.ago) { create(:ticket, customer:) }
    end

    it 'no longer counts a ticket from ten days ago' do
      expect(target).to include(view: :ticket_create)
    end
  end

  context 'when the window is extended to two months' do
    before do
      Setting.set('cti_customer_last_activity', 60.days)
      travel_to(45.days.ago) { create(:ticket, customer:) }
    end

    it 'counts a ticket from six weeks ago' do
      expect(target).to include(view: :user_detail)
    end
  end
end
