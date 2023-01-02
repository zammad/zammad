# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Maintenance - Session Message', type: :system do
  let(:agent)                 { User.find_by(login: 'agent1@example.com') }
  let(:session_message_title) { 'Testing <b>Session Message Title</b>' }
  let(:session_message_text)  { "message <b>1äöüß</b> Session Message Title\n\n\nhttps://zammad.org" }

  def check_sesion_message_content(title, text)
    expect(page).to have_text(title)
    expect(page).to have_text(text)
  end

  context 'when maintenance session message is used and a open session exists' do
    before do
      visit '/'

      using_session(:second_browser) do
        login(
          username: agent.login,
          password: 'test',
        )
      end
    end

    it 'check that the maintenance session message appears' do
      visit 'system/maintenance'

      within :active_content do
        fill_in 'head', with: session_message_title
        find('.js-Message .js-textarea[data-name="message"]').send_keys(session_message_text)

        click '.js-Message button.js-submit'
      end

      using_session(:second_browser) do
        in_modal do
          check_sesion_message_content(session_message_title, session_message_text)

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
        fill_in 'head', with: "#{message_title} #2"
        find('.js-Message .js-textarea[data-name="message"]').send_keys("#{message_text} #2")
        check 'reload', allow_label_click: true

        click '.js-Message button.js-submit'
      end

      using_session(:second_browser) do
        in_modal do
          check_sesion_message_content(message_title, message_text)

          expect(page).to have_text('Continue session')
        end
      end
    end
  end
end
