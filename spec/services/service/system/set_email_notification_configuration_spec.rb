# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::System::SetEmailNotificationConfiguration do
  let(:service) { described_class.new(adapter:, new_configuration:) }

  context 'when adapter is sendmail' do
    let(:adapter) { 'sendmail' }
    let(:new_configuration) { nil }

    before do
      channel_by_adapter('sendmail').update!(active: false)
      channel_by_adapter('smtp').update!(active: true)

      service.execute
    end

    it 'sets smtp to inactive' do
      expect(channel_by_adapter('smtp'))
        .to have_attributes(
          active: false
        )
    end

    it 'sets sendmail to active' do
      expect(channel_by_adapter('sendmail'))
        .to have_attributes(
          active:       true,
          status_out:   'ok',
          last_log_out: nil
        )
    end
  end

  context 'when adapter is smtp' do
    before { service.execute }

    let(:adapter) { 'smtp' }

    let(:new_configuration) do
      {
        adapter:    'smtp',
        host:       'smtp.example.com',
        port:       25,
        ssl:        true,
        user:       'some@example.com',
        password:   'password',
        ssl_verify: false,
      }
    end

    it 'sets smtp to active and updates configuration' do
      expect(channel_by_adapter('smtp'))
        .to have_attributes(
          active:       true,
          status_out:   'ok',
          last_log_out: nil,
          options:      include(
            outbound: include(
              adapter: 'smtp',
              options: include(
                host:       'smtp.example.com',
                port:       25,
                ssl:        true,
                user:       'some@example.com',
                password:   'password',
                ssl_verify: false,
              )
            )
          )
        )
    end

    it 'sets sendmail to inactive' do
      expect(channel_by_adapter('sendmail'))
        .to have_attributes(
          active: false
        )
    end
  end

  def channel_by_adapter(adapter)
    Channel
      .where(area: 'Email::Notification')
      .to_a
      .find { _1.options.dig(:outbound, :adapter) == adapter }
  end
end
