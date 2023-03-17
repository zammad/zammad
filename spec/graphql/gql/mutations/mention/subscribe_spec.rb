# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Mention::Subscribe, :aggregate_failures, type: :graphql do
  let(:agent)  { create(:agent, groups: [object.group]) }
  let(:object) { Ticket.first }

  let(:query) do
    <<~QUERY
      mutation mentionSubscribe($objectId: ID!) {
        mentionSubscribe(objectId: $objectId) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:variables) do
    {
      objectId: gql.id(object),
    }
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    it 'subscribes to a ticket' do
      allow(Mention).to receive(:subscribe!)
      gql.execute(query, variables: variables)
      expect(Mention).to have_received(:subscribe!).with(object, agent)
    end
  end

  context 'with GQL query' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
