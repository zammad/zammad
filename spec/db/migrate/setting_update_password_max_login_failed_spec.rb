# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SettingUpdatePasswordMaxLoginFailed, type: :db_migration do
  context 'when having old password max login failed setting values' do
    before do
      setting.preferences = {
        permission: ['admin.security'],
      }
      setting.frontend = false
      setting.save!
    end

    let(:setting) { Setting.find_by(name: 'password_max_login_failed') }

    it 'add authentication to preferences' do
      expect { migrate }.to change { setting.reload.preferences[:authentication] }.to(true)
    end

    it 'change frontend flag to true' do
      expect { migrate }.to change { setting.reload.frontend }.to(true)
    end
  end
end
