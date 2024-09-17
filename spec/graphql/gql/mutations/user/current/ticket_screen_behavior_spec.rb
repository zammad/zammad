# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TicketScreenBehavior, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentTicketScreenBehavior($behavior: EnumTicketScreenBehavior!) {
        userCurrentTicketScreenBehavior(behavior: $behavior) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) { { behavior: 'stayOnTab' } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'without valid behavior' do
      let(:variables) { { behavior: 'invalid' } }

      it 'returns an error' do
        expect(execute_graphql_query.error_message).to eq('Variable $behavior of type EnumTicketScreenBehavior! was provided invalid value')
      end
    end

    context 'with valid behavior' do
      it 'updates user profile appearance settings' do
        expect { execute_graphql_query }.to change { user.reload.preferences['secondaryAction'] }.from(nil).to('stayOnTab')
      end
    end
  end
end
