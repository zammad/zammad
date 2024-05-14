# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::RemoveLinkedAccount, type: :graphql do
  let(:user)          { create(:agent) }
  let(:authorization) { create(:twitter_authorization, user: user) }
  let(:provider)      { authorization.provider }
  let(:uid)           { authorization.uid }

  let(:mutation) do
    <<~GQL
      mutation userCurrentRemoveLinkedAccount($provider: EnumAuthenticationProvider!, $uid: String!) {
        userCurrentRemoveLinkedAccount(provider: $provider, uid: $uid) {
          success
        }
      }
    GQL
  end

  let(:variables) { { provider:, uid: } }

  before do
    gql.execute(mutation, variables: variables)
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'with a valid authorization' do
      it 'removes the linked account' do
        expect { authorization.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'without required permission' do
      let(:user) do
        create(:agent).tap do |user|
          user.roles.each { |role| role.permission_revoke('user_preferences') }
        end
      end

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without a valid authorization' do
      let(:uid) { 'invalid-uid' }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::UnprocessableEntity)
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
