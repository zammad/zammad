require 'rails_helper'

RSpec.describe 'Login Message', type: :system, authenticated: false do
  context 'with maintenance_login_message' do
    let(:message) { "badum tssss #{rand(99_999)}" }
    let(:alt_message)  { 'lorem ipsum' }

    before { Setting.set 'maintenance_login_message', message }

    context 'with maintenance_login' do
      before { Setting.set 'maintenance_login', true }

      it 'shows message' do
        open_login_page

        expect(page).to have_text(message)
      end

      it 'hides message on the go' do
        open_login_page

        Setting.set 'maintenance_login', false

        expect(page).to have_no_css('.js-maintenanceLogin', text: message, wait: 10)
      end

      it 'changes message text on the go' do
        open_login_page

        Setting.set 'maintenance_login_message', alt_message

        expect(page).to have_no_css('.js-maintenanceLogin', text: alt_message, wait: 10)
      end
    end

    context 'without maintenance_login' do
      before { Setting.set 'maintenance_login', false }

      it 'does not show message' do
        open_login_page

        expect(page).not_to have_text(message)
      end

      it 'shows message on the go' do
        open_login_page

        Setting.set 'maintenance_login', true

        wait(10).until_exists { find '.js-maintenanceLogin', text: message, wait: false }

        expect(page).to have_css('.js-maintenanceLogin', text: message)
      end
    end
  end

  def open_login_page
    visit '/'

    ensure_websocket
  end
end
