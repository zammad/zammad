# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Admin::Enable, current_user_id: 1 do
  subject(:service_result) { described_class.execute(area: channel.area, channel_id: channel.id) }

  let!(:channel) { create(:channel, active: false) }

  describe '#execute' do
    it 'destroys the channel' do
      expect { service_result }.to change { channel.reload.active }.to be(true)
    end
  end
end
