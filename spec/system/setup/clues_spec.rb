# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

  context 'when logging again after the keyboard shortcuts were changed' do
    before do
      # Set a state where the agent saw only the intro, but not the keyboard shortcuts clue.
      agent.preferences = { 'intro' => true }
      agent.save!
    end

    it 'shows the intro clues' do
      visit 'dashboard'

      expect(page).to have_text('New Keyboard Shortcuts')
      find('div.btn', text: 'Got it').click

      wait.until do
        agent.reload.preferences >= { 'intro' => true, 'keyboard_shortcuts_clues' => true }
      end
    end
  end
end
