# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TwoFactor::RecoveryCodesGenerate, type: :graphql do
  let(:mutation) do
    <<~MUTATION
      mutation userCurrentTwoFactorRecoveryCodesGenerate {
        userCurrentTwoFactorRecoveryCodesGenerate {
          recoveryCodes
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  context 'with authorized agent', authenticated_as: :user do
    let(:user) { create(:user) }

    context 'when recovery codes are enabled' do
      it 'returns new recovery codes' do
        gql.execute(mutation)

        expect(gql.result.data['recoveryCodes']).to include(be_a(String))
      end

      it 'generates recovery codes of current user', aggregate_failures: true do
        allow(Service::User::TwoFactor::GenerateRecoveryCodes).to receive(:new).and_call_original
        expect_any_instance_of(Service::User::TwoFactor::GenerateRecoveryCodes).to receive(:execute)

        gql.execute(mutation)

        expect(Service::User::TwoFactor::GenerateRecoveryCodes)
          .to have_received(:new).with(user: user, force: true)
      end
    end

    context 'when recovery codes are disabled' do
      before do
        Setting.set('two_factor_authentication_recovery_codes', false)
      end

      it 'returns an error if recovery codes are disabled' do
        gql.execute(mutation)

        expect(gql.result.error).to be_present
      end
    end
  end

  context 'with not authorized agent', authenticated_as: :user do
    let(:user) { create(:user) }

    before do
      user.roles.each { |role| role.permission_revoke('user_preferences.two_factor_authentication') }
    end

    it 'raises an error' do
      gql.execute(mutation)
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
