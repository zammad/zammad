# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Later migration changes structure of Permission model
# This adds a field that is now missing to check if old migration still works for upgrades from older systems
Permission.attr_accessor :note

RSpec.describe Add2faPermission, type: :db_migration do
  let(:role) { create(:role, permission_names:) }

  before do
    Permission.find(fa_permission_id).destroy!
    role
  end

  context 'when role has no user preferences permissions' do
    let(:permission_names) { %w[report] }

    it 'does not add two_factor_authentication permission' do
      expect { migrate }
        .not_to change { role.reload.permission_ids.include? fa_permission_id }
    end
  end

  context 'when role has whole user_preferences permission' do
    let(:permission_names) { %w[user_preferences] }

    it 'does not add two_factor_authentication permission' do
      expect { migrate }
        .not_to change { role.reload.permission_ids.include? fa_permission_id }
    end
  end

  context 'when role has specifically user_preferences.password' do
    let(:permission_names) { %w[user_preferences.password] }

    it 'adds two_factor_authentication permission' do
      expect { migrate }
        .to change { role.reload.permission_ids.include? fa_permission_id }
        .to be_truthy
    end
  end

  context 'when role has other user_preferences.something permission' do
    let(:permission_names) { %w[user_preferences.calendar] }

    it 'does not add two_factor_authentication permission' do
      expect { migrate }
        .not_to change { role.reload.permission_ids.include? fa_permission_id }
    end
  end

  # This cannot be a let block since permission does not exist before migration
  # Later migration changes structure of Permission model so it's safer to use ID only
  def fa_permission_id
    Permission
      .where(name: 'user_preferences.two_factor_authentication')
      .pick(:id)
  end
end
