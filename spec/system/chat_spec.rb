# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Chat Handling', type: :system do
  let(:agent_chat_switch_selector) { '#navigation .js-chatMenuItem .js-switch' }
  let(:chat_url) { "/assets/chat/#{chat_url_type}.html?port=#{ENV['WS_PORT']}" }
  let(:chat_url_type) { 'znuny' }

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
    find('.active .chat-window .js-customerChatInput').send_keys(message)
    click '.active .chat-window .js-send'
  end

  shared_examples 'chat button is hidden after idle timeout' do
    it 'check that button is hidden after idle timeout', authenticated_as: :authenticate do
      click agent_chat_switch_selector

      open_window_and_switch

      visit chat_url

      expect(page).to have_css('.zammad-chat', visible: :all)
      expect(page).to have_css('.zammad-chat-is-hidden', visible: :all)
      expect(page).to have_no_css('.open-zammad-chat:not([style*="display: none"]', visible: :all, wait: 20)
    end
  end

  shared_examples 'chat messages' do
    it 'messages in each direction, starting on agent side', authenticated_as: :authenticate do
      enable_agent_chat

      open_window_and_switch

      visit chat_url

      open_chat_dialog

      switch_to_window_index(1)

      click '.active .js-acceptChat'

      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')
      check_content('.active .chat-window .js-body', chat_url)

      send_agent_message('my name is me')

      switch_to_window_index(2)

      check_content('.zammad-chat .zammad-chat-agent-status', 'Online')
      check_content('.zammad-chat', 'my name is me')

      send_customer_message('my name is customer')

      switch_to_window_index(1)

      check_content('.active .chat-window', 'my name is customer')
      expect(page).to have_css('.active .chat-window .chat-status.is-modified')

      click '.active .chat-window .js-customerChatInput'

      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')

      switch_to_window_index(2)

      click '.js-chat-toggle .zammad-chat-header-icon'

      switch_to_window_index(1)

      check_content('.active .chat-window', 'closed the conversation')
    end

    it 'messages in each direction, starting on customer side', authenticated_as: :authenticate do
      enable_agent_chat

      open_window_and_switch

      visit chat_url

      open_chat_dialog

      switch_to_window_index(1)

      click '.active .js-acceptChat'

      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')

      # Keep focus outside of chat window to check .chat-status.is-modified later.
      click '#global-search'

      switch_to_window_index(2)

      check_content('.zammad-chat .zammad-chat-agent-status', 'Online')

      send_customer_message('my name is customer')

      switch_to_window_index(1)

      expect(page).to have_css('.active .chat-window .chat-status.is-modified')
      check_content('.active .chat-window', 'my name is customer')

      send_agent_message('my name is me')
      expect(page).to have_no_css('.active .chat-window .chat-status.is-modified')

      switch_to_window_index(2)

      check_content('.zammad-chat', 'my name is me')

      switch_to_window_index(1)

      click '.active .chat-window .js-disconnect:not(.is-hidden)'
      click '.active .chat-window .js-close'

      switch_to_window_index(2)

      check_content('.zammad-chat .zammad-chat-agent-status', 'Offline')
      check_content('.zammad-chat', %r{(Chat closed by|Chat beendet von)})

      click '.zammad-chat .js-chat-toggle .zammad-chat-header-icon'

      expect(page).to have_no_css('.zammad-chat-is-open')

      open_chat_dialog

      switch_to_window_index(1)

      click '.active .js-acceptChat'

      expect(page).to have_css('.active .chat-window .chat-status')
    end
  end

  shared_examples 'open chat with button' do
    it 'open the chat', authenticated_as: :authenticate do
      enable_agent_chat

      open_window_and_switch

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

  shared_examples 'timeouts' do
    it 'check different timeouts', authenticated_as: :authenticate do
      enable_agent_chat

      open_window_and_switch

      visit chat_url

      # No customer action, hide the widget.
      expect(page).to have_css('.zammad-chat')

      expect(page).to have_no_css('.zammad-chat', wait: 20)

      refresh

      # No agent action, show sorry screen.
      open_chat_dialog

      check_content('.zammad-chat-modal-text', %r{(waiting|Warte)})
      check_content('.zammad-chat-modal-text', %r{(takes longer|dauert länger)}, wait: 20)

      refresh

      # No customer action, show sorry screen.
      open_chat_dialog

      switch_to_window_index(1)

      click '.active .js-acceptChat'

      send_agent_message('agent is asking')

      switch_to_window_index(2)

      check_content('.zammad-chat', 'agent is asking')

      check_content('.zammad-chat-modal-text', %r{(Since you didn't respond|Da Sie in den letzten)}, wait: 30)

      # Test the restart of inactive chat.
      switch_to_window_index(1)

      click '.active .chat-window .js-close'

      switch_to_window_index(2)

      click '.js-restart'

      open_chat_dialog

      switch_to_window_index(1)

      click '.active .js-acceptChat'

      send_agent_message('my name is me')

      switch_to_window_index(2)

      check_content('.zammad-chat', 'my name is me')
    end
  end

  context 'when chat is activated or disabled' do
    it 'switch the chat setting', authenticated_as: :authenticate do
      visit '/#channels/chat'

      click '.content.active .js-chatSetting'

      expect(page).to have_no_css(agent_chat_switch_selector)

      open_window_and_switch

      visit chat_url

      check_content('.settings', '{"state":"chat_disabled"}')

      switch_to_window_index(1)

      click '.content.active .js-chatSetting'

      expect(page).to have_css(agent_chat_switch_selector)

      switch_to_window_index(2)

      refresh

      expect(page).to have_no_css('.zammad-chat')
      check_content('.settings', '{"state":"chat_disabled"}', should_match: false)
      check_content('.settings', '{"event":"chat_status_customer","data":{"state":"offline"}}')

      switch_to_window_index(1)

      click agent_chat_switch_selector
      click 'a[href="#customer_chat"]'

      switch_to_window_index(2)

      refresh

      expect(page).to have_css('.zammad-chat')
      check_content('.settings', '{"event":"chat_status_customer","data":{"state":"offline"}}', should_match: false)
      check_content('.settings', '{"state":"online"}')

      click '.zammad-chat .js-chat-open'

      expect(page).to have_css('.zammad-chat-is-shown')
      check_content('.zammad-chat-modal-text', %r{(waiting|Warte)})

      switch_to_window_index(1)

      check_content('.js-chatMenuItem .counter', '1')

      switch_to_window_index(2)

      click '.zammad-chat .js-chat-toggle .zammad-chat-header-icon'

      check_content('.zammad-chat-modal-text', %r{(waiting|Warte)}, should_match: false)

      switch_to_window_index(1)

      expect(page).to have_no_css('.js-chatMenuItem .counter')
    end
  end

  context 'when changing chat preferences for current agent' do
    it 'use chat phrase preference', authenticated_as: :authenticate do
      enable_agent_chat

      click '.active .js-settings'

      modal_ready

      find('.modal [name="chat::phrase::1"]').send_keys('Hi Stranger!;My Greeting')
      click '.modal .js-submit'

      modal_disappear

      open_window_and_switch

      visit chat_url

      open_chat_dialog

      switch_to_window_index(1)

      click '.active .js-acceptChat'

      expect(page).to have_css('.active .chat-window .chat-status')

      switch_to_window_index(2)

      check_content('.zammad-chat', %r{(Hi Stranger|My Greeting)})

      switch_to_window_index(1)

      send_agent_message('my name is me')

      switch_to_window_index(2)

      check_content('.zammad-chat', 'my name is me')

      refresh

      expect(page).to have_css('.zammad-chat')
      check_content('.zammad-chat', %r{(Hi Stranger|My Greeting)})
      check_content('.zammad-chat', 'my name is me')

      visit "#{chat_url}#new_hash"

      switch_to_window_index(1)

      check_content('.active .chat-window .js-body', "#{chat_url}#new_hash")
    end
  end

  context 'when jquery variant is used' do
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

  context 'when none jquery variant is used' do
    let(:chat_url_type) { 'znuny-no-jquery' }

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
        open_window_and_switch

        visit chat_url
        click '.zammad-chat .js-chat-open'
        expect(page).to have_selector('.js-restart', wait: 60)
        click '.js-chat-toggle .zammad-chat-header-icon'
        expect(page).to have_no_selector('zammad-chat-is-open', wait: 60)
      end
    end

    context 'with jquery' do
      include_examples 'test issue #2471'
    end

    context 'wihtout jquery' do
      let(:chat_url_type) { 'znuny-no-jquery' }

      include_examples 'test issue #2471'
    end
  end
end
