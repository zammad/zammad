# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe OnlineNotification, type: :model do
  subject(:online_notification) { create(:online_notification, o: ticket) }

  let(:ticket) { create(:ticket) }

  it_behaves_like 'ApplicationModel'

  describe '#related_object' do
    it 'returns ticket' do
      expect(online_notification.related_object).to eq ticket
    end
  end
end
