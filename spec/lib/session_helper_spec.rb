# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

  describe 'taskbars' do
    let(:user)      { create(:user) }
    let(:taskbar_1) { create(:taskbar, user: user) }
    let(:taskbar_2) { create(:taskbar, user: user, app: 'mobile') }

    before { taskbar_1 && taskbar_2 }

    it 'returns desktop taskbars' do
      collections = described_class.json_hash(user)[:collections]
      expect(collections[Taskbar.to_app_model]).to eq([taskbar_1])
    end
  end

  describe 'New collections by installed packages are crashing zammad#4748' do
    it 'does add a collection as a file' do
      allow(Rails).to receive(:env).and_return('production')
      Rails.root.join('lib/session_helper/collection_xxx.rb').write('module SessionHelper::CollectionXXX; end;')

      expect { described_class.default_collections(User.find(1)) }.not_to raise_error(NameError, 'uninitialized constant SessionHelper::CollectionXxx')
    ensure
      Rails.root.join('lib/session_helper/collection_xxx.rb').delete
    end
  end
end
