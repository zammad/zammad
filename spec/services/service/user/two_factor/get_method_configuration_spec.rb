# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::GetMethodConfiguration do
  subject(:service_result) { described_class.with_current_user(user).execute(method_name:) }

  let(:user)        { create(:agent) }
  let(:method_name) { 'security_keys' }
  let(:enabled)     { true }

  before do
    Setting.set('two_factor_authentication_method_security_keys', enabled)
  end

  context 'when method does not exist' do
    let(:method_name) { 'nonsense' }

    it 'raises an error' do
      expect { service_result }
        .to raise_error(Exceptions::UnprocessableContent)
    end
  end

  context 'when method is configured' do
    let(:user_preference) { create(:user_two_factor_preference, :security_keys, user:) }

    before { user_preference }

    context 'when method is enabled' do
      it 'returns configuration' do
        expect(service_result).to eq(user_preference.configuration)
      end

      context 'with authenticator app method' do
        let(:method_name)     { 'authenticator_app' }
        let(:user_preference) { create(:user_two_factor_preference, :authenticator_app, user:) }

        it 'returns nil' do
          expect(service_result).to be_nil
        end
      end
    end

    context 'when method is not enabled' do
      let(:enabled) { false }

      it 'returns configuration' do
        expect(service_result).to eq(user_preference.configuration)
      end
    end
  end

  context 'when method is not configured' do
    it 'returns nil' do
      expect(service_result).to be_nil
    end
  end
end
