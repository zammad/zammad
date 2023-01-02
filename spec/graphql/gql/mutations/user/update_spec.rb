# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Update, type: :graphql do
  context 'when creating a new user', authenticated_as: :agent do
    let(:agent) { create(:agent) }
    let(:user)  { create(:user) }

    let(:query) do
      <<~QUERY
        mutation userUpdate($id: ID!, $input: UserInput!) {
          userUpdate(id: $id, input: $input) {
            user {
              id
              firstname
              lastname
              fullname
            }
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
        id:    gql.id(user),
        input: {
          email:     'dummy@zammad.com',
          firstname: 'Bender',
          lastname:  'Rodríguez',
        }
      }
    end

    let(:expected_response) do
      {
        'id'        => gql.id(user),
        'firstname' => 'Bender',
        'lastname'  => 'Rodríguez',
        'fullname'  => 'Bender Rodríguez',
      }
    end

    it 'updates User record' do
      gql.execute(query, variables: variables)
      expect(gql.result.data['user']).to eq(expected_response)
    end

    context 'with not unique email', :aggregate_failures do
      it 'returns a user error' do
        create(:user, email: 'dummy@zammad.com')

        gql.execute(query, variables: variables)
        expect(gql.result.data['errors'].first).to include({ 'message' => "Email address 'dummy@zammad.com' is already used for other user." })
      end
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
          expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
        end
      end

      context 'with customer' do
        let(:user) { create(:customer) }

        it 'raises an error' do
          gql.execute(query, variables: variables)
          expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
        end
      end
    end
  end
end
