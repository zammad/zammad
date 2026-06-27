# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base search shortcuts', authenticated_as: :user, type: :system, websocket: false do
  include_context 'basic Knowledge Base'

  let(:user) { create(:admin) }

  before do
    published_answer
  end

  context 'when elasticsearch is enabled', searchindex: true do
    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/search"
    end

    it 'shows the shortcuts dropdown trigger' do
      expect(page).to have_css('.searchfield-shortcut')
    end

    it 'opens the dropdown on click and shows shortcut items' do
      find('.searchfield-shortcut .btn').click

      expect(page).to have_css('.dropdown-menu li', text: 'Created within last 14 days')
      expect(page).to have_css('.dropdown-menu li', text: 'Updated within last 3 days')
      expect(page).to have_css('.dropdown-menu li', text: 'Drafts only')
    end

    it 'populates the search field when a shortcut is clicked' do
      find('.searchfield-shortcut .btn').click
      find('.js-shortcut', text: 'Drafts only').click

      expect(find('.js-searchField').value).to eq('publication_state:draft')
    end

    it 'executes search and shows results after shortcut click' do
      searchindex_model_reload([KnowledgeBase::Answer::Translation])

      find('.searchfield-shortcut .btn').click
      find('.js-shortcut', text: 'Created within last 14 days').click

      expect(page).to have_css('.js-results .section', wait: 5)
    end
  end

  context 'when elasticsearch is disabled', authenticated_as: :authenticate, searchindex: false do
    def authenticate
      Setting.set('es_url', nil)
      true
    end

    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/search"
    end

    it 'does not show the shortcuts dropdown' do
      expect(page).to have_no_css('.searchfield-shortcut')
    end
  end

  context 'when ai-generated answer setting is enabled', authenticated_as: :authenticate, searchindex: true do
    def authenticate
      Setting.set('ai_assistance_kb_answer_from_ticket_generation', true)
      true
    end

    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/search"
    end

    it 'shows the ai-generated shortcut in the dropdown' do
      find('.searchfield-shortcut .btn').click

      expect(page).to have_css('.dropdown-menu li', text: 'Tagged')
    end
  end

  context 'when ai-generated answer setting is disabled', authenticated_as: :authenticate, searchindex: true do
    def authenticate
      Setting.set('ai_assistance_kb_answer_from_ticket_generation', false)
      true
    end

    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/search"
    end

    it 'does not show the ai-generated shortcut in the dropdown' do
      find('.searchfield-shortcut .btn').click

      expect(page).to have_no_css('.dropdown-menu li', text: 'Tagged')
    end
  end
end
