# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4243PermissionFix, type: :db_migration do
  let!(:test_role) do
    role = create(:role)
    role.group_names_access_map = {
      Group.first.name => 'full',
    }
    role
  end

  before do
    migrate
  end

  it 'does add the permission if groups are present but ticket.agent permission is not set' do
    expect(test_role.reload.permissions).to include(Permission.find_by(name: 'ticket.agent'))
  end
end
