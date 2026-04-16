# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'provider/model_supports_temperature' do
  describe 'temperature support flag' do
    let(:prompt_system) { '' }
    let(:prompt_user)   { 'Hi' }

    before do
      allow(UserAgent).to receive(:post).and_return(
        UserAgent::Result.new(
          success: true,
          code:    200,
          data:    chat_response_data,
        )
      )
    end

    context 'when model_temperature_support is false' do
      before do
        Setting.set('ai_provider_config', Setting.get('ai_provider_config').merge(model_temperature_support: false), validate: false)
      end

      it 'does not include temperature in the request', :aggregate_failures do
        subject.ask(prompt_system:, prompt_user:)

        request_body = nil
        expect(UserAgent).to have_received(:post) do |_url, body, _options|
          request_body = body
        end

        expect(request_body).not_to include(:temperature)
        expect(request_body.dig(:options, :temperature)).to be_nil if request_body.key?(:options)
      end
    end
  end
end
