# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::AIProviderConfig do

  let(:setting_name) { 'ai_provider_config' }

  context 'with blank settings' do
    it 'does not raise error' do
      expect { Setting.set(setting_name, {}) }.not_to raise_error
    end

    context 'when config is present but provider is missing' do
      it 'raises error' do
        expect { Setting.set(setting_name, { url: 'http://ai.example.com' }) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  context 'with unsupported provider' do
    it 'raises error' do
      expect { Setting.set(setting_name, { provider: 'unsupported' }) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when provider is ollama' do
    let(:config) { { provider: 'ollama', url: } }

    before do
      allow(AI::Provider::Ollama).to receive(:ping!).and_return(true)
    end

    context 'with missing url' do
      let(:url) { nil }

      it 'raises error' do
        expect { Setting.set(setting_name, config) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with valid url' do
      let(:url) { 'https://ollama.ai' }

      it 'does not raise error' do
        expect { Setting.set(setting_name, config) }
          .not_to raise_error
      end
    end
  end

  context 'when provider is ZammadAI' do
    let(:config)    { { provider: 'zammad_ai', token: } }
    let(:env_value) { nil }

    before do
      allow(UserAgent).to receive(:get) do |_, _, options|
        success = options[:bearer_token] == 'valid'

        UserAgent::Result.new(
          error:   '',
          success:,
          code:    success ? 200 : 400,
        )
      end
    end

    around do |example|
      old_env = ENV['ZAMMAD_AI_TOKEN']
      ENV['ZAMMAD_AI_TOKEN'] = env_value

      example.run

      ENV['ZAMMAD_AI_TOKEN'] = old_env
    end

    context 'with missing token' do
      let(:token) { nil }

      it 'raises error' do
        expect { Setting.set(setting_name, config) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with valid token' do
      let(:token) { 'valid' }

      it 'does not raise error' do
        expect { Setting.set(setting_name, config) }
          .not_to raise_error
      end
    end

    context 'with invalid token' do
      let(:token) { 'invalid_token' }

      it 'raises error' do
        expect { Setting.set(setting_name, config) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when in SaaS' do
      before do
        Setting.set('system_online_service', true)
      end

      context 'when ENV variable is present' do
        let(:env_value) { 'valid' }

        context 'with missing token' do
          let(:token) { nil }

          it 'does not raise error' do
            expect { Setting.set(setting_name, config) }
              .not_to raise_error
          end
        end

        context 'with valid token' do
          let(:token) { 'valid' }

          it 'does not raise error' do
            expect { Setting.set(setting_name, config) }
              .not_to raise_error
          end
        end

        context 'with invalid token' do
          let(:token) { 'invalid_token' }

          it 'does not raise error' do
            expect { Setting.set(setting_name, config) }
              .not_to raise_error
          end
        end
      end

      context 'when ENV variable is missing' do
        let(:env_value) { nil }

        context 'with missing token' do
          let(:token) { nil }

          it 'does not raise error' do
            expect { Setting.set(setting_name, config) }
              .to raise_error(ActiveRecord::RecordInvalid)
          end
        end

        context 'with valid token' do
          let(:token) { 'valid' }

          it 'does not raise error' do
            expect { Setting.set(setting_name, config) }
              .not_to raise_error
          end
        end

        context 'with invalid token' do
          let(:token) { 'invalid_token' }

          it 'raises error' do
            expect { Setting.set(setting_name, config) }
              .to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end
    end
  end

  context 'when provider is not ollama' do
    let(:config) { { provider: 'open_ai', token: } }

    before do
      allow(AI::Provider::OpenAI).to receive(:ping!).with(hash_including(token:)) do |hash|
        next if hash[:token] == 'valid'

        raise AI::Provider::ResponseError, 'API server not accessible'
      end
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_return(true)
    end

    context 'with missing token' do
      let(:token) { nil }

      it 'raises error' do
        expect { Setting.set(setting_name, config) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with valid token' do
      let(:token) { 'valid' }

      it 'does not raise error' do
        expect { Setting.set(setting_name, config) }
          .not_to raise_error
      end
    end

    context 'with invalid token' do
      let(:token) { 'invalid_token' }

      it 'raises error' do
        expect { Setting.set(setting_name, config) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'temperature support check' do
    let(:config) { { provider: 'open_ai', token: 'valid' } }

    before do
      allow(AI::Provider::OpenAI).to receive(:ping!)
    end

    context 'when temperature is supported' do
      before do
        allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_return(true)
      end

      it 'persists model_temperature_support as true' do
        Setting.set(setting_name, config)

        expect(Setting.get(setting_name)).to include('model_temperature_support' => true)
      end
    end

    context 'when temperature is not supported' do
      before do
        allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_return(false)
      end

      it 'persists model_temperature_support as false' do
        Setting.set(setting_name, config)

        expect(Setting.get(setting_name)).to include('model_temperature_support' => false)
      end
    end

    context 'when temperature check raises an error' do
      before do
        allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_raise(AI::Provider::CheckTemperatureSupportError, 'check failed')
      end

      it 'does cause validation failure' do
        expect { Setting.set(setting_name, config) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'calls check_temperature_support! after successful ping' do
      allow(AI::Provider::OpenAI).to receive(:check_temperature_support!).and_return(true)

      Setting.set(setting_name, config)

      expect(AI::Provider::OpenAI).to have_received(:check_temperature_support!)
    end
  end
end
