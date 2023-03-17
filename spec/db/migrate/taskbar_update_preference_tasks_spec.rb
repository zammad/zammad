# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TaskbarUpdatePreferenceTasks, type: :db_migration do
  let(:taskbar) { create(:taskbar) }

  it 'updates taskbar tasks' do
    freeze_time

    expect { migrate }
      .to change { taskbar.reload.preferences }
      .to({
            tasks: [
              { user_id: 1, id: taskbar.id, apps: { desktop: { last_contact: taskbar.last_contact, changed: false } } }
            ]
          })
  end
end
