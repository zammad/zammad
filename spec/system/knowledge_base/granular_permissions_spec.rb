# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Granular permissions', authenticated_as: :user, type: :system do
  include_context 'basic Knowledge Base'

  let(:user) { create(:user, role_ids: [role.id]) }
  let(:role) { create(:role, permission_names: %w[knowledge_base.editor]) }

  context 'when knowledge base is read-only' do
    before do
      KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role => 'reader'
      KnowledgeBase::PermissionsUpdate.new(category).update! role => category_access

      visit '#knowledge_base'
    end

    context 'when category is editable' do
      let(:category_access) { 'editor' }

      context 'when answer is draft' do
        let(:answer) { draft_answer }

        it 'shows the category' do
          expect(page).to have_text(category.translations.first.title)
        end
      end
    end

    context 'when category is read-only' do
      let(:category_access) { 'reader' }

      context 'when answer is draft' do
        let(:answer) { draft_answer }

        it 'does not show the category' do
          expect(page).to have_no_text(category.translations.first.title)
        end
      end
    end
  end
end
