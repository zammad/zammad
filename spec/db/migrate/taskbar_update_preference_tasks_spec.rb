# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TaskbarUpdatePreferenceTasks, type: :db_migration do
  let(:ticket)  { create(:ticket) }
  let(:user)    { create(:agent, groups: [ticket.group]) }
  let(:taskbar) { create(:taskbar, :with_ticket, ticket:, user:) }

  it 'updates taskbar tasks' do
    freeze_time

    expect { migrate }
      .to change { taskbar.reload.preferences }
      .to({
            tasks: [
              { user_id: user.id, id: taskbar.id, apps: { desktop: { last_contact: taskbar.last_contact, changed: false } } }
            ]
          })
  end
end
