# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5083ChatPermission, type: :db_migration do
  let(:role_with_chat_permission)    { create(:role) }
  let(:role_without_chat_permission) { create(:role) }

  before do

    # undisable chat permission
    Permission.create_or_update(
      name:        'chat',
      note:        __('Access to %s'),
      preferences: {
        translations: [__('Chat')],
      },
    )

    role_with_chat_permission.permissions << Permission.find_by(name: 'chat')
    role_without_chat_permission

    # reset original state
    Permission.create_or_update(
      name:        'chat',
      note:        __('Access to %s'),
      preferences: {
        translations: [__('Chat')],
        disabled:     true,
      },
    )

    migrate
  end

  it 'does migrate role with chat permission', :aggregate_failures do
    expect(role_with_chat_permission.reload.permissions).not_to include(Permission.find_by(name: 'chat'))
    expect(role_with_chat_permission.reload.permissions).to include(Permission.find_by(name: 'chat.agent'))
  end

  it 'does not touch role without chat permission', :aggregate_failures do
    expect(role_without_chat_permission.reload.permissions).not_to include(Permission.find_by(name: 'chat'))
    expect(role_without_chat_permission.reload.permissions).not_to include(Permission.find_by(name: 'chat.agent'))
  end
end
