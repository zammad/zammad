# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Configuration do
  describe '.verify!' do
    let(:channel) do
      options = {
        secret:            Faker::Crypto.sha256,
        verify_token:      Faker::Crypto.sha256,
        callback_url_uuid: Faker::Number.unique.number(digits: 15),
      }

      create(:channel, area: 'WhatsApp::Business', options: options)
    end

    let(:options) do
      {
        callback_url_uuid:  channel.options['callback_url_uuid'],
        'hub.mode':         'subscribe',
        'hub.challenge':    Faker::Number.unique.number(digits: 10),
        'hub.verify_token': channel.options['verify_token'],
      }
    end

    context 'when channel not exists' do
      it 'raises NoChannelError' do
        options[:callback_url_uuid] = 0
        expect { described_class.new(options:).verify! }.to raise_error(Whatsapp::Webhook::NoChannelError)
      end
    end

    context 'when no WhatsApp channel is referenced' do
      it 'raises NoChannelError' do
        options.delete(:callback_url_uuid)
        expect { described_class.new(options:).verify! }.to raise_error(Whatsapp::Webhook::NoChannelError)
      end
    end

    context 'when existing channel is using wrong area' do
      it 'raises NoChannelError' do
        channel.update!(area: 'foobar')

        expect { described_class.new(options:).verify! }.to raise_error(Whatsapp::Webhook::NoChannelError)
      end
    end

    context 'when hub.mode is not subscribe' do
      it 'raises VerificationError' do
        options[:'hub.mode'] = 'unsubscribe'
        expect { described_class.new(options:).verify! }.to raise_error(described_class::VerificationError)
      end
    end

    context 'when hub.challenge is not a number' do
      it 'raises VerificationError' do
        options[:'hub.challenge'] = 'foobar'
        expect { described_class.new(options:).verify! }.to raise_error(described_class::VerificationError)
      end
    end

    context 'when hub.verify_token is not valid' do
      it 'raises VerificationError' do
        options[:'hub.verify_token'] = 'foobar'
        expect { described_class.new(options:).verify! }.to raise_error(described_class::VerificationError)
      end
    end

    context 'when all options are valid' do
      it 'returns hub.challenge' do
        expect(described_class.new(options:).verify!).to eq(options[:'hub.challenge'])
      end
    end
  end
end
