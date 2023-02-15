# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Autosave', type: :system do
  before do
    visit "ticket/zoom/#{Ticket.first.id}"
    click '.attachmentPlaceholder'
  end

  context 'with content added' do
    before do
      find(:richtext).send_keys('sample text')
    end

    it 'autosaves visibility change for the default type' do
      click '.js-toggleVisibility'
      expect(page).to have_css('.js-reset')

      wait_for_autosave_and_reload

      within '.article-new' do
        expect(page)
          .to have_selector('.editControls-icon.icon-public')
          .and have_selector('.js-selectableTypes[data-type="note"]')
      end
    end

    it 'autosaves visibility change back to default for the default type' do
      click '.js-toggleVisibility'
      click '.js-toggleVisibility'

      wait_for_autosave_and_reload

      within '.article-new' do
        expect(page)
          .to have_selector('.editControls-icon.icon-internal')
          .and have_selector('.js-selectableTypes[data-type="note"]')
      end
    end

    it 'autosaves non-default type' do
      click '.js-selectableTypes'
      click '.js-articleTypeItem[data-value=phone]'

      wait_for_autosave_and_reload

      within '.article-new' do
        expect(page)
          .to have_selector('.editControls-icon.icon-public')
          .and have_selector('.js-selectableTypes[data-type="phone"]')
      end
    end

    it 'autosaves non-default type with non-default visibility' do
      click '.js-selectableTypes'
      click '.js-articleTypeItem[data-value=phone]'
      click '.js-toggleVisibility'

      wait_for_autosave_and_reload

      within '.article-new' do
        expect(page)
          .to have_selector('.editControls-icon.icon-internal')
          .and have_selector('.js-selectableTypes[data-type="phone"]')
      end
    end
  end

  context 'without content' do
    it 'ignores visibility change' do
      click '.js-toggleVisibility'

      expect(page).to have_no_css('.js-reset')
    end

    it 'ignores type change' do
      click '.js-selectableTypes'
      click '.js-articleTypeItem[data-value=phone]'

      expect(page).to have_no_css('.js-reset')
    end
  end

  def wait_for_autosave_and_reload
    time = Time.current

    wait.until do
      Taskbar.exists?(['updated_at > ?', time])
    end

    refresh

    click '.attachmentPlaceholder'
  end
end
