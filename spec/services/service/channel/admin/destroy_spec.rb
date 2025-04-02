# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Admin::Destroy, :aggregate_failures, current_user_id: 1 do
  subject(:service) { described_class.new(area: channel.area, channel_id: channel.id) }

  let!(:channel) { create(:channel) }

  describe '#execute' do
    it 'destroys the channel' do
      expect { service.execute }.to change(Channel, :count).by(-1)
      expect { channel.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
