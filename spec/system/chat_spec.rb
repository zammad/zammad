# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  # Chat.coffee's switch() decides whether to auto-activate the (single, seeded)
  #   chat topic or show a "select at least one chat topic" modal based on
  #   App.Chat.count() - if that collection hasn't finished its async load yet
  #   right after a page visit, count() is transiently 0 and the wrong modal
  #   appears, blocking whatever click follows.
  def wait_for_chat_topics_loaded
    wait.until { page.evaluate_script('App.Chat.count()') > 0 }
  end

  def enable_agent_chat
    wait_for_chat_topics_loaded

    click agent_chat_switch_selector
    click 'a[href="#customer_chat"]'
  end

  # The accept button is always present in the DOM, but Chat.coffee only marks
  #   it with .is-active once the agent has been notified of the waiting
  #   customer.
  def accept_chat
    click '.active .js-acceptChat.is-active'
  end

  def open_chat_dialog
    expect(page).to have_css('.zammad-chat')
    click '.zammad-chat .js-chat-open'
    expect(page).to have_css('.zammad-chat-is-shown')
  end

  # Closing the chat widget reconnects its websocket (onCloseAnimationEnd ->
  #   io.reconnect()), but the widget's Io#send passes messages to ws.send
  #   without checking readyState - a chat_session_init fired while the new
  #   socket is still connecting is lost for good and no agent ever gets
  #   notified. Wait for the reconnect to finish before reopening the dialog.
  def wait_for_widget_websocket_open
    wait.until { page.evaluate_script('chat.io.ws.readyState') == 1 }
  end

  def send_customer_message(message)
    find('.zammad-chat .zammad-chat-input').send_keys(message)
    click '.zammad-chat .zammad-chat-send'
  end

  def send_agent_message(message)
    find('.active .chat-window .js-customerChatInput').send_keys(message)

    # Wait until the message is verifiably present in the input before clicking
    #   send, because ChatWindow#sendMessage silently sends nothing when the
    #   input is empty at the time of the click.
    #   send_keys sometimes fails to type into the contenteditable input at all
    #   (observed on Firefox headless, but not provably limited to it) - that is
    #   a failure of the test tooling, not product behavior, so set the text
    #   directly in that case regardless of the driver.
    wait.until do
      input = find('.active .chat-window .js-customerChatInput')
      input.execute_script('this.textContent = arguments[0]', message) if input.text != message
      input.text == message
    end

    # The send is deliberately clicked only once: a message that gets lost
    #   although it was present in the input is a product bug that has to
    #   surface here instead of being papered over by retyping and resending.
    click '.active .chat-window .js-send'
    expect(page).to have_css('.active .chat-window .chat-message--agent', text: message)
  end

  shared_examples 'chat button is hidden after idle timeout' do
    it 'check that button is hidden after idle timeout', authenticated_as: :authenticate do
      wait_for_chat_topics_loaded
      click agent_chat_switch_selector

      using_session :customer do
        visit chat_url

        expect(page).to have_css('.zammad-chat', visible: :all)
        expect(page).to have_css('.zammad-chat-is-hidden', visible: :all)
        expect(page).to have_no_css('.open-zammad-chat:not([style*="display: none"])', visible: :all)
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

      accept_chat

      # Wait for the chat window to render after accepting before checking its content.
      # have_no_css passes immediately when the window hasn't rendered yet, so check
      # for presence first to avoid a false-positive synchronisation point.
      expect(page).to have_css('.active .chat-window .js-body')
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

      accept_chat

      # Same false-positive risk as in the agent-side test: have_no_css passes
      # immediately before the window renders, so wait for the body first.
      expect(page).to have_css('.active .chat-window .js-body')
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

        wait_for_widget_websocket_open

        open_chat_dialog
      end

      accept_chat

      expect(page).to have_css('.active .chat-window .js-body')
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

      accept_chat

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

      accept_chat

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

      enable_agent_chat

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

      accept_chat

      expect(page).to have_css('.active .chat-window .chat-status')

      using_session :customer do
        check_content('.zammad-chat', %r{(Hi Stranger|My Greeting)})
      end

      send_agent_message('my name is me')

      using_session :customer do

        check_content('.zammad-chat', 'my name is me')

        refresh

        # After a page refresh the chat session reconnects automatically via
        # WebSocket. The content checks below already wait for the element, so
        # the standalone existence assertion is redundant and can race in CI.
        check_content('.zammad-chat', %r{(Hi Stranger|My Greeting)})
        check_content('.zammad-chat', 'my name is me')

        visit "#{chat_url}#new_hash"
      end

      check_content('.active .chat-window .js-body', "#{chat_url}#new_hash")

      # Close the conversation instead of leaving it active - otherwise the customer
      #   session gets torn down mid-chat by the after-each hook (rather than a clean
      #   UI close), which can leave the conversation looking still active server-side
      #   and intermittently block a later test's chat interactions with a stray modal.
      using_session :customer do
        click '.js-chat-toggle .zammad-chat-header-icon'
      end

      check_content('.active .chat-window', 'closed the conversation')
    end
  end

  context 'when hovering over the active agents info' do
    it 'shows the avatar of the active agent', authenticated_as: :authenticate do
      visit '/'

      enable_agent_chat

      expect(page).to have_css('.active .js-activeAgents .js-badgeActiveAgents', text: '1')

      find('.active .js-activeAgents .js-info').hover

      # The avatar is positioned via an inline style - Bootstrap's popover sanitizer
      #   strips that attribute unless sanitizing is disabled, leaving a blank avatar.
      expect(page).to have_css('.popover .userList-entry .avatar[style]')
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
        wait_for_chat_topics_loaded
        click agent_chat_switch_selector
        using_session :customer do

          visit chat_url
          click '.zammad-chat .js-chat-open'
          expect(page).to have_css('.js-restart', wait: 60)
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
