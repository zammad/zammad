# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The category keeps the reader access the user still has, so nothing about it changes and none of
#   its ids move — the access alone does. See App.KnowledgeBaseAgentController#accessMayHaveChanged.
RSpec.describe 'Knowledge Base role based access changing while open', authenticated_as: :user, performs_jobs: true, type: :system do
  include_context 'basic Knowledge Base'

  let(:reader_role) { create(:role, permission_names: %w[ticket.agent knowledge_base.reader]) }
  let(:editor_role) { create(:role, permission_names: %w[knowledge_base.editor]) }
  let(:user)        { create(:user, role_ids: [reader_role.id, editor_role.id]) }

  before do
    published_answer

    visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/category/#{category.id}"
  end

  it 'stops offering the editor actions when the role loses the editor permission' do
    within :active_content do
      expect(page).to have_link('Edit')
    end

    perform_enqueued_jobs do
      editor_role.update!(permission_ids: [])
    end

    within :active_content do
      expect(page).to have_no_link('Edit')
    end
  end

  it 'stops offering the editor actions when the role is deactivated' do
    within :active_content do
      expect(page).to have_link('Edit')
    end

    perform_enqueued_jobs do
      editor_role.update!(active: false)
    end

    within :active_content do
      expect(page).to have_no_link('Edit')
    end
  end
end
