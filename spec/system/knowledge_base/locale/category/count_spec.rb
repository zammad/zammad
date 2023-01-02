# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Answer Read', authenticated_as: true, type: :system do
  include_context 'basic Knowledge Base'

  let(:empty_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

  let(:another_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let(:another_published) { create(:knowledge_base_answer, :published, category: another_category) }

  let(:deep_category) { create(:knowledge_base_category, parent: category) }
  let(:deep_published) { create(:knowledge_base_answer, :published, category: deep_category) }

  before do
    internal_answer && draft_answer && another_published && deep_published && empty_category

    visit 'knowledge_base'
  end

  it 'shows count' do
    within :active_content do
      within '.section-inner', text: category.translations.first.title do
        expect(page).to have_text('Answers: 3')
      end
    end
  end

  it 'shows zero for empty category' do
    within :active_content do
      within '.section-inner', text: empty_category.translations.first.title do
        expect(page).to have_text('Answers: 0')
      end
    end
  end
end
