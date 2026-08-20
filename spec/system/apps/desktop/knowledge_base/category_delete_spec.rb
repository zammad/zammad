# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Knowledge Base > Delete category', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent)       { create(:agent, roles: [Role.find_by(name: 'Agent'), role_editor]) }
  let(:role_editor) { create(:role, permission_names: %w[knowledge_base.editor]) }

  let!(:knowledge_base) { create(:knowledge_base) }
  let!(:empty_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let!(:full_category)  { create(:knowledge_base_category, :containing_published, knowledge_base: knowledge_base) }

  let(:empty_category_title) { empty_category.translations.first.title }
  let(:full_category_title)  { full_category.translations.first.title }

  before do
    visit '/knowledge-base'
  end

  def delete_from_card_menu(title)
    within('li', text: title) do
      click_on 'Category actions'
    end

    click_on 'Delete category'
  end

  it 'deletes an empty category after confirmation' do
    delete_from_card_menu(empty_category_title)

    within '[role="dialog"]' do
      expect(page).to have_text("Do you really want to delete \"#{empty_category_title}\"?")

      click_on 'Delete object'
    end

    expect(page).to have_no_text(empty_category_title)
    expect(KnowledgeBase::Category).not_to exist(empty_category.id)
  end

  it 'refuses to delete a category with content' do
    delete_from_card_menu(full_category_title)

    within '[role="dialog"]' do
      expect(page).to have_text('Cannot delete category')
        .and have_text('Delete all child categories and answers, then try again.')

      # An informational dialog only — there is no cancel button.
      expect(page).to have_no_button('Cancel & go back')

      click_on 'OK'
    end

    expect(page).to have_text(full_category_title)
    expect(KnowledgeBase::Category).to exist(full_category.id)
  end
end
