# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SessionHelper do
  describe 'Core Workflow: Does show wrong field list if you only have admin permissions and not ticket.agent permissions #4035' do
    context 'when user has admin.core_workflow permissions' do
      let(:core_workflow_role) { create(:role, :admin_core_workflow) }
      let(:user)               { create(:user, role_ids: [core_workflow_role.id]) }

      it 'does provide assets for application selector ui element' do
        expect(described_class.json_hash(user)[:collections][ObjectManager::Attribute.to_app_model]).to be_truthy
      end
    end

    context 'when user has ticket.agent permissions' do
      let(:user) { create(:agent) }

      it 'does provide assets for application selector ui element' do
        expect(described_class.json_hash(user)[:collections][ObjectManager::Attribute.to_app_model]).to be_falsey
      end
    end

    context 'when user has customer permissions' do
      let(:user) { create(:customer) }

      it 'does provide assets for application selector ui element' do
        expect(described_class.json_hash(user)[:collections][ObjectManager::Attribute.to_app_model]).to be_falsey
      end
    end
  end
end
