# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::BetaUi::SendFeedback, :aggregate_failures, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation betaUiSendFeedback($input: BetaUiFeedbackInput!) {
        betaUiSendFeedback(input: $input) {
          success
        }
      }
    GQL
  end

  let(:variables) do
    {
      input: {
        type:      'manual_feedback',
        comment:   Faker::Lorem.unique.paragraph,
        timeSpent: 42,
        rating:    5,
      },
    }
  end

  def execute_graphql_query
    gql.execute(mutation, variables:)
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'when beta ui is enabled' do
      before do
        Setting.set('ui_desktop_beta_switch', true)

        allow(Service::BetaUi::SendFeedback).to receive(:execute).and_return(true)
      end

      it 'sends feedback' do
        execute_graphql_query
        expect(gql.result.data[:success]).to be(true)
      end
    end

    context 'when beta ui is disabled' do
      it 'fails with authorization error' do
        execute_graphql_query
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end
end
