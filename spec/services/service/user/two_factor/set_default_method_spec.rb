# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::SetDefaultMethod do
  subject(:service) { described_class.new(user:, method_name:) }

  let(:user) { create(:agent) }

  context 'when the given method exists' do
    let(:method_name) { 'authenticator_app' }

    context 'when the given method not enabled' do
      it 'raises error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity)
      end
    end

    context 'when the given method enabled' do
      before do
        Setting.set('two_factor_authentication_method_authenticator_app', true)
        Setting.set('two_factor_authentication_method_security_keys', true)
      end

      context 'when user has the given method configured' do
        let(:preference)       { create(:user_two_factor_preference, :authenticator_app, user:) }
        let(:other_preference) { create(:user_two_factor_preference, :security_keys, user:) }

        before { other_preference && preference }

        it 'sets the given method as default' do
          expect { service.execute }
            .to change { user.reload.preferences.dig(:two_factor_authentication, :default) }
            .to('authenticator_app')
        end
      end

      context 'when user does not have the given method configured' do
        it 'raises error' do
          expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity)
        end
      end
    end
  end

  context 'when the given method does not exist' do
    let(:method_name) { 'nonsense' }

    it 'raises error' do
      expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity)
    end
  end
end
