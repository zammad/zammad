# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Macros, type: :graphql do
  let(:agent)        { create(:agent, groups: [group, other_group]) }
  let(:group)        { create(:group) }
  let!(:other_group) { create(:group) }
  let(:query) do
    <<~QUERY
      query macros($groupIds: [ID!]!) {
        macros(groupIds: $groupIds) {
          id
          active
          name
          uxFlowNextUp
        }
      }
    QUERY
  end

  let(:variables) { { groupIds: [gql.id(group)] } }

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
        let(:variables) { { groupIds: [gql.id(group), gql.id(other_group)] } }

        it 'does not return macros' do
          expect(gql.result.data).to be_empty
        end
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
