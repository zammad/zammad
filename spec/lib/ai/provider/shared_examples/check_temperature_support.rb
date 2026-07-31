# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'provider/check_temperature_support' do
  describe '.check_temperature_support!' do
    let(:provider_config) { default_ai_provider_config }

    context 'when API accepts temperature' do
      before do
        allow(UserAgent).to receive(:post).and_return(
          UserAgent::Result.new(
            success: true,
            code:    200,
            data:    {},
          )
        )
      end

      it 'returns true' do
        expect(described_class.check_temperature_support!(provider_config)).to be true
      end
    end

    context 'when API rejects temperature' do
      before do
        allow(UserAgent).to receive(:post).and_return(
          UserAgent::Result.new(
            body:    '{ "error": { "message": "Unsupported value: \'temperature\' does not support 0.1 with this model. Only the default (1) value is supported.", "type": "invalid_request_error", "param":  "temperature", "code": "unsupported_value" } }',
            success: false,
            code:    400,
          )
        )
      end

      it 'returns false' do
        expect(described_class.check_temperature_support!(provider_config)).to be false
      end
    end

    context 'when an exception occurs' do
      before do
        allow(UserAgent).to receive(:post).and_raise(StandardError, 'connection error')
      end

      it 'raises an error' do
        expect { described_class.check_temperature_support!(provider_config) }.to raise_error(AI::Provider::CheckTemperatureSupportError, 'connection error')
      end
    end
  end
end
