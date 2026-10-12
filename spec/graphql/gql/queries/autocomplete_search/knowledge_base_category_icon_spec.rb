# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# How icons are matched is covered by spec/lib/knowledge_base/icon_catalog_spec.rb — this covers the
#   GraphQL surface only: arguments, authorization, and the payload.
RSpec.describe Gql::Queries::AutocompleteSearch::KnowledgeBaseCategoryIcon, authenticated_as: :editor, type: :graphql do
  context 'when searching for knowledge base category icons' do
    let(:role)     { create(:role, permission_names: %w[knowledge_base.editor]) }
    let(:editor)   { create(:agent, roles: [role]) }
    let(:query) do
      <<~QUERY
        query autocompleteSearchKnowledgeBaseCategoryIcon($input: AutocompleteSearchKnowledgeBaseCategoryIconInput!) {
          autocompleteSearchKnowledgeBaseCategoryIcon(input: $input) {
            value
            label
            iconSet
          }
        }
      QUERY
    end

    let(:variables)    { { input: { query: query_string, iconSet: icon_set, limit: limit } } }
    let(:query_string) { 'glass' }
    let(:icon_set)     { 'FontAwesome' }
    let(:limit)        { nil }

    before { gql.execute(query, variables: variables) }

    context 'with a matching name' do
      it 'returns the icon codepoint as value, the name as label and the searched iconset' do
        expect(gql.result.data).to include(
          {
            'value'   => 'f000',
            'label'   => 'glass',
            'iconSet' => 'FontAwesome',
          }
        )
      end
    end

    context 'with a limit' do
      let(:query_string) { 'user' }
      let(:limit)        { 2 }

      it 'respects the limit' do
        expect(gql.result.data.length).to eq(2)
      end
    end

    KnowledgeBase::ICONSETS.each do |iconset|
      context "with iconset #{iconset}" do
        let(:icon_set)     { iconset }
        let(:query_string) { '*' }

        it 'returns icons of that set' do
          expect(gql.result.data).to be_present.and(all(include('iconSet' => iconset)))
        end
      end
    end

    context 'with an unknown iconset' do
      let(:icon_set) { 'NonExistingIconSet' }

      it 'raises a coercion error' do
        expect(gql.result.error_message).to include('is not a valid KnowledgeBaseIconSet')
      end
    end

    context 'without knowledge base editor permission', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'raises an authorization error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
