# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Settings > BETA UI', type: :system do
  let(:route) { '#manage' }

  before { visit route }

  context 'when BETA UI admin menu is enabled', authenticated_as: :authenticate do
    def authenticate
      Setting.set('ui_desktop_beta_switch_admin_menu', true)
      true
    end

    it 'shows BETA UI menu item' do
      within '.sidebar' do
        expect(page).to have_link('BETA UI', href: '#settings/beta_ui')
      end
    end

    context 'when visiting BETA UI screen' do
      let(:route) { '#settings/beta_ui' }

      it 'supports modifying BETA UI settings' do
        expect(page).to have_no_text('Try New BETA UI')

        within :active_content do
          expect(page).to have_css('h1', text: 'BETA UI Availability')
          check_switch_field_value('betaUIToggle', false)
          set_switch_field_value('betaUIToggle', true)
        end

        expect(Setting.get('ui_desktop_beta_switch')).to be(true)
        expect(page).to have_text('Try New BETA UI')

        within :active_content do
          click "[data-attribute-name='ui_desktop_beta_switch_role_ids'] .columnSelect-column--sidebar .columnSelect-option", exact_text: 'Customer'
          click_on 'Submit'
        end

        expect(Setting.get('ui_desktop_beta_switch_role_ids')).to eq([Role.lookup(name: 'Customer').id.to_s])
        expect(page).to have_no_text('Try New BETA UI')
      end
    end
  end

  context 'when BETA UI admin menu is disabled' do
    it 'does not show BETA UI menu item' do
      within '.sidebar' do
        expect(page).to have_no_link('BETA UI', href: '#settings/beta_ui')
      end
    end
  end
end
