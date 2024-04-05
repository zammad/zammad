# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Account::OutOfOffice, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation accountOutOfOffice($settings: OutOfOfficeInput!) {
        accountOutOfOffice(settings: $settings) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) do
    {
      settings:
                {
                  enabled:     true,
                  text:        'Out of office message',
                  startAt:     1.day.from_now.iso8601,
                  endAt:       2.days.from_now.iso8601,
                  replacement: create(:agent).id
                }
    }
  end

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'with invalid settings' do
      let(:variables) do
        {
          settings:
                    {
                      enabled:     true,
                      text:        'Out of office message',
                      startAt:     1.day.from_now.iso8601,
                      endAt:       2.days.from_now.iso8601,
                      replacement: nil
                    }
        }
      end

      it 'returns an error' do
        expect(execute_graphql_query.error_message).to eq('Variable $settings of type OutOfOfficeInput! was provided invalid value for replacement (Expected value to not be null)')
      end
    end

    context 'with valid setting' do
      it 'updates user profile out of office settings' do
        expect { execute_graphql_query }.to change { user.reload.preferences['out_of_office_text'] }.from(nil).to('Out of office message')
      end
    end
  end
end
