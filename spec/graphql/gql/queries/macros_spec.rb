# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Macros, type: :graphql do
  let(:agent) { create(:agent, groups: [group]) }
  let(:group) { create(:group) }
  let(:query) do
    <<~QUERY
      query macros($groupId: ID!) {
        macros(groupId: $groupId) {
          id
          active
          name
          uxFlowNextUp
        }
      }
    QUERY
  end

  let(:variables) { { groupId: gql.id(group) } }

  let(:macro) { create(:macro) }

  before do
    Macro.destroy_all
    macro
    gql.execute(query, variables: variables)
  end

  context 'with authenticated session', authenticated_as: :agent do
    it 'returns macros' do
      expect(gql.result.data).to match_array(include('id' => gql.id(macro)))
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
