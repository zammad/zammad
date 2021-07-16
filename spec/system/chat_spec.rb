# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Chat Handling', type: :system do
  let(:agent_chat_switch_selector) { '#navigation .js-chatMenuItem .js-switch' }

  def authenticate
    Setting.set('chat', true)
    true
  end

  it 'Check that button is hidden after idle timeout (JQuery and without JQuery variant)', authenticated_as: :authenticate do
    click agent_chat_switch_selector

    open_window_and_switch

    visit "/assets/chat/znuny_open_by_button.html?port=#{ENV['WS_PORT']}"

    expect(page).to have_css('.zammad-chat', visible: :all)
    expect(page).to have_css('.zammad-chat-is-hidden', visible: :all)
    expect(page).to have_no_css('.open-zammad-chat:not([style*="display: none"]', visible: :all)

    visit "/assets/chat/znuny-no-jquery-open_by_button.html?port=#{ENV['WS_PORT']}"

    expect(page).to have_css('.zammad-chat', visible: :all)
    expect(page).to have_css('.zammad-chat-is-hidden', visible: :all)
    expect(page).to have_no_css('.open-zammad-chat:not([style*="display: none"]', visible: :all)
  end
end
