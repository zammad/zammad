# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Knowledge Base > Delete category', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:agent)       { create(:agent, roles: [Role.find_by(name: 'Agent'), role_editor]) }
  let(:role_editor) { create(:role, permission_names: %w[knowledge_base.editor]) }

  let!(:knowledge_base) { create(:knowledge_base) }
  let!(:empty_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let!(:full_category)  { create(:knowledge_base_category, :containing_published, knowledge_base: knowledge_base) }

  let(:empty_category_title) { empty_category.translations.first.title }
  let(:full_category_title)  { full_category.translations.first.title }

  before do
    open_desktop('/knowledge-base')
  end

  def delete_from_card_menu(title)
    main_content.get_by_role('listitem').filter(hasText: title).get_by_role('button', name: 'Category actions').click
    page.get_by_role('menuitem', name: 'Delete category').click
  end

  it 'deletes an empty category after confirmation' do
    delete_from_card_menu(empty_category_title)

    dialog = page.get_by_role('dialog', name: 'Delete object')
    expect(dialog).to contain_text("Do you really want to delete \"#{empty_category_title}\"?")
    dialog.get_by_role('button', name: 'Delete object').click

    expect(page.locator('body')).to not_contain_text(empty_category_title)
    expect(KnowledgeBase::Category).not_to exist(empty_category.id)
  end

  it 'refuses to delete a category with content' do
    delete_from_card_menu(full_category_title)

    dialog = page.get_by_role('dialog', name: 'Cannot delete category')
    expect(dialog).to contain_text('Delete all child categories and answers, then try again.')

    expect(dialog.get_by_role('button', name: 'Cancel & go back')).to have_count(0)

    dialog.get_by_role('button', name: 'OK', exact: true).click
    expect(dialog).to have_count(0)

    expect(main_content).to contain_text(full_category_title)
    expect(KnowledgeBase::Category).to exist(full_category.id)
  end
end
