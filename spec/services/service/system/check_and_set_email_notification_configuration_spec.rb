# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::System::CheckAndSetEmailNotificationConfiguration do
  subject(:service_result) { described_class.execute(adapter:, new_configuration:, test_address:) }

  let(:adapter)      { 'smtp' }
  let(:test_address) { nil }
  let(:sender)       { Setting.get('notification_sender') }
  let(:probe_result) { { result: 'ok' } }

  let(:new_configuration) do
    {
      host:       'smtp.example.com',
      port:       587,
      user:       'some@example.com',
      password:   'password',
      ssl_verify: true,
    }
  end

  let(:refusal) do
    {
      result:        'invalid',
      message:       'smtp.example.com: 554 5.7.1 Relay access denied',
      message_human: nil,
      invalid_field: {},
      refused:       true,
    }
  end

  let(:failure) do
    {
      result:        'invalid',
      message:       'Authentication on smtp.example.com failed: 535 5.7.8 authentication failed',
      message_human: 'Authentication failed.',
      invalid_field: { user: true, password: true },
    }
  end

  before do
    allow(EmailHelper::Probe).to receive(:outbound).and_return(probe_result)
  end

  def channel_by_adapter(adapter)
    Channel
      .where(area: 'Email::Notification')
      .to_a
      .find { it.options.dig(:outbound, :adapter) == adapter }
  end

  def saved_configuration
    Channel.where(area: 'Email::Notification').reorder(:id).map { [it.active, it.options] }
  end

  shared_examples 'saving the configuration' do |internal_only:|
    it 'saves the configuration' do
      service_result

      expect(channel_by_adapter(adapter)).to have_attributes(
        active:  true,
        options: include(
          outbound: include(
            adapter:       adapter,
            options:       include(host: 'smtp.example.com', password: 'password'),
            internal_only: internal_only,
          ),
        ),
      )
    end
  end

  shared_examples 'not saving the configuration' do
    it 'does not save the configuration' do
      expect { service_result }.not_to change { saved_configuration }
    end
  end

  context 'without a test address' do
    context 'when the server accepts the test mail' do
      it { is_expected.to eq(result: 'ok') }

      it_behaves_like 'saving the configuration', internal_only: false

      it 'sends the test mail of the usual check from the notification sender' do
        service_result

        expect(EmailHelper::Probe).to have_received(:outbound).once.with(
          include(adapter: 'smtp', options: include(host: 'smtp.example.com', password: 'password')),
          sender,
          system_bcc: false,
        )
      end

      context 'when the sender was saved as internal-only before' do
        before do
          Service::System::SetEmailNotificationConfiguration.execute(adapter:, new_configuration:, internal_only: true)
        end

        it_behaves_like 'saving the configuration', internal_only: false
      end

      context 'when the configuration claims to be internal-only' do
        let(:new_configuration) { super().merge(internal_only: true) }

        it_behaves_like 'saving the configuration', internal_only: false
      end

      context 'when the configuration has string keys' do
        let(:new_configuration) { super().stringify_keys }

        it_behaves_like 'saving the configuration', internal_only: false

        it 'hands the check a configuration which is readable with symbols' do
          service_result

          expect(EmailHelper::Probe).to have_received(:outbound).with(
            include(adapter: 'smtp', options: include(host: 'smtp.example.com', port: 587)),
            sender,
            system_bcc: false,
          )
        end
      end

      context 'when the check changes the configuration it got' do
        before do
          allow(EmailHelper::Probe).to receive(:outbound) do |configuration, *|
            configuration[:options][:domain] = 'zammad.example.com'

            probe_result
          end
        end

        shared_examples 'saving the configuration as it was given' do
          it 'saves the configuration as it was given' do
            service_result

            expect(channel_by_adapter(adapter).options.dig(:outbound, :options)).not_to include(:domain)
          end
        end

        it_behaves_like 'saving the configuration as it was given'

        context 'when the configuration is an indifferent access hash' do
          let(:new_configuration) { super().with_indifferent_access }

          it_behaves_like 'saving the configuration as it was given'
        end
      end
    end

    context 'when the server refuses the test mail' do
      let(:probe_result) { refusal }

      it 'returns the refusal' do
        expect(service_result).to include(result: 'invalid', refused: true, message: refusal[:message])
      end

      it_behaves_like 'not saving the configuration'
    end

    context 'when the check fails' do
      let(:probe_result) { failure }

      it { is_expected.to eq(failure) }

      it_behaves_like 'not saving the configuration'
    end

    context 'when the test address is blank' do
      let(:test_address) { ' ' }

      it_behaves_like 'saving the configuration', internal_only: false

      it 'runs the usual check' do
        service_result

        expect(EmailHelper::Probe).to have_received(:outbound).with(anything, sender, system_bcc: false)
      end
    end
  end

  context 'with a test address' do
    let(:test_address) { 'admin@example.com' }

    context 'when the server accepts the test mail' do
      it { is_expected.to eq(result: 'ok') }

      it_behaves_like 'saving the configuration', internal_only: true

      it 'sends the test mail to the test address only' do
        service_result

        expect(EmailHelper::Probe).to have_received(:outbound).once.with(
          include(adapter: 'smtp', options: include(host: 'smtp.example.com')),
          sender,
          recipient:  'admin@example.com',
          system_bcc: false,
        )
      end

      it 'does not save the test address' do
        service_result

        expect(channel_by_adapter(adapter).options.to_json).not_to include('admin@example.com')
      end
    end

    context 'when the server refuses the test mail' do
      let(:probe_result) { refusal }

      it 'returns a failure without the refusal marker' do
        expect(service_result).to eq(refusal.except(:refused))
      end

      it_behaves_like 'not saving the configuration'
    end

    context 'when the check fails' do
      let(:probe_result) { failure }

      it { is_expected.to eq(failure) }

      it_behaves_like 'not saving the configuration'
    end

    context 'when the test address is no email address' do
      let(:test_address) { 'admin' }

      it 'returns a failure for the test address' do
        expect(service_result).to include(
          result:        'invalid',
          message_human: 'Please enter a valid email address.',
          invalid_field: { test_address: true },
        )
      end

      it 'sends no test mail' do
        service_result

        expect(EmailHelper::Probe).not_to have_received(:outbound)
      end

      it_behaves_like 'not saving the configuration'
    end

    context 'when the test address is on a host without a domain' do
      let(:test_address) { 'helpdesk@mailhost' }

      it 'sends the test mail to it' do
        service_result

        expect(EmailHelper::Probe).to have_received(:outbound).with(anything, sender, hash_including(recipient: 'helpdesk@mailhost'))
      end

      it_behaves_like 'saving the configuration', internal_only: true
    end

    context 'when the adapter is sendmail' do
      let(:adapter)           { 'sendmail' }
      let(:new_configuration) { {} }

      it 'runs the usual check' do
        service_result

        expect(EmailHelper::Probe).to have_received(:outbound).with(include(adapter: 'sendmail'), sender, system_bcc: false)
      end

      it 'saves the sender without the internal-only flag' do
        service_result

        expect(channel_by_adapter('sendmail')).to have_attributes(
          active:  true,
          options: include(outbound: include(internal_only: false)),
        )
      end
    end
  end
end
