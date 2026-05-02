# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Admin Panel > Knowledge Base > Create', type: :system do
  before do
    visit '/#manage/knowledge_base'
  end

  context 'with valid data' do
    it 'creates a knowledge base' do
      find('[data-name="kb_locales"] .js-input').fill_in with: 'Lithuanian'
      find('.js-option.is-active').click

      click_on 'Create Knowledge Base'

      expect(page).to have_text('Theme').and have_text('Languages')
    end
  end

  context 'with missing locale' do
    it 'shows validation error' do
      click_on 'Create Knowledge Base'

      expect(page).to have_text('At least one locale is required.')
    end
  end
end
