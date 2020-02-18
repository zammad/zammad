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

        wait(10).until_disappears { find '.js-maintenanceLogin', text: message }

        expect(page).not_to have_css('.js-maintenanceLogin')
      end

      it 'changes message text on the go' do
        open_login_page

        Setting.set 'maintenance_login_message', alt_message

        wait(10).until_exists { find '.js-maintenanceLogin', text: alt_message }

        expect(page).to have_css('.js-maintenanceLogin', text: alt_message)
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

        wait(10).until_exists { find '.js-maintenanceLogin', text: message }

        expect(page).to have_css('.js-maintenanceLogin', text: message)
      end
    end
  end

  def open_login_page
    timestamp = Time.zone.now.to_i

    visit '/'

    wait(5).until do
      pinged_since?(timestamp) && connection_open?
    end

    true
  end

  def pinged_since?(timestamp)
    Sessions
      .list
      .values
      .map  { |elem| elem.dig(:meta, :last_ping) }
      .any? { |elem| elem >= timestamp }
  end

  def connection_open?
    page
      .evaluate_script('App.WebSocket.channel()')
      .present?
  end
end
