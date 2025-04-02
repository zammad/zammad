# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Email::UpdateDestinationGroupEmail, current_user_id: 1 do
  subject(:service) { described_class.new(group:, channel:, email_address:) }

  let(:channel)       { create(:channel) }
  let(:group)         { create(:group) }
  let(:email_address) { create(:email_address) }

  describe '#execute' do
    it 'update channel email address' do
      expect { service.execute }.to change { group.reload.email_address_id }.to be(email_address.id)
    end

    context 'when email address is not given' do
      let(:email_address) { nil }
      let(:email_address2) { create(:email_address, channel: channel) }

      it 'does update group email address from channel' do
        expect { service.execute }.to change { group.reload.email_address_id }.to be(email_address2.id)
      end
    end
  end
end
