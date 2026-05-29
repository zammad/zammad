# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddIntegrationPermissions, type: :db_migration do
  let(:integration_permissions) { %w[integration.idoit integration.github integration.gitlab] }
  let!(:role)                   { create(:role, permission_names: %w[ticket.agent]) }

  it 'creates the integration permissions' do
    migrate
    expect(Permission.where(name: ['integration', *integration_permissions]).count).to eq(4)
  end

  it 'grants the integration permissions to roles holding ticket.agent (preserving existing access)' do
    expect { migrate }
      .to change { role.reload.permissions.where(name: integration_permissions).count }
      .from(0).to(integration_permissions.size)
  end

  it 'does not grant the integration permissions to roles without ticket.agent' do
    customer_role = create(:role, permission_names: %w[ticket.customer])

    expect { migrate }
      .not_to change { customer_role.reload.permissions.where(name: integration_permissions).count }
  end
end
