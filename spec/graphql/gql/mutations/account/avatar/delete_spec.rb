# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Account::Avatar::Delete, type: :graphql do
  context 'when creating a new avatar for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { id: Gql::ZammadSchema.id_from_object(avatar) } }
    let(:execute_query) { true }
    let(:avatar)        { create(:avatar, o_id: agent.id) }

    let(:query) do
      read_graphql_file('apps/mobile/modules/account/avatar/graphql/mutations/delete.graphql') +
        read_graphql_file('shared/graphql/fragments/errors.graphql')
    end

    before do
      next if !execute_query

      graphql_execute(query, variables: variables)
    end

    context 'with existing avatar' do
      it 'returns success' do
        expect(graphql_response['data']['accountAvatarDelete']['success']).to be true
      end

      it 'does not find the avatar anymore' do
        expect { Avatar.find(avatar.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when deleting avatar of another user' do
      let(:avatar) { create(:avatar, o_id: 1) }

      it 'fails with error message' do
        expect(graphql_response['errors'][0]).to include('message' => 'Avatar could not be found.')
      end
    end

    context 'with not existing avatar' do
      let(:variables) { { id: SecureRandom.random_number(1_000_000) + 123_456 } }

      it 'fails with error message' do
        expect(graphql_response['errors'][0]).to include('message' => "Could not find Avatar #{variables[:id]}")
      end

      it 'fails with error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'ActiveRecord::RecordNotFound' })
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
