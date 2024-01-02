# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

  context 'when KB has a custom address' do
    before do
      knowledge_base.update! custom_address: '/custom'

      allow_any_instance_of(KnowledgeBase)
        .to receive(:custom_address_matches?).and_return(true)

      published_answer && published_answer_with_tag

      visit help_tag_path(locale_name, published_answer_tag_name)
    end

    let(:prefix)        { "https://#{Setting.get('fqdn')}" }
    let(:expected_path) { help_tag_path(locale_name, published_answer_tag_name).gsub(%r{/help}, '/custom') }
    let(:expected_url)  { "#{prefix}#{expected_path}" }

    # https://github.com/zammad/zammad/issues/4111
    it 'shows tag breadcrumb correctly' do
      expect(page)
        .to have_breadcrumb_item(published_answer_tag_name)
        .at_index(1)
        .with_url(expected_url)
    end
  end
end
