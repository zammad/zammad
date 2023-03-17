# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base tag', authenticated_as: false, type: :system do
  include_context 'basic Knowledge Base'

  context 'when answer with the tag exists' do
    before do
      published_answer && published_answer_with_tag

      visit help_tag_path(locale_name, published_answer_tag_name)
    end

    it 'displays tag name' do
      expect(page).to have_css('h1', text: published_answer_tag_name)
    end

    it 'lists an answer with the tag' do
      expect(page).to have_link(published_answer_with_tag.translations.first.title)
    end

    it 'does not list another answer' do
      expect(page).to have_no_link(published_answer.translations.first.title)
    end

    it 'does not show empty placeholder' do
      expect(page).to have_no_css('.sections-empty')
    end
  end

  context 'when no answers with the tag exists' do
    before do
      published_answer

      visit help_tag_path(locale_name, published_answer_tag_name)
    end

    it 'shows empty placeholder' do
      expect(page).to have_css('.sections-empty')
    end

    it 'shows no links' do
      expect(page).to have_no_css('.main a')
    end

    it 'displays tag name' do
      expect(page).to have_css('h1', text: published_answer_tag_name)
    end
  end
end
