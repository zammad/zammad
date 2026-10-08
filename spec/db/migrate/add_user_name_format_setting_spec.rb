# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddUserNameFormatSetting, type: :db_migration do
  before do
    Setting.find_by(name: 'user_name_format').destroy!
  end

  it 'creates the setting' do
    expect { migrate }.to change { Setting.exists?(name: 'user_name_format') }.from(false).to(true)
  end

  it 'defaults to first_last and is exposed to the frontend' do
    migrate

    expect(Setting.find_by(name: 'user_name_format')).to have_attributes(
      state_current: { 'value' => 'first_last' },
      frontend:      true,
    )
  end

  it 'performs no action for new systems', system_init_done: false do
    expect { migrate }.not_to change { Setting.exists?(name: 'user_name_format') }.from(false)
  end
end
