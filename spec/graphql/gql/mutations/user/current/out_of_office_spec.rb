# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::OutOfOffice, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentOutOfOffice($input: OutOfOfficeInput!) {
        userCurrentOutOfOffice(input: $input) {
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
      input: {
        enabled:       true,
        text:          'Out of office message',
        startAt:       '2011-02-03',
        endAt:         '2011-03-03',
        replacementId: gql.id(create(:agent))
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
          input: {
            enabled:       true,
            text:          'Out of office message',
            startAt:       '2011-02-03',
            endAt:         '2011-03-03',
            replacementId: nil
          }
        }
      end

      it 'returns an error' do
        execute_graphql_query

        expect(gql.result.data).to include('errors' => include(
          include(
            'field'   => 'outOfOfficeReplacementId',
            'message' => 'This field can\'t be blank'
          )
        ))
      end
    end

    context 'with valid setting' do
      it 'updates user profile out of office input' do
        expect { execute_graphql_query }
          .to change { user.reload.preferences['out_of_office_text'] }
          .from(nil)
          .to('Out of office message')
      end
    end
  end
end
