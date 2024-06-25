# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Templates, type: :graphql do

  context 'when fetching templates' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query templates($onlyActive: Boolean) {
          templates(onlyActive: $onlyActive) {
            name
            active
            options
          }
        }
      QUERY
    end
    let(:only_active) { false }
    let(:variables) { { onlyActive: only_active } }

    let!(:template)                  { create(:template) }
    let!(:inactive_template)         { create(:template, active: false) }
    let(:template_response)          { { 'name' => template.name, 'options' => template.options, 'active' => true } }
    let(:inactive_template_response) { { 'name' => inactive_template.name, 'options' => inactive_template.options, 'active' => false } }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(gql.result.data).to eq([template_response, inactive_template_response])
      end

      context 'when fetching only active templates' do
        let(:only_active) { true }

        it 'does not include inactive templates' do
          expect(gql.result.data).to eq([template_response])
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
