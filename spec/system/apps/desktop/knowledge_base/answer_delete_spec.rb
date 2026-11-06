# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Knowledge Base > Delete answer', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:agent)       { create(:agent, roles: [Role.find_by(name: 'Agent'), role_editor]) }
  let(:role_editor) { create(:role, permission_names: %w[knowledge_base.editor]) }

  let!(:knowledge_base) { create(:knowledge_base) }
  let!(:category)       { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let!(:answer)         { create(:knowledge_base_answer, :published, category: category) }

  let(:locale)        { knowledge_base.kb_locales.first.system_locale.locale }
  let(:answer_title)  { answer.translations.first.title }
  let(:category_path) { "/knowledge-base/locale/#{locale}/category/#{category.id}" }

  it 'deletes the opened answer after confirmation' do
    open_desktop("/knowledge-base/locale/#{locale}/answer/#{answer.id}")

    # The answer's actions sit in the sidebar's header, not in the top bar.
    content_sidebar.get_by_role('button', name: 'Additional actions').click
    page.get_by_role('menuitem', name: 'Delete answer').click

    dialog = page.get_by_role('dialog', name: 'Delete object')
    expect(dialog).to contain_text("Do you really want to delete \"#{answer_title}\"?")
    dialog.get_by_role('button', name: 'Delete object').click

    # The answer's URL is a dead end now, so the flow lands on its category.
    expect(page).to have_url(%r{/desktop#{category_path}$})
    expect(page.locator('body')).to not_contain_text(answer_title)

    wait_for_mutation('knowledgeBaseAnswerDelete')

    expect(KnowledgeBase::Answer).not_to exist(answer.id)
  end

  context 'without editor access' do
    let(:agent)       { create(:agent, roles: [Role.find_by(name: 'Agent'), role_reader]) }
    let(:role_reader) { create(:role, permission_names: %w[knowledge_base.reader]) }

    # A reader has neither of the actions the card menu would hold, so there is no menu at all.
    it 'offers no answer actions' do
      open_desktop(category_path)

      expect(main_content).to contain_text(answer_title)
      expect(page.get_by_role('button', name: 'Answer actions')).to have_count(0)
    end
  end
end
