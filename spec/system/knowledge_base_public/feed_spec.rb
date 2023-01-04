# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base feed', authenticated_as: false, type: :system do
  include_context 'basic Knowledge Base'

  before do
    knowledge_base.update! show_feed_icon: show_feed_icon
    published_answer
  end

  context 'when feed is on' do
    let(:show_feed_icon) { true }

    it 'shows root link at main page' do
      visit help_root_path(locale_name)

      click '.icon-rss'

      within '.dropdown-menu' do
        link = find('a', text: knowledge_base.translations.first.title)

        expect(link[:href]).to end_with help_root_feed_path(locale_name)
      end
    end

    it 'shows root and category links at category page' do
      visit help_category_path(locale_name, category)

      click '.icon-rss'

      within '.dropdown-menu' do
        kb_link = find('a', text: knowledge_base.translations.first.title)

        expect(kb_link[:href]).to end_with help_root_feed_path(locale_name)

        category_link = find('a', text: category.translations.first.title)

        expect(category_link[:href]).to end_with help_category_feed_path(locale_name, category)
      end
    end

    it 'shows root and category links at answer page' do
      visit help_answer_path(locale_name, category, published_answer)

      click '.icon-rss'

      within '.dropdown-menu' do
        kb_link = find('a', text: knowledge_base.translations.first.title)

        expect(kb_link[:href]).to end_with help_root_feed_path(locale_name)

        category_link = find('a', text: category.translations.first.title)

        expect(category_link[:href]).to end_with help_category_feed_path(locale_name, category)
      end
    end
  end

  context 'when feed is off' do
    let(:show_feed_icon) { false }

    it 'does not show icon' do
      visit help_root_path(locale_name)

      expect(page).to have_no_css('.icon-rss')
    end
  end
end
