# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# https://github.com/zammad/zammad/issues/6188
RSpec.describe 'Admin Panel > Knowledge Base > Remove Language', type: :system do
  include_context 'basic Knowledge Base'

  context 'when removing a language' do
    before do
      alternative_locale
      visit '/#manage/knowledge_base'
      find('a', text: 'Languages').click
      find('.js-remove:not(.is-disabled)').click
      click_on 'Submit'
    end

    it 'shows a confirmation dialog' do
      expect(page).to have_text 'Remove Language'
    end

    context 'when confirming removal' do
      before do
        in_modal do
          find('input[name="sure"]').fill_in with: 'DELETE'
          click_on 'Delete'
        end
        await_empty_ajax_queue
      end

      it 'removes the language' do
        expect(KnowledgeBase::Locale.exists?(alternative_locale.id)).to be false
      end
    end

    context 'when cancelling' do
      before do
        in_modal { click_on 'Cancel' }
      end

      it 'keeps the language' do
        expect(KnowledgeBase::Locale.exists?(alternative_locale.id)).to be true
      end
    end
  end

  context 'when not removing a language' do
    before do
      primary_locale
      visit '/#manage/knowledge_base'
      find('a', text: 'Languages').click
      click_on 'Submit'
      await_empty_ajax_queue
    end

    it 'does not show a confirmation dialog' do
      expect(page).to have_no_text 'Remove Language'
    end
  end
end
