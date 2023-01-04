# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Account::Avatar::Delete, type: :graphql do
  context 'when creating a new avatar for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { id: gql.id(avatar) } }
    let(:execute_query) { true }
    let(:avatar)        { create(:avatar, o_id: agent.id) }

    let(:query) do
      <<~QUERY
        mutation accountAvatarDelete($id: ID!) {
          accountAvatarDelete(id: $id) {
            success
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    before do
      next if !execute_query

      gql.execute(query, variables: variables)
    end

    context 'with existing avatar' do
      it 'returns success' do
        expect(gql.result.data['success']).to be true
      end

      it 'does not find the avatar anymore' do
        expect { Avatar.find(avatar.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when deleting avatar of another user' do
      let(:avatar) { create(:avatar, o_id: 1) }

      it 'fails with error message' do
        expect(gql.result.error_message).to eq('Avatar could not be found.')
      end
    end

    context 'with not existing avatar' do
      let(:variables) { { id: 123_456_789 } }

      it 'fails with error message' do
        expect(gql.result.error_message).to eq("Could not find Avatar #{variables[:id]}")
      end

      it 'fails with error type' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
