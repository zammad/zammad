# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::KnowledgeBase::CategoriesControllerPolicy do
  subject(:policy) { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::CategoriesController }

  let(:record) do
    rec        = record_class.new
    rec.params = params

    rec
  end

  context 'with knowledge_base.reader permissions' do
    let(:user)   { create(:agent) }
    let(:params) { { id: internal_answer.category.id, knowledge_base_id: knowledge_base.id } }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(:create, :update, :destroy) }
  end

  context 'when using granular permissions' do
    let(:user) { create(:user, role_ids: [role.id]) }
    let(:role) { create(:role, permission_names: ['knowledge_base.editor']) }

    context 'when managing a subcategory' do
      let(:params) { { id: subcategory.id, parent_id: category.id, knowledge_base_id: knowledge_base.id } }

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

    context 'when creating a new root-level category (#6148)' do
      let(:params) { { knowledge_base_id: knowledge_base.id } }

      before do
        KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role => access
      end

      context 'when KB is editable' do
        let(:access) { 'editor' }

        it { is_expected.to permit_action(:create) }
      end

      context 'when KB is not editable' do
        let(:access) { 'reader' }

        it { is_expected.to forbid_action(:create) }
      end
    end

    context 'when managing a top level category' do
      let(:params) { { id: category.id, knowledge_base_id: knowledge_base.id } }

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

    context 'when creating a root-level category without knowledge_base_id' do
      let(:params) { { id: category.id } }

      it 'raises an appropriate error' do
        expect { policy.create? }.to raise_error(ActiveRecord::RecordNotFound, %r{Couldn't find KnowledgeBase without an ID})
      end
    end
  end
end
