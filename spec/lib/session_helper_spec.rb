# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  describe 'ticket collections' do
    let(:group)         { create(:group) }
    let(:foreign_group) { create(:group) }
    let(:user)          { create(:agent, groups: [group]) }

    let(:macro)                  { create(:macro, groups: [group]) }
    let(:foreign_macro)          { create(:macro, groups: [foreign_group]) }
    let(:inactive_macro)         { create(:macro, groups: [group], active: false) }
    let(:text_tool)              { create(:ai_text_tool, groups: [group]) }
    let(:foreign_text_tool)      { create(:ai_text_tool, groups: [foreign_group]) }
    let(:inactive_text_tool)     { create(:ai_text_tool, groups: [group], active: false) }
    let(:template)               { create(:template) }
    let(:inactive_template)      { create(:template, active: false) }
    let(:shared_draft)           { create(:ticket_shared_draft_start, group: group) }
    let(:foreign_shared_draft)   { create(:ticket_shared_draft_start, group: foreign_group) }

    let(:assets) { described_class.json_hash(user)[:assets] }

    before do
      macro && foreign_macro && inactive_macro
      text_tool && foreign_text_tool && inactive_text_tool
      template && inactive_template
      shared_draft && foreign_shared_draft
    end

    it 'provides only accessible records' do
      expect(assets)
        .to include_assets_of(macro, text_tool, template, shared_draft)
        .and not_include_assets_of(foreign_macro, inactive_macro, foreign_text_tool, inactive_text_tool, inactive_template, foreign_shared_draft)
    end

    context 'when user is admin' do
      let(:user) { create(:admin, groups: [group, foreign_group]) }

      it 'provides all records' do
        expect(assets)
          .to include_assets_of(macro, foreign_macro, inactive_macro, text_tool, foreign_text_tool, inactive_text_tool, template, inactive_template, shared_draft, foreign_shared_draft)
      end
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it 'provides no records' do
        expect(assets)
          .to not_include_assets_of(macro, foreign_macro, inactive_macro, text_tool, foreign_text_tool, inactive_text_tool, template, inactive_template, shared_draft, foreign_shared_draft)
      end
    end
  end

  describe 'New collections by installed packages are crashing zammad#4748' do
    let(:collection_files) { Rails.root.glob('lib/session_helper/collection_*.rb').map(&:to_s) }
    let(:unloadable_file)  { Rails.root.join('lib/session_helper/collection_xxx.rb').to_s }

    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production'))
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with(%r{/lib/session_helper/collection_\*\.rb\z}).and_return([*collection_files, unloadable_file])
    end

    it 'skips collection files without a loaded constant and keeps the other collections' do
      collections, = described_class.default_collections(User.find(1))

      expect(collections).to include(Locale.to_app_model)
    end
  end
end
