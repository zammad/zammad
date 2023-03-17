# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::EffectivePermission do
  include_context 'basic Knowledge Base'

  describe '#access_effective' do
    let(:role_editor) { create(:role, permission_names: 'knowledge_base.editor') }
    let(:role_reader) { create(:role, permission_names: 'knowledge_base.reader') }
    let(:role_non_kb) { create(:role, :admin) }

    let(:user) { create(:user, roles: [role_editor, role_reader, role_non_kb]) }
    let(:user_editor) { create(:user, roles: [role_editor]) }
    let(:user_admin)  { create(:admin) }
    let(:user_reader) { create(:user, roles: [role_reader]) }
    let(:user_nonkb)  { create(:user, roles: [role_non_kb]) }

    let(:child_category) { create(:knowledge_base_category, parent: category) }

    it 'editor with no permissions defined returns editor' do
      expect(described_class.new(user_editor, category).access_effective).to eq 'editor'
    end

    it 'user with multiple permissions defined returns editor' do
      expect(described_class.new(user, category).access_effective).to eq 'editor'
    end

    it 'reader with no permissions defined returns reader' do
      expect(described_class.new(user_reader, category).access_effective).to eq 'reader'
    end

    it 'non-kb with no permissions defined returns none' do
      expect(described_class.new(user_nonkb, category).access_effective).to eq 'none'
    end

    it 'editor with both reader and editor permissions returns editor' do
      create_permission(role_reader, 'reader')
      create_permission(role_editor, 'editor')

      expect(described_class.new(user_admin, category).access_effective).to eq 'editor'
    end

    it 'editor with reader permission on parent category returns reader' do
      create_permission(role_editor, 'reader')

      expect(described_class.new(user_editor, child_category).access_effective).to eq 'reader'
    end

    it 'editor with reader permission on KB returns reader' do
      create_permission(role_editor, 'reader', permissionable: knowledge_base)

      expect(described_class.new(user_editor, category).access_effective).to eq 'reader'
    end

    it 'editor with reader permission on parent category but editor permission on category returns editor' do
      create_permission(role_editor, 'reader', permissionable: category)
      create_permission(role_editor, 'editor', permissionable: child_category)

      expect(described_class.new(user_editor, child_category).access_effective).to eq 'editor'
    end

    it 'editor with editor permission on parent category but reader permission on category returns reader' do
      create_permission(role_editor, 'editor', permissionable: category)
      create_permission(role_editor, 'reader', permissionable: child_category)

      expect(described_class.new(user_editor, child_category).access_effective).to eq 'reader'
    end

    it 'reader with reader and non-effective permissions returns reader' do
      create_permission(role_reader, 'reader')
      create_permission(role_editor, 'editor')

      expect(described_class.new(user_reader, category).access_effective).to eq 'reader'
    end

    it 'reader with no matching permissions returns reader' do
      create_permission(role_editor, 'editor')

      expect(described_class.new(user_reader, category).access_effective).to eq 'reader'
    end

    it 'retuns none when user not given' do
      expect(described_class.new(nil, category).access_effective).to eq 'none'
    end
  end

  def create_permission(role, access, permissionable: category)
    create(:knowledge_base_permission, role: role, permissionable: permissionable, access: access)
  end
end
