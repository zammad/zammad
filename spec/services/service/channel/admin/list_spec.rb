# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Admin::List, current_user_id: 1 do
  subject(:service_result) { described_class.execute(area: channel.area) }

  let!(:channel) { create(:channel) }

  describe '#execute' do
    it 'destroys the channel' do
      expect(service_result).to eq([channel])
    end
  end
end
