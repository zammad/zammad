# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
    it { is_expected.not_to allow_access_value(nil) }
    it { is_expected.not_to allow_access_value('foobar') }

    context 'when role is editor' do
      it { is_expected.to allow_access_value('editor') }
      it { is_expected.to allow_access_value('reader') }
      it { is_expected.to allow_access_value('none') }
    end

    context 'when role is reader' do
      subject(:kb_category_permission) { build(:knowledge_base_permission, role: create(:role, permission_names: 'knowledge_base.reader')) }

      it { is_expected.not_to allow_access_value('editor') }
      it { is_expected.to allow_access_value('reader') }
      it { is_expected.to allow_access_value('none') }
    end

    context 'when role has no KB access' do
      subject(:kb_category_permission) { build(:knowledge_base_permission, role: create(:role)) }

      it { is_expected.not_to allow_access_value('editor') }
      it { is_expected.not_to allow_access_value('reader') }
      it { is_expected.not_to allow_access_value('none') }
    end
  end

  matcher :allow_access_value do
    match do
      actual.access = expected
      actual.valid?
    end

    failure_message do
      "Expected to allow #{expected} as access, but was not allowed"
    end

    failure_message_when_negated do
      "Expected to not allow #{expected} as access, but was allowed"
    end
  end
end
