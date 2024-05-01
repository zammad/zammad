# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::VerifyMethodConfiguration, current_user_id: 1 do
  subject(:service) { described_class.new(user:, method_name:, payload:, configuration:) }

  let(:user)                  { create(:agent) }
  let(:method_name)           { 'authenticator_app' }
  let(:recover_codes_enabled) { true }
  let(:has_recovery_codes)    { false }
  let(:payload)               { verification_code }
  let(:verification_code)     { nil }
  let(:configuration)         { nil }

  context 'when the given method exists' do
    let(:verification_code) { ROTP::TOTP.new(configuration[:secret]).now }
    let(:configuration) { user.auth_two_factor.authentication_method_object(method_name).initiate_configuration }

    before do
      if has_recovery_codes
        create(:user_two_factor_preference, :recovery_codes, user:)
      end

      Setting.set('two_factor_authentication_recovery_codes', recover_codes_enabled)
    end

    context 'when the given method is not enabled' do
      it 'raises error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'The two-factor authentication method is not enabled.')
      end
    end

    context 'when given method is enabled' do
      before do
        Setting.set('two_factor_authentication_method_authenticator_app', true)
      end

      context 'with wrong verification code' do
        let(:verification_code) { 'wrong' }

        it 'verify failed' do
          expect { service.execute }.to raise_error(Service::User::TwoFactor::VerifyMethodConfiguration::Failed, 'The verification of the two-factor authentication method configuration failed.')
        end
      end

      context 'with correct verification code', :aggregate_failures do
        it 'verify succeeded with recovery codes' do
          result = service.execute
          expect(result[:recovery_codes].length).to eq(10)
        end

        context 'with disabled recovery codes' do
          let(:recover_codes_enabled) { false }

          it 'verify succeeded (but without recovery codes)' do
            result = service.execute
            expect(result[:recovery_codes]).to be_nil
          end
        end

        context 'with existing recovery codes' do
          let(:has_recovery_codes) { true }

          it 'verify succeeded (but without recovery codes)' do
            result = service.execute
            expect(result[:recovery_codes]).to be_nil
          end
        end
      end
    end
  end

  context 'when the given method does not exist' do
    let(:method_name) { 'nonsense' }

    it 'raises error' do
      expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'The given two-factor method does not exist.')
    end
  end
end
