# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::ChangePassword, type: :graphql do
  context 'when changing the password', authenticated_as: :agent do
    let(:agent) { create(:agent, password: 'password') }
    let(:mutation) do
      <<~MUTATION
        mutation userCurrentChangePassword($currentPassword: String!, $newPassword: String!) {
          userCurrentChangePassword(currentPassword: $currentPassword, newPassword: $newPassword) {
            success
            errors {
              message
              messagePlaceholder
              field
            }
          }
        }
      MUTATION
    end
    let(:variables) { {} }

    before do
      gql.execute(mutation, variables: variables)
    end

    context 'with invalid current password' do
      let(:variables) do
        {
          currentPassword: 'foobar',
          newPassword:     'new_password'
        }
      end

      it 'fails with error message', :aggregate_failures do
        errors = gql.result.data[:errors].first
        expect(errors['message']).to eq('The current password you provided is incorrect.')
        expect(errors['field']).to eq('current_password')
      end
    end

    context 'with password policy violation' do
      let(:variables) do
        {
          currentPassword: 'password',
          newPassword:     'fooBAR42',
        }
      end

      it 'fails with an error message' do
        expect(gql.result.data[:errors].first).to eq({
                                                       'message'            => 'Invalid password, it must be at least %s characters long!',
                                                       'messagePlaceholder' => ['10'],
                                                       'field'              => 'new_password',
                                                     })
      end
    end

    context 'with valid passwords' do
      let(:variables) do
        {
          currentPassword: 'password',
          newPassword:     'IamAValidPassword111einseinself'
        }
      end

      it 'succeeds' do
        expect(gql.result.data[:success]).to be_truthy
      end
    end
  end
end
