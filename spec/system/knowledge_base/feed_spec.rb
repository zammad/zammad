# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base feed', type: :system do
  include_context 'basic Knowledge Base'

  before do
    knowledge_base.update! show_feed_icon: show_feed_icon
    published_answer
  end

  context 'when feed is on' do
    let(:show_feed_icon) { true }

    it 'shows root link at main page' do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}"

      click '.icon-rss'

      in_modal do
        token = Token.last.name

        link = find('a', text: knowledge_base.translations.first.title)

        expect(link[:href]).to end_with feed_knowledge_base_path(knowledge_base, locale_name, token: token)
      end
    end

    it 'shows root and category links at category page' do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/category/#{category.id}"

      click '.icon-rss'

      in_modal do
        token = Token.last.name

        kb_link = find('a', text: knowledge_base.translations.first.title)

        expect(kb_link[:href]).to end_with feed_knowledge_base_path(knowledge_base, locale_name, token: token)

        category_link = find('a', text: category.translations.first.title)

        expect(category_link[:href]).to end_with feed_knowledge_base_category_path(knowledge_base, category, locale_name, token: token)
      end
    end

    it 'shows root and category links at answer page' do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/answer/#{published_answer.id}"

      click '.icon-rss'

      in_modal do
        token = Token.last.name

        kb_link = find('a', text: knowledge_base.translations.first.title)

        expect(kb_link[:href]).to end_with feed_knowledge_base_path(knowledge_base, locale_name, token: token)

        category_link = find('a', text: category.translations.first.title)

        expect(category_link[:href]).to end_with feed_knowledge_base_category_path(knowledge_base, category, locale_name, token: token)
      end
    end
  end

  context 'when feed is off' do
    let(:show_feed_icon) { false }

    it 'does not show icon' do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}"

      expect(page).to have_no_css('.icon-rss')
    end
  end
end
