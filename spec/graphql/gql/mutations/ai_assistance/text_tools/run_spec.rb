# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::AIAssistance::TextTools::Run, :aggregate_failures, type: :graphql do
  context 'when accessing as an agent', authenticated_as: :agent do
    let(:agent)            { create(:agent) }
    let(:input)            { Faker::Lorem.unique.sentence }
    let(:ai_analytics_run) { create(:ai_analytics_run) }
    let(:output)           { Struct.new(:content, :stored_result, :ai_analytics_run, :fresh, keyword_init: true).new(content: Faker::Lorem.unique.paragraph, stored_result: nil, ai_analytics_run: ai_analytics_run, fresh: false) }
    let(:text_tool)        { create(:ai_text_tool) }

    let(:query) do
      <<~MUTATION
        mutation aiAssistanceTextToolsRun($input: String!, $textToolId: ID!, $templateRenderContext: TemplateRenderContextInput!) {
          aiAssistanceTextToolsRun(input: $input, textToolId: $textToolId, templateRenderContext: $templateRenderContext) {
            output
            analytics {
              run {
                id
              }
            }
          }
        }
      MUTATION
    end

    let(:variables) do
      {
        input:,
        textToolId:            gql.id(text_tool),
        templateRenderContext: {},
      }
    end

    before do
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

      Setting.set('ai_assistance_text_tools', true)
      setup_ai_provider

      allow_any_instance_of(AI::Service::TextTool)
        .to receive(:execute)
        .and_return(output)

      gql.execute(query, variables: variables)
    end

    it 'returns improved text and implicitly records usage' do
      expect(gql.result.data).to eq({
                                      'output'    => output[:content],
                                      'analytics' => {
                                        'run' => {
                                          'id' => gql.id(ai_analytics_run),
                                        },
                                      },
                                    })

      expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
        rating: nil,
      )
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
