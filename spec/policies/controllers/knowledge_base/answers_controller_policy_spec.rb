# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Controllers::KnowledgeBase::AnswersControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::AnswersController }
  let(:record) do
    rec             = record_class.new
    rec.params      = params

    rec
  end

  let(:params) { { id: internal_answer.id, category_id: category.id } }

  context 'when user is editor' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
  end

  context 'when user is reader' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(:create, :update, :destroy) }
  end

  context 'when user is non-kb-user' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end

  context 'when using granular permissions' do
    let(:user) { create(:user, role_ids: [role.id]) }
    let(:role) { create(:role, permission_names: ['knowledge_base.editor']) }

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
end
