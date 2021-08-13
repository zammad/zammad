# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Chat Handling', type: :system do
  let(:agent_chat_switch_selector) { '#navigation .js-chatMenuItem .js-switch' }
  let(:chat_url) { "/assets/chat/znuny_open_by_button.html?port=#{ENV['WS_PORT']}" }

  def authenticate
    Setting.set('chat', true)
    true
  end

  shared_examples 'chat button is hidden after idle timeout' do
    it 'Check that button is hidden after idle timeout', authenticated_as: :authenticate do
      click agent_chat_switch_selector

      open_window_and_switch

      visit chat_url

      expect(page).to have_css('.zammad-chat', visible: :all)
      expect(page).to have_css('.zammad-chat-is-hidden', visible: :all)
      expect(page).to have_no_css('.open-zammad-chat:not([style*="display: none"]', visible: :all, wait: 20)
    end
  end

  context 'when jquery variant is used' do
    include_examples 'chat button is hidden after idle timeout'
  end

  context 'when none jquery variant is used' do
    let(:chat_url) { "/assets/chat/znuny-no-jquery-open_by_button.html?port=#{ENV['WS_PORT']}" }

    include_examples 'chat button is hidden after idle timeout'
  end
end
