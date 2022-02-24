# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Permission, type: :model do
  subject(:kb_category_permission) { create(:knowledge_base_permission) }

  include_context 'basic Knowledge Base'
  include_context 'factory'

  describe '#permissionable' do
    it { is_expected.to belong_to(:permissionable).touch(true) }

    it 'allows multiple permissions for the same category' do
      permission = build(:knowledge_base_permission, permissionable: kb_category_permission.permissionable)
      permission.save

      expect(permission).to be_persisted
    end

    it 'does not allow same role/permission conbination' do
      permission = build(:knowledge_base_permission,
                         permissionable: kb_category_permission.permissionable,
                         role:           kb_category_permission.role)
      permission.save

      expect(permission).not_to be_persisted
    end
  end

  describe '#role' do
    it { is_expected.to belong_to(:role) }

    it 'allows multiple permissions for the same category' do
      permission = build(:knowledge_base_permission, role: kb_category_permission.role)
      permission.save

      expect(permission).to be_persisted
    end
  end

  describe '#access' do
    it { is_expected.to validate_presence_of(:access).with_message(%r{}) }
    it { is_expected.to allow_value('editor').for(:access) }
    it { is_expected.to allow_value('reader').for(:access) }
    it { is_expected.to allow_value('none').for(:access) }
    it { is_expected.not_to allow_value('foobar').for(:access) }
  end
end
