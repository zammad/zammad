# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Clues', authenticated_as: :agent, type: :system do

  let(:agent) { create(:agent, hide_clues: false) }

  context 'when logging in the first time' do
    it 'shows the intro clues' do
      visit 'dashboard'
      expect_current_route 'clues'
      find(:clues_close).in_fixed_position.click

      wait.until do
        agent.reload.preferences >= { 'intro' => true, 'keyboard_shortcuts_clues' => true }
      end
    end
  end

  context 'when the dashboard is turned off' do
    before do
      Setting.set('dashboard', false)
    end

    it 'shows the intro clues on the overviews' do
      visit '/'
      expect_current_route 'clues'
      find(:clues_close).in_fixed_position.click

      wait.until do
        agent.reload.preferences >= { 'intro' => true, 'keyboard_shortcuts_clues' => true }
      end

      expect_current_route 'ticket/view'
    end

    # A reload finds the overview list cached, so the redirect to the first overview happens right away.
    it 'shows the intro clues on the overviews after a reload' do
      visit '/'
      expect(page).to have_selector(:clues_close)

      visit '/'
      expect(page).to have_selector(:clues_close)
    end

    context 'when logged in as customer', authenticated_as: :customer do
      let(:customer) { create(:customer, hide_clues: false) }

      it 'shows no clues on the overviews' do
        visit 'ticket/view'

        # The redirect to the first overview comes after the clues would have opened.
        expect_current_route 'ticket/view/'
        expect(page).to have_no_css('.js-modal--clue')
      end
    end
  end

  context 'when logging again after the keyboard shortcuts were changed' do
    before do
      # Set a state where the agent saw only the intro, but not the keyboard shortcuts clue.
      agent.preferences = { 'intro' => true }
      agent.save!
    end

    it 'shows the keyboard shortcuts clue and remembers it' do
      visit 'dashboard'

      expect(page).to have_text('New Keyboard Shortcuts')
      find('div.btn', text: 'Got it').click

      wait.until do
        agent.reload.preferences >= { 'intro' => true, 'keyboard_shortcuts_clues' => true }
      end
    end
  end
end
