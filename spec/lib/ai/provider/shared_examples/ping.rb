# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'provider/ping!' do
  describe '.ping!' do
    before do
      allow(HttpLog).to receive(:create)
    end

    it 'does not raise and does not write to the log' do
      described_class.ping!(Setting.get('ai_provider_config'))
      expect(HttpLog).not_to have_received(:create)
    end

    context 'when API returns an error' do
      before do
        error_response = UserAgent::Result.new(error: '', success: false, code: 401)
        allow(UserAgent).to receive_messages(get: error_response, post: error_response)
      end

      it 'raises ResponseError with mapped error message' do
        expect { described_class.ping!(Setting.get('ai_provider_config')) }
          .to raise_error(AI::Provider::ResponseError, 'Invalid API key - please check your configuration')
      end
    end
  end
end
