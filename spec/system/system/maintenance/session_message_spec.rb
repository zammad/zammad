# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Maintenance - Session Message', type: :system do
  let(:agent)                 { User.find_by(login: 'agent1@example.com') }
  let(:session_message_title) { 'Testing Session Message Title' }
  let(:session_message_text)  { 'message 1äöüß Session Message Text https://zammad.org' }

  def check_session_message_content(title, text)
    expect(page).to have_text(title).and have_text(text)
  end

  context 'when maintenance session message is used and a open session exists' do
    before do
      visit '/'
      ensure_websocket

      using_session(:second_browser) do
        login(
          username: agent.login,
          password: 'test',
        )
        ensure_websocket
      end
    end

    it 'check that the maintenance session message appears' do
      visit 'system/maintenance'

      within :active_content do
        fill_in 'head', with: session_message_title

        within '.js-Message' do
          set_editor_field_value 'message', session_message_text
        end

        click '.js-Message button.js-submit'
      end

      using_session(:second_browser) do
        in_modal do
          check_session_message_content(session_message_title, session_message_text)

          click '.js-close'
        end
      end

      within :active_content do
        expect(page).to have_no_text(session_message_title)
        expect(page).to have_no_text(session_message_text)
      end
    end

    it 'check that the maintenance session message appears with browser reload' do
      message_title = "#{session_message_title} #2"
      message_text = "#{session_message_text} #2"

      visit 'system/maintenance'

      within :active_content do
        fill_in 'head', with: message_title

        within '.js-Message' do
          set_editor_field_value 'message', message_text
        end

        check 'reload', allow_label_click: true

        click '.js-Message button.js-submit'
      end

      using_session(:second_browser) do
        in_modal do
          check_session_message_content(message_title, message_text)

          expect(page).to have_text('Continue session')
        end
      end
    end
  end
end
