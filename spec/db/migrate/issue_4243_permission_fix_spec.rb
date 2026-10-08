# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4243PermissionFix, type: :db_migration do
  let!(:test_role) do
    role = create(:role)
    role.group_names_access_map = {
      Group.first.name => 'full',
    }
    role
  end
  let!(:agent_role) do
    role = create(:role, :agent)
    role.group_names_access_map = {
      Group.first.name => 'full',
    }
    role
  end

  it 'does remove the groups if the role does not have the ticket.agent permissions' do
    expect { migrate }.to change { test_role.reload.groups.to_a }.from([Group.first]).to([])
  end

  it 'does nothing if the role does have the ticket.agent permissions' do
    expect { migrate }.not_to change { agent_role.reload.groups.to_a }.from([Group.first])
  end
end
