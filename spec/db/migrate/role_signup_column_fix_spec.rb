# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RoleSignupColumnFix, type: :db_migration, db_strategy: :reset do
  context 'when a role contains signup permissions' do
    let!(:role) do
      role = create(:role)
      role.permission_grant('user_preferences.password')
      role.permission_grant('ticket.agent')
      role.update_column(:default_at_signup, true)
      role
    end

    before do
      without_column(:permissions, column: :allow_signup)
      migrate
    end

    it 'has password permission' do
      expect(role.reload.permissions.map(&:name)).to include('user_preferences.password')
    end

    it 'has no agent permission' do
      expect(role.reload.permissions.map(&:name)).not_to include('ticket.agent')
    end

    it 'has permission with allow_signup set correctly' do
      expect(Permission.find_by(name: 'user_preferences.password').allow_signup).to be true
    end
  end
end
