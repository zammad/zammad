# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Login Message', authenticated_as: false, type: :system do
  context 'with maintenance_login_message' do
    let(:message)     { "badum tssss #{SecureRandom.uuid}" }
    let(:alt_message) { 'lorem ipsum' }

    before { Setting.set 'maintenance_login_message', message }

    context 'with maintenance_login' do
      before { Setting.set 'maintenance_login', true }

      it 'shows message' do
        open_login_page

        expect(page).to have_css('.js-maintenanceLogin', text: message)
      end

      it 'hides message on the go' do
        open_login_page

        expect(page).to have_css('.js-maintenanceLogin', text: message)

        Setting.set 'maintenance_login', false

        expect(page).to have_no_css('.js-maintenanceLogin', text: message, wait: 30)
      end

      it 'changes message text on the go' do
        open_login_page

        expect(page).to have_css('.js-maintenanceLogin', text: message)

        Setting.set 'maintenance_login_message', alt_message

        expect(page).to have_css('.js-maintenanceLogin', text: alt_message, wait: 30)
      end
    end

    context 'without maintenance_login' do
      before { Setting.set 'maintenance_login', false }

      it 'does not show message' do
        open_login_page

        expect(page).to have_no_text(message)
      end

      it 'shows message on the go' do
        open_login_page

        Setting.set 'maintenance_login', true

        expect(page).to have_css('.js-maintenanceLogin', text: message, wait: 30)
      end
    end
  end

  def open_login_page
    visit '/'

    ensure_websocket

    # Wait until the event binding for the 'config_update_local' is present.
    # TODO: If this works we can maybe move the check for event bindings in a helper function.
    wait.until do
      page.evaluate_script("Object.keys(App.Event._allBindings()).find((key) => {
    return App.Event._allBindings()[key].filter((item) => {
      return item.event === 'config_update_local' || item.event === 'ui:rerender';
    }).length === 2;
  })")
    end
  end
end
