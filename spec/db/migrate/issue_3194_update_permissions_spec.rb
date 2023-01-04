# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3194UpdatePermissions, type: :db_migration do
  it 'does update settings with new permissions' do
    expect { migrate }.to change { Setting.find_by(name: 'ticket_subject_size').preferences[:permission] }.to include('admin.channel_google', 'admin.channel_microsoft365')
  end
end
