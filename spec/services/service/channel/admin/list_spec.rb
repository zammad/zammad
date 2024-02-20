# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Channel::Admin::List, current_user_id: 1 do
  subject(:service) { described_class.new(area: channel.area) }

  let!(:channel) { create(:channel) }

  describe '#execute' do
    it 'destroys the channel' do
      expect(service.execute).to eq([channel])
    end
  end
end
