# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::ProviderConnection::TestConnection do
  describe '#execute' do
    before do
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_return(true)
    end

    it 'returns the detected temperature support' do
      expect(described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })).to be(true)
    end

    it 'raises for an unknown provider' do
      expect { described_class.execute(provider: 'does_not_exist', incoming_config: {}) }
        .to raise_error(Exceptions::UnprocessableContent)
    end

    it 'validates the config that will be stored: mask sentinels restored, blanks dropped' do
      described_class.execute(
        provider:        'open_ai',
        incoming_config: { 'token' => SensitiveParamsHelper::SENSITIVE_MASK, 'model' => '', 'url' => 'https://example.com' },
        existing_config: { 'token' => 'real-token', 'model' => 'gpt-4o' },
      )

      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!)
        .with({ token: 'real-token', url: 'https://example.com' }, related_object: nil)
    end

    it 'validates the retained config when none was submitted (provider-only update)' do
      described_class.execute(provider: 'open_ai', existing_config: { 'token' => 'kept-token' })

      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!).with({ token: 'kept-token' }, related_object: nil)
    end

    it 'validates an explicitly emptied config as empty, not the retained one' do
      described_class.execute(provider: 'open_ai', incoming_config: {}, existing_config: { 'token' => 'kept-token' })

      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!).with({}, related_object: nil)
    end

    it 'propagates the provider error' do
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_raise(AI::Provider::ResponseError, 'boom')

      expect { described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }) }
        .to raise_error(AI::Provider::ResponseError, 'boom')
    end

    # Providers whose check_temperature_support! does not talk to the endpoint validate in ping!.
    it 'pings providers that implement the reachability check' do
      allow(AI::Provider::Mistral).to receive(:ping!)

      described_class.execute(provider: 'mistral', incoming_config: { 'token' => 'sk' })

      expect(AI::Provider::Mistral).to have_received(:ping!).with({ token: 'sk' }, related_object: nil)
    end

    # So the HTTP log of a failed test points back at the connection the admin is editing.
    it 'attributes the request to the connection being tested' do
      connection = create(:ai_provider_connection, provider: 'open_ai')

      described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }, related_object: connection)

      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!).with({ token: 'sk' }, related_object: connection)
    end
  end
end
