# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'GraphQL', type: :request do
  describe 'sensitive data is filtered out from logs' do
    let(:query) do
      <<~QUERY
        mutation testMutation() {
          test() {
          }
        }
      QUERY
    end

    let(:testing_string)     { 'visible test string' }
    let(:private_key_string) { 'private string to be redacted' }
    let(:password_string)    { 'testpassword' }
    let(:idp_cert_string)    { 'idp_cert_value' }

    let(:variables) do
      {
        testing:     testing_string,
        privateKey:  private_key_string,
        newPassword: password_string,
        idpCert:     idp_cert_string
      }
    end

    it 'does not log sensitive fields', aggregate_failures: true do
      allow(Rails.logger).to receive(:info)

      post '/graphql', params: { query: query, variables: variables }, as: :json

      expect(Rails.logger).to have_received(:info).with(%r{Parameters:}) do |message|
        expect(message)
          .to include(testing_string)
          .and(not_include(private_key_string))
          .and(not_include(password_string))
          .and(not_include(idp_cert_string))
      end
    end
  end

  describe 'originating browser tab' do
    let(:headers) { { 'X-Zammad-Browser-Tab-Id' => 'tab-a', 'X-Zammad-Skip-Subscriptions' => 'ticketUpdates,userCurrentTaskbarItemStateUpdates' } }

    let(:origins) { {} }

    before do
      allow(Gql::ZammadSchema).to receive(:execute).and_wrap_original do |method, *args, **kwargs|
        origins[:execution] = Gql::SubscriptionOrigin.current
        method.call(*args, **kwargs)
      end

      allow(TransactionDispatcher).to receive(:commit).and_wrap_original do |method, *args|
        origins[:transaction] = Gql::SubscriptionOrigin.current
        method.call(*args)
      end

      post '/graphql', params: { query: '{ __typename }' }, headers:, as: :json
    end

    it 'applies it to the execution' do
      expect(origins[:execution]).to have_attributes(
        browser_tab_id:     'tab-a',
        skip_subscriptions: %w[ticketUpdates userCurrentTaskbarItemStateUpdates],
      )
    end

    it 'does not apply it to the transaction backends' do
      expect(origins).to include(transaction: nil)
    end
  end

  describe 'custom errors for DDOS-like queries' do
    before do
      allow(Gql::ZammadSchema)
        .to receive(:execute)
        .and_raise(GraphqlValidations::Error, 'Abusive query detected')

      post '/graphql', params: { query: '{ abusiveQuery }' }, as: :json
    end

    it 'returns unprocessable content status' do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns JSON error for abusive queries' do
      expect(json_response).to eq(
        'errors' => [
          {
            'message' => 'Abusive query detected',
          }
        ]
      )
    end
  end

  describe 'session based authentication' do
    let(:user) { create(:agent, :with_valid_password) }

    before do
      authenticated_as(user, via: :browser)
    end

    it 'accepts a session of an active user', :aggregate_failures do
      post '/graphql', params: { query: '{ currentUser { id } }' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.dig('data', 'currentUser', 'id')).to eq(user.to_global_id.to_s)
    end

    # Bypasses the callback that drops the user's sessions (see User::TerminatesSessions), so
    #   that this covers the prerequisite itself: a session that outlives a deactivation - one
    #   written by a code path that skips callbacks, or re-persisted by the request in which the
    #   account deactivated itself - must still be rejected.
    it 'rejects a session that was retained across a deactivation' do
      user.update_columns(active: false)

      post '/graphql', params: { query: '{ currentUser { id } }' }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'no longer authenticates once deactivation dropped the session' do
      user.update!(active: false)

      post '/graphql', params: { query: '{ currentUser { id } }' }, as: :json

      expect(json_response).to include('errors' => include(include('message' => 'Authentication required')))
    end

    # A session an admin switched into another user from authenticates as that user, so it stays
    #   a working session of a revoked admin unless the account that holds it is checked as well
    #   (see Auth::SwitchedSession) - switching back is not required to keep using it.
    context 'with a session switched into another user' do
      let(:user)  { create(:admin, :with_valid_password) }
      let(:agent) { create(:agent) }

      # Deactivating the last account with admin permissions is refused.
      before do
        create(:admin)

        get "/api/v1/sessions/switch/#{agent.id}", as: :json
      end

      it 'accepts it while the admin is active', :aggregate_failures do
        post '/graphql', params: { query: '{ currentUser { id } }' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.dig('data', 'currentUser', 'id')).to eq(agent.to_global_id.to_s)
      end

      # Bypasses the callback that drops the admin's sessions, as above.
      it 'rejects it once the admin was deactivated' do
        user.update_columns(active: false)

        post '/graphql', params: { query: '{ currentUser { id } }' }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'no longer authenticates once the deactivation dropped the session' do
        user.update!(active: false)

        post '/graphql', params: { query: '{ currentUser { id } }' }, as: :json

        expect(json_response).to include('errors' => include(include('message' => 'Authentication required')))
      end
    end
  end
end
