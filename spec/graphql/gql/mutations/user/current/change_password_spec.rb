# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
          newPassword:     'FooBarbazbaz'
        }
      end

      it 'fails with error message', :aggregate_failures do
        errors = gql.result.data[:errors].first
        expect(errors['message']).to eq('Invalid password, it must contain at least 1 digit!')
        expect(errors['field']).to eq('new_password')
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
