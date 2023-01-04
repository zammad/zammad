# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Add, type: :graphql do
  context 'when creating a new user', authenticated_as: :agent do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        mutation userAdd($input: UserInput!) {
          userAdd(input: $input) {
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
        input: {
          email:     'dummy@zammad.com',
          firstname: 'Bender',
          lastname:  'Rodríguez',
        }
      }
    end

    let(:expected_response) do
      {
        'id'        => gql.id(User.find_by(email: 'dummy@zammad.com')),
        'firstname' => 'Bender',
        'lastname'  => 'Rodríguez',
        'fullname'  => 'Bender Rodríguez',
      }
    end

    it 'creates User record' do
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

    context 'without permission', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
