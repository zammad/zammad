# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User, type: :graphql do
  context 'when fetching user' do
    let(:authenticated) { create(:agent) }
    let(:user)          do
      create(:user).tap do |user|
        create(:authorization, provider: 'testprovider', username: 'testuser', user_id: user.id)
      end
    end
    let(:variables) { { userId: gql.id(user) } }

    let(:query) do
      <<~QUERY
        query user($userId: ID, $userInternalId: Int) {
          user(user: { userId: $userId, userInternalId: $userInternalId }) {
            id
            firstname
            hasSecondaryOrganizations
            authorizations {
              username
              provider
            }
          }
        }
      QUERY
    end

    before do
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :authenticated do
      it 'has data' do
        expect(gql.result.data).to include(
          'firstname'      => user.firstname,
          'authorizations' => [ { 'provider' => 'testprovider', 'username' => 'testuser' } ],
        )
      end

      context 'without user' do
        let(:user) { create(:user).tap(&:destroy) }

        it 'fetches no user' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end

      context 'with internalId' do
        let(:variables) { { userInternalId: user.id } }

        it 'has data' do
          expect(gql.result.data).to include('firstname' => user.firstname)
        end

        it 'has no secondary organizations' do
          expect(gql.result.data).to include('hasSecondaryOrganizations' => false)
        end
      end

      context 'with secondardy organizations' do
        let(:organization)            { create(:organization) }
        let(:secondary_organizations) { create_list(:organization, 2) }
        let(:user)                    { create(:user, organization_id: organization.id, organization_ids: secondary_organizations.map(&:id)) }
        let(:authenticated)           { user }

        it 'has secondary organizations' do
          expect(gql.result.data).to include('hasSecondaryOrganizations' => true)
        end
      end

      context 'with customer' do
        context 'with myself' do
          let(:authenticated) { user }

          it 'has data' do
            expect(gql.result.data).to include('firstname' => user.firstname)
          end
        end

        context 'with another customer' do
          let(:authenticated) { create(:customer) }

          it 'raises an error' do
            expect(gql.result.error_type).to eq(Exceptions::Forbidden)
          end
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
