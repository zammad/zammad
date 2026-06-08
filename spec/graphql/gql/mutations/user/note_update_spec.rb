# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::NoteUpdate, type: :graphql do
  context 'when updating a user', authenticated_as: :agent do
    let(:agent) { create(:agent) }
    let(:user)  { create(:user, :with_org) }
    let(:note)  { 'This is a test note.' }
    let(:variables) do
      {
        id:   gql.id(user),
        note:
      }
    end

    let(:query) do
      <<~QUERY
        mutation userNoteUpdate($id: ID!, $note: String!) {
          userNoteUpdate(id: $id, note: $note) {
            user {
              id
              note
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:expected_response) do
      {
        'id'   => gql.id(user),
        'note' => note,
      }
    end

    it 'updates User record' do
      gql.execute(query, variables: variables)
      expect(gql.result.data[:user]).to eq(expected_response)
    end

    context 'without permission', authenticated_as: :user do
      context 'with not authorized agent' do
        let(:user) { create(:admin, roles: [role]) }
        let(:role) do
          role = create(:role)
          role.permission_grant('admin.branding')
          role
        end

        it 'raises an error' do
          gql.execute(query, variables: variables)
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'with customer' do
        let(:user) { create(:customer) }

        it 'raises an error' do
          gql.execute(query, variables: variables)
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end
    end
  end
end
