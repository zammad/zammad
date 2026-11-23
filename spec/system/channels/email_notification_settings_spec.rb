# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Email > Notification sender settings', type: :system do
  let(:smtp_configuration) { { host: 'smtp.example.com', user: 'zammad', password: 'secret' } }

  def notification_block
    channel = Channel.find_by(area: 'Email::Notification', active: true)

    find(".action[data-id='#{channel.id}'] table.key-value")
  end

  before do
    setup

    visit '#channels/email'
  end

  context 'when the sender was verified with an address of the admin' do
    let(:setup) do
      Service::System::SetEmailNotificationConfiguration.execute(adapter: 'smtp', new_configuration: smtp_configuration, internal_only: true)
    end

    it 'shows the sender as internal-only' do
      expect(notification_block).to have_css('tr', text: %r{Internal email server\s+yes})
    end
  end

  context 'when the sender passed the usual check' do
    let(:setup) do
      Service::System::SetEmailNotificationConfiguration.execute(adapter: 'smtp', new_configuration: smtp_configuration)
    end

    it 'shows no mark' do
      expect(notification_block).to have_css('tr', text: %r{Protocol\s+smtp})
        .and have_no_text('Internal email server')
    end
  end

  context 'when the sender uses sendmail' do
    let(:setup) do
      Service::System::SetEmailNotificationConfiguration.execute(adapter: 'sendmail', new_configuration: {})
    end

    it 'shows the protocol only' do
      expect(notification_block).to have_css('tr', text: %r{Protocol\s+sendmail})
        .and have_no_text('Internal email server')
        .and have_no_text('User')
        .and have_no_text('Host')
    end
  end
end
