# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI Assistance API endpoint', authenticated_as: :user, type: :request do
  let(:user)             { create(:agent) }
  let(:input)            { Faker::Lorem.unique.sentence }
  let(:ai_analytics_run) { create(:ai_analytics_run) }
  let(:output)           { Struct.new(:content, :stored_result, :fresh, :ai_analytics_run, keyword_init: true).new(content: Faker::Lorem.unique.paragraph, stored_result: nil, fresh: false, ai_analytics_run:) }

  describe '#text_tools' do
    let(:params) do
      {
        input:,
      }
    end

    before do
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

      setup_ai_provider
      Setting.set('ai_assistance_text_tools', true)
    end

    context 'when using an existing text tool' do
      let(:text_tool) { create(:ai_text_tool) }

      before do
        allow_any_instance_of(AI::Service::TextTool)
          .to receive(:execute)
          .and_return(output)

        post "/api/v1/ai_assistance/text_tools/#{text_tool.id}", params:, as: :json
      end

      context 'when user has agent access' do
        it 'returns improved text and implicitly records usage', aggregate_failures: true do
          expect(json_response).to eq({
                                        'output'    => output[:content],
                                        'analytics' => {
                                          'run_id' => ai_analytics_run.id,
                                        },
                                      })

          expect(ai_analytics_run.usages.find_by(user: user)).to have_attributes(
            rating: nil,
          )
        end
      end

      context 'when user does not have agent access' do
        let(:user) { create(:customer) }

        it 'raises error' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when using an inactive text tool' do
      let(:text_tool) { create(:ai_text_tool, active: false) }

      before do
        post "/api/v1/ai_assistance/text_tools/#{text_tool.id}", params:, as: :json
      end

      it 'raises error' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when using an unknown text tool' do
      before do
        post '/api/v1/ai_assistance/text_tools/99_999', params:, as: :json
      end

      it 'raises error' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
