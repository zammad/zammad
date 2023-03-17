# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Auto wizard', set_up: false, type: :system do
  shared_examples 'showing that auto wizard is enabled' do
    it 'shows the auto wizard enable message' do
      visit '/'

      within '.wizard.setup .wizard-slide' do
        expect(page).to have_content('The auto wizard is enabled. Please use the provided auto wizard url.')
      end
    end
  end

  context 'with auto wizard enabled' do
    before do
      FileUtils.ln(
        Rails.root.join('contrib/auto_wizard_test.json'),
        Rails.root.join('auto_wizard.json'),
        force: true
      )
    end

    it_behaves_like 'showing that auto wizard is enabled'

    it 'automatically set up and login' do
      visit 'getting_started/auto_wizard'
      # auto wizard is enabled
      expect(current_login).to eq('admin@example.com')
    end
  end

  context 'when auto wizard is enabled with secret token' do
    before do
      FileUtils.ln(
        Rails.root.join('contrib/auto_wizard_example.json'),
        Rails.root.join('auto_wizard.json'),
        force: true
      )
    end

    it_behaves_like 'showing that auto wizard is enabled'

    it 'automatically setup and login with token params' do
      visit 'getting_started/auto_wizard/secret_token'

      close_clues_modal

      expect(current_login).to eq('hans.atila@zammad.org')
    end

    it 'allows user to login and logout' do
      visit 'getting_started/auto_wizard/secret_token'

      close_clues_modal

      visit 'logout'

      expect(page).to have_current_route('login')

      login(
        username: 'hans.atila@zammad.org',
        password: 'Z4mm4dr0ckZ!'
      )

      expect(page).to have_current_path('/')

      refresh

      expect(current_login).to eq('hans.atila@zammad.org')
    end

    context 'with organisation in the auto_wizard data', searchindex: true do
      before do
        visit 'getting_started/auto_wizard/secret_token'

        searchindex_model_reload([User, Organization])

        close_clues_modal
      end

      it 'shows the organization from the auto wizard' do
        fill_in id: 'global-search', with: 'Demo Organization'

        click_on 'Show Search Details'

        find('[data-tab-content=Organization]').click

        find('.js-content .js-tableBody tr.item').click

        within '.active .profile-window' do
          expect(page).to have_content 'Demo Organization'
          expect(page).to have_content 'Atila'
        end
      end
    end
  end

  def close_clues_modal
    within '.js-modal--clue.modal--clue-ready' do
      find('.modal-close.js-close').click
    end
  end
end
