# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OnlineNotificationStandalone, type: :model do
  subject(:standalone_notification) { create(:online_notification_standalone) }

  it { is_expected.to validate_inclusion_of(:kind).in_array(%w[bulk_job kb_answer_generation_failed]) }

  it 'creates a record via factory' do
    expect(standalone_notification).to be_persisted
  end
end
