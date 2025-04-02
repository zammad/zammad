# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Add, :aggregate_failures, type: :graphql do
  context 'when creating a new user', authenticated_as: :agent do
    let(:agent)       { create(:agent) }
    let(:dummy_email) { 'dummy@zammad.com' }
    let(:query) do
      <<~QUERY
        mutation userAdd($input: UserInput!, $sendInvite: Boolean) {
          userAdd(input: $input, sendInvite: $sendInvite) {
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
          email:     dummy_email,
          firstname: 'Bender',
          lastname:  'Rodríguez',
        }
      }
    end

    let(:expected_response) do
      {
        'id'        => gql.id(User.find_by(email: dummy_email)),
        'firstname' => 'Bender',
        'lastname'  => 'Rodríguez',
        'fullname'  => 'Bender Rodríguez',
      }
    end

    it 'creates User record' do
      gql.execute(query, variables: variables)
      expect(gql.result.data[:user]).to eq(expected_response)
    end

    context 'with not unique email', :aggregate_failures do
      it 'returns a user error' do
        create(:user, email: dummy_email)

        gql.execute(query, variables: variables)
        expect(gql.result.data[:errors].first)
          .to include({ 'message' => "Email address '#{dummy_email}' is already used for another user." })
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
