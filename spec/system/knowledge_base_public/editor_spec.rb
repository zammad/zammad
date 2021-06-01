# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base for editor', type: :system, authenticated_as: true do
  include_context 'basic Knowledge Base'

  before do
    published_answer && draft_answer && internal_answer
  end

  context 'homepage' do
    before { visit help_no_locale_path }

    it { expect(page).to have_editor_bar }

    it 'expect to have edit button' do
      button = find '.topbar-btn'
      expect(button['href']).to match(%r{edit$})
    end
  end

  context 'category' do
    before { visit help_category_path(primary_locale.system_locale.locale, category) }

    it 'shows published answer' do
      within '.main' do
        expect(page).to have_selector(:link_containing, published_answer.translation.title)
      end
    end

    it 'shows draft answer' do
      within '.main' do
        expect(page).to have_selector(:link_containing, draft_answer.translation.title)
      end
    end

    it 'shows internal answer' do
      within '.main' do
        expect(page).to have_selector(:link_containing, internal_answer.translation.title)
      end
    end
  end
end
