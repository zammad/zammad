# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3194UpdatePermissions, type: :db_migration do
  let(:permissions) { %w[admin.channel_google admin.channel_microsoft365] }

  before do
    setting = Setting.find_by(name: 'ticket_subject_size')
    setting.preferences[:permission] -= permissions
    setting.save!
  end

  it 'does update settings with new permissions' do
    expect { migrate }
      .to change { Setting.find_by(name: 'ticket_subject_size').preferences[:permission] }
      .from(not_include(*permissions))
      .to(include(*permissions))
  end
end
