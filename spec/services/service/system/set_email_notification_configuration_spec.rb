# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::System::SetEmailNotificationConfiguration do
  subject(:service_result) { described_class.execute(adapter:, new_configuration:) }

  context 'when adapter is sendmail' do
    let(:adapter)           { 'sendmail' }
    let(:new_configuration) { nil }

    before do
      channel_by_adapter('sendmail').update!(active: false)
      channel_by_adapter('smtp').update!(active: true)

      service_result
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
    before { service_result }

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

  context 'when adapter is microsoft_graph_outbound without auth data' do
    it 'raises ArgumentError' do
      expect do
        described_class.execute(
          adapter:           'microsoft_graph_outbound',
          new_configuration: { user: 'user@example.com' },
        )
      end.to raise_error(ArgumentError, /microsoft_graph_auth/)
    end
  end

  context 'when adapter is microsoft_graph_outbound' do
    let(:auth_data) do
      {
        access_token:  'test_access_token',
        refresh_token: 'test_refresh_token',
        provider:      'microsoft_graph',
        type:          'XOAUTH2',
        client_id:     'test_client_id',
        client_secret: 'test_client_secret',
        created_at:    Time.zone.now,
      }
    end

    before do
      described_class.execute(
        adapter:              'microsoft_graph_outbound',
        new_configuration:    { user: 'user@example.com' },
        microsoft_graph_auth: auth_data,
      )
    end

    it 'sets microsoft_graph_outbound to active with auth and outbound options' do
      expect(channel_by_adapter('microsoft_graph_outbound'))
        .to have_attributes(
          active:       true,
          status_out:   'ok',
          last_log_out: nil,
          options:      include(
            outbound: include(
              adapter: 'microsoft_graph_outbound',
              options: include(
                user:     'user@example.com',
                password: 'test_access_token',
              ),
            ),
            auth: include(
              provider: 'microsoft_graph',
            ),
          ),
        )
    end

    it 'sets smtp to inactive' do
      expect(channel_by_adapter('smtp'))
        .to have_attributes(active: false)
    end

    it 'sets sendmail to inactive' do
      expect(channel_by_adapter('sendmail'))
        .to have_attributes(active: false)
    end

    context 'with shared mailbox' do
      before do
        described_class.execute(
          adapter:              'microsoft_graph_outbound',
          new_configuration:    { user: 'user@example.com', shared_mailbox: 'shared@example.com' },
          microsoft_graph_auth: auth_data,
        )
      end

      it 'stores shared mailbox in outbound options' do
        expect(channel_by_adapter('microsoft_graph_outbound').options.dig(:outbound, :options, :shared_mailbox))
          .to eq('shared@example.com')
      end
    end

    context 'when switching back to smtp' do
      before do
        described_class.execute(
          adapter:           'smtp',
          new_configuration: {
            host: 'smtp.example.com', port: 25, ssl: true,
            user: 'some@example.com', password: 'password',
          },
        )
      end

      it 'sets smtp to active' do
        expect(channel_by_adapter('smtp'))
          .to have_attributes(active: true)
      end

      it 'sets microsoft_graph_outbound to inactive' do
        expect(channel_by_adapter('microsoft_graph_outbound'))
          .to have_attributes(active: false)
      end
    end
  end

  def channel_by_adapter(adapter)
    Channel
      .where(area: 'Email::Notification')
      .to_a
      .find { it.options.dig(:outbound, :adapter) == adapter }
  end
end
