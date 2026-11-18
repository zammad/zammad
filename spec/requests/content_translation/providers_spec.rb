# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Content translation providers', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  shared_examples 'switching the provider' do
    it 'switches the provider' do
      expect(response).to have_http_status(:ok)
      expect(json_response).to eq('success' => true)
      expect(Service::ContentTranslation::SwitchProvider).to have_received(:execute).with(provider: 'ai', active:)
    end
  end

  shared_examples 'requiring a translation administration permission' do
    context 'with the integration permission only' do
      let(:user) { create(:agent, roles: [create(:role, permission_names: %w[admin.integration])]) }

      include_examples 'switching the provider'
    end

    context 'with the AI translation permission only' do
      let(:user) { create(:agent, roles: [create(:role, permission_names: %w[admin.ai_assistance_translation])]) }

      include_examples 'switching the provider'
    end

    context 'with another administration permission' do
      let(:user) { create(:agent, roles: [create(:role, permission_names: %w[admin.ai_provider])]) }

      it 'returns forbidden without switching' do
        expect(response).to have_http_status(:forbidden)
        expect(Service::ContentTranslation::SwitchProvider).not_to have_received(:execute)
      end
    end
  end

  describe 'POST /content_translation/providers/:provider/activate' do
    let(:active) { true }

    context 'with the service answering' do
      before do
        allow(Service::ContentTranslation::SwitchProvider).to receive(:execute)

        post '/api/v1/content_translation/providers/ai/activate', as: :json
      end

      include_examples 'switching the provider'
      include_examples 'requiring a translation administration permission'
    end

    # The admin interface shows this answer as the reason the switch turned back.
    context 'with a provider that lacks its configuration' do
      before { post '/api/v1/content_translation/providers/deepl/activate', as: :json }

      it 'answers with the reason and switches nothing' do
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error_human']).to eq('Translation service configuration is incomplete')
        expect(Setting.get('content_translation_provider')).to eq('')
      end
    end
  end

  describe 'POST /content_translation/providers/:provider/deactivate' do
    let(:active) { false }

    before do
      allow(Service::ContentTranslation::SwitchProvider).to receive(:execute)

      post '/api/v1/content_translation/providers/ai/deactivate', as: :json
    end

    include_examples 'switching the provider'
    include_examples 'requiring a translation administration permission'
  end
end
