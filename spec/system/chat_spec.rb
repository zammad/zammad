# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Chat Handling', type: :system do
  let(:agent_chat_switch_selector) { '#navigation .js-chatMenuItem .js-switch' }
  let(:chat_url)                   { "/assets/chat/#{chat_url_type}.html?port=#{ENV['WS_PORT']}" }
  let(:chat_url_type)              { 'znuny' }

  def authenticate
    Setting.set('chat', true)
    true
  end

  def check_content(selector, value, should_match: true, wait: nil)
    if should_match
      expect(page).to have_css(selector, wait: wait, text: value)
    else
      expect(page).to have_no_css(selector, wait: wait, text: value)
    end
  end

  def enable_agent_chat
    click agent_chat_switch_selector
    click 'a[href="#customer_chat"]'
  end

  def open_chat_dialog
    expect(page).to have_css('.zammad-chat')
    click '.zammad-chat .js-chat-open'
    expect(page).to have_css('.zammad-chat-is-shown')
  end

  def send_customer_message(message)
    find('.zammad-chat .zammad-chat-input').send_keys(message)
    click '.zammad-chat .zammad-chat-send'
  end

  def send_agent_message(message)
    input = find('.active .chat-window .js-customerChatInput')
    input.send_keys(message)
    # Work around an obsure bug of send_keys sometimes not working on Firefox headless.
    if input.text != message
      input.execute_script("this.textContent = '#{message}'")
    end
    click '.active .chat-window .js-send'
  end

  shared_examples 'chat button is hidden after idle timeout' do
    it 'check that button is hidden after idle timeout', authenticated_as: :authenticate do
      click agent_chat_switch_selector

      using_session :customer do
        visit chat_url

        expect(page).to have_css('.zammad-chat', visible: :all)
        expect(page).to have_css('.zammad-chat-is-hidden', visible: :all)
        expect(page).to have_no_css('.open-zammad-chat:not([style*="display: none"]', visible: :all)
      end
    end
  end

  shared_examples 'chat messages' do
    it 'messages in each direction, starting on agent side', authenticated_as: :authenticate do
      enable_agent_chat

      using_session :customer do
        visit chat_url
        open_chat_dialog
      end

      click '.active .js-acceptChat'

      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')
      check_content('.active .chat-window .js-body', chat_url)

      send_agent_message('my name is me')

      using_session :customer do
        check_content('.zammad-chat .zammad-chat-agent-status', 'Online')
        check_content('.zammad-chat', 'my name is me')
        send_customer_message('my name is customer')
      end

      check_content('.active .chat-window', 'my name is customer')
      expect(page).to have_css('.active .chat-window .chat-status.is-modified')

      click '.active .chat-window .js-customerChatInput'

      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')

      using_session :customer do
        click '.js-chat-toggle .zammad-chat-header-icon'
      end

      check_content('.active .chat-window', 'closed the conversation')
    end

    it 'messages in each direction, starting on customer side', authenticated_as: :authenticate do
      enable_agent_chat

      using_session :customer do

        visit chat_url

        open_chat_dialog
      end

      click '.active .js-acceptChat'

      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')

      # Keep focus outside of chat window to check .chat-status.is-modified later.
      click_on 'Dashboard'

      using_session :customer do
        check_content('.zammad-chat .zammad-chat-agent-status', 'Online')
        send_customer_message('my name is customer')
      end

      click 'a[href="#customer_chat"]'

      expect(page).to have_css('.active .chat-window .chat-status.is-modified')
      check_content('.active .chat-window', 'my name is customer')

      send_agent_message('my name is me')
      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')

      using_session :customer do
        check_content('.zammad-chat', 'my name is me')
      end

      click '.active .chat-window .js-disconnect:not(.is-hidden)'
      click '.active .chat-window .js-close'

      using_session :customer do

        check_content('.zammad-chat .zammad-chat-agent-status', 'Offline')
        check_content('.zammad-chat', %r{(Chat closed by|Chat.*geschlossen)})

        click '.zammad-chat .js-chat-toggle .zammad-chat-header-icon'

        expect(page).to have_no_css('.zammad-chat-is-open')

        open_chat_dialog
      end

      click '.active .js-acceptChat'

      expect(page).to have_css('.active .chat-window .chat-status')
    end
  end

  shared_examples 'open chat with button' do
    it 'open the chat', authenticated_as: :authenticate do
      enable_agent_chat

      using_session :customer do
        visit chat_url

        expect(page).to have_css('.zammad-chat', visible: :all)
        expect(page).to have_css('.zammad-chat-is-hidden', visible: :all)
        expect(page).to have_no_css('.zammad-chat-is-shown', visible: :all)
        expect(page).to have_no_css('.zammad-chat-is-open', visible: :all)

        click '.open-zammad-chat'

        expect(page).to have_css('.zammad-chat-is-shown', visible: :all)
        expect(page).to have_css('.zammad-chat-is-open', visible: :all)
        check_content('.zammad-chat-modal-text', %r{(waiting|Warte)})

        click '.zammad-chat-header-icon-close'

        expect(page).to have_no_css('.zammad-chat-is-shown', visible: :all)
        expect(page).to have_no_css('.zammad-chat-is-open', visible: :all)
      end
    end
  end

  shared_examples 'timeouts' do
    it 'check different timeouts', authenticated_as: :authenticate do
      enable_agent_chat

      using_session :customer do

        visit chat_url

        # No customer action, hide the widget.
        expect(page).to have_css('.zammad-chat')

        expect(page).to have_no_css('.zammad-chat')

        refresh

        # No agent action, show sorry screen.
        open_chat_dialog

        check_content('.zammad-chat-modal-text', %r{(waiting|Warte)})
        check_content('.zammad-chat-modal-text', %r{(taking longer|dauert länger)})

        refresh

        # No customer action, show sorry screen.
        open_chat_dialog
      end

      click '.active .js-acceptChat'

      send_agent_message('agent is asking')

      using_session :customer do

        check_content('.zammad-chat', 'agent is asking')

        check_content('.zammad-chat-modal-text', %r{(Since you didn't respond|Da Sie innerhalb der letzten)}, wait: 30)
      end

      # Test the restart of inactive chat.
      click '.active .chat-window .js-close'

      using_session :customer do

        click '.js-restart'
        open_chat_dialog
      end

      click '.active .js-acceptChat'

      send_agent_message('my name is me')

      using_session :customer do
        check_content('.zammad-chat', 'my name is me')
      end
    end
  end

  context 'when chat is activated or disabled' do
    it 'switch the chat setting', authenticated_as: :authenticate do
      visit '/#channels/chat'

      click '.content.active .js-chatSetting'

      expect(page).to have_no_css(agent_chat_switch_selector)

      using_session :customer do

        visit chat_url

        check_content('.settings', '{"state":"chat_disabled"}')
      end

      click '.content.active .js-chatSetting'

      expect(page).to have_css(agent_chat_switch_selector)

      using_session :customer do

        refresh

        expect(page).to have_no_css('.zammad-chat')
        check_content('.settings', '{"state":"chat_disabled"}', should_match: false)
        check_content('.settings', '{"event":"chat_status_customer","data":{"state":"offline"}}')
      end

      click agent_chat_switch_selector
      click 'a[href="#customer_chat"]'

      using_session :customer do

        refresh

        expect(page).to have_css('.zammad-chat')
        check_content('.settings', '{"event":"chat_status_customer","data":{"state":"offline"}}', should_match: false)
        check_content('.settings', '{"state":"online"}')

        click '.zammad-chat .js-chat-open'

        expect(page).to have_css('.zammad-chat-is-shown')
        check_content('.zammad-chat-modal-text', %r{(waiting|Warte)})
      end

      check_content('.js-chatMenuItem .counter', '1')

      using_session :customer do

        click '.zammad-chat .js-chat-toggle .zammad-chat-header-icon'

        check_content('.zammad-chat-modal-text', %r{(waiting|Warte)}, should_match: false)
      end

      expect(page).to have_no_css('.js-chatMenuItem .counter')
    end
  end

  context 'when changing chat preferences for current agent' do
    it 'use chat phrase preference', authenticated_as: :authenticate do
      visit '/'

      enable_agent_chat

      click '.active .js-settings'

      in_modal do
        find('[name="chat::phrase::1"]').send_keys('Hi Stranger!;My Greeting')
        click '.js-submit'
      end

      using_session :customer do

        visit chat_url

        open_chat_dialog
      end

      click '.active .js-acceptChat'

      expect(page).to have_css('.active .chat-window .chat-status')

      using_session :customer do
        check_content('.zammad-chat', %r{(Hi Stranger|My Greeting)})
      end

      send_agent_message('my name is me')

      using_session :customer do

        check_content('.zammad-chat', 'my name is me')

        refresh

        expect(page).to have_css('.zammad-chat')
        check_content('.zammad-chat', %r{(Hi Stranger|My Greeting)})
        check_content('.zammad-chat', 'my name is me')

        visit "#{chat_url}#new_hash"
      end

      check_content('.active .chat-window .js-body', "#{chat_url}#new_hash")
    end
  end

  context 'when jquery variant is used' do
    before do
      visit '/'
    end

    context 'when normal mode is used' do
      include_examples 'chat messages'
      include_examples 'timeouts'
    end

    context 'when button mode is active' do
      let(:chat_url_type) { 'znuny_open_by_button' }

      include_examples 'open chat with button'
      include_examples 'chat button is hidden after idle timeout'
    end
  end

  context 'when no-jquery variant is used' do
    let(:chat_url_type) { 'znuny-no-jquery' }

    before do
      visit '/'
    end

    context 'when normal mode is used' do
      include_examples 'chat messages'
      include_examples 'timeouts'
    end

    context 'when button mode is active' do
      let(:chat_url_type) { 'znuny-no-jquery-open_by_button' }

      include_examples 'open chat with button'
      include_examples 'chat button is hidden after idle timeout'
    end
  end

  describe "Chat can't be closed after timeout #2471", authenticated_as: :authenticate do
    shared_examples 'test issue #2471' do
      it 'is able to close to the dialog after a idleTimeout happened' do
        click agent_chat_switch_selector
        using_session :customer do

          visit chat_url
          click '.zammad-chat .js-chat-open'
          expect(page).to have_selector('.js-restart', wait: 60)
          click '.js-chat-toggle .zammad-chat-header-icon'
          expect(page).to have_no_selector('zammad-chat-is-open', wait: 60)
        end
      end
    end

    before do
      visit '/'
    end

    context 'with jquery' do
      include_examples 'test issue #2471'
    end

    context 'without jquery' do
      let(:chat_url_type) { 'znuny-no-jquery' }

      include_examples 'test issue #2471'
    end
  end

  context 'when image is present in chat message', authenticated_as: :authenticate do
    let(:chat) { create(:chat) }
    let(:chat_user)    { create(:agent) }
    let(:chat_session) { create(:'chat/session', user: chat_user, chat: chat) }

    before do
      file     = Rails.root.join('spec/fixtures/files/image/squares.png').binread
      base64   = Base64.encode64(file).delete("\n")

      create(
        :'chat/message',
        chat_session: chat_session,
        content:      "With inline image: <img src='data:image/png;base64,#{base64}' style='width: 100%; max-width: 460px;'>"
      )
    end

    context 'when image preview is used' do
      it 'use image preview' do
        visit "#customer_chat/session/#{chat_session.id}"

        find('.chat-body .chat-message img') { |elem| ActiveModel::Type::Boolean.new.cast elem[:complete] }
          .click

        in_modal do
          expect(page).to have_css('.js-submit', text: 'Download')
        end
      end
    end
  end
end
