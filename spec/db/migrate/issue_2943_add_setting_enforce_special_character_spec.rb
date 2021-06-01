# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2943AddSettingEnforceSpecialCharacter, type: :db_migration do
  before do
    Setting.find_by(name: :password_need_special_character).destroy
  end

  it 'adds password_need_special_character setting' do
    expect { migrate }.to change { Setting.exists?(name: :password_need_special_character) }.from(false).to(true)
  end

  it 'performs no action for new systems', system_init_done: false do
    expect { migrate }.not_to change { Setting.exists?(name: :password_need_special_character) }.from(false)
  end
end
