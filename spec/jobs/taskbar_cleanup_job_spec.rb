# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TaskbarCleanupJob, type: :job do
  let(:taskbar_1) { create(:taskbar, app: :desktop, last_contact: 2.days.ago) }
  let(:taskbar_2) { create(:taskbar, app: :mobile, last_contact: 2.days.ago) }
  let(:taskbar_3) { create(:taskbar, app: :mobile, last_contact: 1.hour.ago) }

  before do
    taskbar_1.update_columns last_contact: 1.day.ago
    taskbar_2.update_columns last_contact: 1.day.ago
    taskbar_3.update_columns last_contact: 1.hour.ago
  end

  it 'removes old mobile taskbar only' do
    expect { described_class.perform_now }
      .to change { Taskbar.all.reload }
      .to eq([taskbar_1, taskbar_3])
  end
end
