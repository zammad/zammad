# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Deliberately without any answer: the removal used to subtract the visible categories from the
#   loaded *answers*, which keeps the category whenever their ids do not happen to line up.
RSpec.describe 'Knowledge Base category losing its access while open', authenticated_as: :user, performs_jobs: true, type: :system do
  include_context 'basic Knowledge Base'

  let(:role) { create(:role, permission_names: %w[ticket.agent knowledge_base.editor]) }
  let(:user) { create(:user, role_ids: [role.id]) }

  before do
    category
    other_category

    visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}"
  end

  it 'removes the category from the client' do
    within :active_content do
      expect(page).to have_text(other_category.translations.first.title)
    end

    perform_enqueued_jobs do
      KnowledgeBase::PermissionsUpdate.new(other_category).update! role => 'none'
    end

    within :active_content do
      expect(page)
        .to have_no_text(other_category.translations.first.title)
        .and have_text(category.translations.first.title)
    end
  end
end
