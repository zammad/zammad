# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Organization::NoteUpdate, type: :graphql do
  context 'when updating organizations', authenticated_as: :user do
    let(:user)               { create(:agent, preferences: { locale: 'de-de' }) }
    let(:organization)       { create(:organization) }
    let(:variables)          { { id: gql.id(organization), note: } }
    let(:note)               { 'This is a test note.' }

    let(:query) do
      <<~QUERY
        mutation organizationNoteUpdate($id: ID!, $note: String!) {
          organizationNoteUpdate(id: $id, note: $note) {
            organization {
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

    before do
      gql.execute(query, variables: variables)
    end

    it 'returns updated organization' do
      expect(gql.result.data[:organization]).to include('note' => note)
    end

    context 'when trying to update without having correct permissions' do
      let(:user) { create(:customer) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
