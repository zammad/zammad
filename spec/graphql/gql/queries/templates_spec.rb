# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Templates, type: :graphql do

  context 'when fetching templates' do
    let(:admin)     { create(:admin) }
    let(:agent)     { create(:agent) }
    let(:customer)  { create(:customer) }
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

    context 'with admin.template permission', authenticated_as: :admin do

      it 'returns active and inactive templates' do
        expect(gql.result.data).to contain_exactly(template_response, inactive_template_response)
      end

      it 'returns templates in alphabetical order' do
        actual_names = gql.result.data.pluck('name')
        expect(actual_names).to eq(actual_names.sort)
      end

      context 'when fetching only active templates' do
        let(:only_active) { true }

        it 'does not include inactive templates' do
          expect(gql.result.data).to eq([template_response])
        end
      end
    end

    context 'with ticket.agent permission only', authenticated_as: :agent do

      it 'does not include inactive templates' do
        expect(gql.result.data).to eq([template_response])
      end

      context 'when fetching only active templates' do
        let(:only_active) { true }

        it 'does not include inactive templates' do
          expect(gql.result.data).to eq([template_response])
        end
      end
    end

    context 'with ticket.customer permission only', authenticated_as: :customer do

      it 'fails with an authorization error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
