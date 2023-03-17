# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Telegram', integration: true, required_envs: %w[TELEGRAM_TOKEN], type: :system do
  before { visit '/#channels/telegram' }

  it 'does connect and add the token' do
    Setting.set('fqdn', 'example.com')
    Setting.set('http_type', 'https')
    page.find('.js-new').click
    page.find('#api_token').set(ENV['TELEGRAM_TOKEN'])
    page.find('#welcome').set('hii')
    page.find('#goodbye').set('cyaa')
    page.find('.js-submit').click
    expect(page).to have_text('ZammadCIBot')
  end
end
