# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Update, type: :graphql do
  let(:variables) do
    {
      id:    gql.id(user),
      input: input
    }
  end

  let(:input) { { email: 'dummy@zammad.com' } }

  context 'when updating a user', authenticated_as: :agent do
    let(:agent) { create(:agent) }
    let(:user)  { create(:user, :with_org) }

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

    context 'with basic fields' do
      let(:input) do
        {
          email:     'dummy@zammad.com',
          firstname: 'Bender',
          lastname:  'Rodríguez',
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
        expect(gql.result.data[:user]).to eq(expected_response)
      end

      context 'with not unique email', :aggregate_failures do
        it 'returns a user error' do
          create(:user, email: 'dummy@zammad.com')

          gql.execute(query, variables: variables)
          expect(gql.result.data[:errors].first).to include({ 'message' => "Email address 'dummy@zammad.com' is already used for another user." })
        end
      end
    end

    context 'with multiple secondary organizations' do
      let(:organization_a) { create(:organization) }
      let(:organization_b) { create(:organization) }

      context 'when user has no secondary organizations' do
        let(:input) do
          {
            email:           'dummy@zammad.com',
            organizationIds: [organization_a, organization_b].map { |elem| gql.id(elem) }
          }
        end

        it 'adds given organizations' do
          gql.execute(query, variables: variables)

          expect(user.reload).to have_attributes(organizations: [organization_a, organization_b])
        end
      end

      context 'when user already has a secondary organization' do
        let(:input) do
          {
            email:           'dummy@zammad.com',
            organizationIds: [organization_b].map { |elem| gql.id(elem) }
          }
        end

        it 'replaces secondary organization with a given one' do
          user.update! organizations: [organization_a]

          gql.execute(query, variables: variables)

          expect(user.reload).to have_attributes(organizations: [organization_b])
        end
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

    context 'when user is email-less' do
      let(:user)      { create(:user, :without_email) }
      let(:firstname) { 'dummy test name' }
      let(:input)     { { firstname: firstname } }

      it 'updates User record' do
        gql.execute(query, variables: variables)

        expect(user.reload).to have_attributes(firstname: firstname)
      end
    end
  end
end
