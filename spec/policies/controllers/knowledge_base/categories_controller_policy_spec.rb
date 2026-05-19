# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::KnowledgeBase::CategoriesControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::CategoriesController }

  let(:record) do
    rec        = record_class.new
    rec.params = params

    rec
  end

  context 'with knowledge_base.reader permissions' do
    let(:user)   { create(:agent) }
    let(:params) { { id: internal_answer.category.id } }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(:create, :update, :destroy) }
  end

  context 'when using granular permissions' do
    let(:user) { create(:user, role_ids: [role.id]) }
    let(:role) { create(:role, permission_names: ['knowledge_base.editor']) }

    context 'when managign a subcategory' do
      let(:params) { { id: subcategory.id, parent_id: category.id } }

      before do
        KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role => 'reader'
        KnowledgeBase::PermissionsUpdate.new(category).update! role => access
      end

      context 'when parent category is editable' do
        let(:access) { 'editor' }

        it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
      end

      context 'when parent category is not editable' do
        let(:access) { 'reader' }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to forbid_actions(:create, :update, :destroy) }
      end

      context 'when parent category is unreachable' do
        let(:access) { 'none' }

        it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
      end
    end

    context 'when managing a top level category' do
      let(:params) { { id: category.id } }

      before do
        KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role => access
      end

      context 'when KB is editable' do
        let(:access) { 'editor' }

        it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
      end

      context 'when KB is not editable' do
        let(:access) { 'reader' }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to forbid_actions(:create, :update, :destroy) }
      end

      context 'when KB is unreachable' do
        let(:access) { 'none' }

        it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
      end
    end
  end
end
