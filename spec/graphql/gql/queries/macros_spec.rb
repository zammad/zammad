# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Macros, type: :graphql do
  let(:agent)        { create(:agent, groups: [group, other_group]) }
  let(:group)        { create(:group) }
  let!(:other_group) { create(:group) }

  let(:query) do
    <<~QUERY
      query macros($selector: TicketMacrosSelectorInput!) {
        macros(selector: $selector) {
          id
          active
          name
          uxFlowNextUp
        }
      }
    QUERY
  end

  let(:selector)  { { entityIds: [gql.id(group)] } }
  let(:variables) { { selector: selector } }

  let(:macro) { create(:macro) }

  before do
    Macro.destroy_all
    macro
    gql.execute(query, variables: variables)
  end

  context 'with authenticated session', authenticated_as: :agent do
    context 'without macros group assignment' do
      it 'returns macros' do
        expect(gql.result.data).to match_array(include('id' => gql.id(macro)))
      end
    end

    context 'with macros group assignment' do
      let(:macro) { create(:macro, group_ids: [group.id]) }

      context 'when querying for assigned groups' do
        it 'returns macros with assigned groups' do
          expect(gql.result.data).to match_array(include('id' => gql.id(macro)))
        end
      end

      context 'when querying for unassigned groups' do
        let(:selector) { { entityIds: [gql.id(group), gql.id(other_group)] } }

        it 'does not return macros' do
          expect(gql.result.data).to be_empty
        end
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'

  describe 'selector validation', authenticated_as: :agent do
    let(:group_ids)    { nil }
    let(:overview_id)  { nil }
    let(:search_query) { nil }
    let(:selector)     { { entityIds: group_ids, overviewId: overview_id, searchQuery: search_query } }

    before do
      allow_any_instance_of(described_class).to receive(:resolve)
    end

    context 'when no arguments provided' do
      it 'raises an error' do
        gql.execute(query, variables:)

        expect(gql.result.error)
          .to include(message: 'Exactly one of entity_ids, overview_id, or search_query must be provided.')
      end
    end

    context 'when multiple arguments provided' do
      let(:group_ids)    { [1, 2] }
      let(:search_query) { 'query' }

      it 'raises an error' do
        gql.execute(query, variables:)

        expect(gql.result.error)
          .to include(message: 'Exactly one of entity_ids, overview_id, or search_query must be provided.')
      end
    end

    context 'when only entity_ids provided' do
      let(:group)      { create(:group) }
      let(:group_ids) { [gql.id(group)] }

      it 'passes group internal IDs to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: hash_including(entity_ids: [group.id]))

        gql.execute(query, variables:)
      end
    end

    context 'when only overview_id provided' do
      let(:overview)    { create(:overview) }
      let(:overview_id) { gql.id(overview) }

      it 'passes overview to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: hash_including(overview:))

        gql.execute(query, variables:)
      end
    end

    context 'when only search_query provided' do
      let(:search_query) { 'query' }

      it 'passes search query to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: hash_including(search_query:))

        gql.execute(query, variables:)
      end
    end
  end
end
