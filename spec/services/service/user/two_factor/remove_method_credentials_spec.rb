# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::RemoveMethodCredentials do
  subject(:service) { described_class.new(user:, method_name:, credential_id:) }

  let(:user)          { create(:agent) }
  let(:method_name)   { 'security_keys' }
  let(:enabled)       { true }
  let(:credential_id) { 'firstKey' }

  before do
    Setting.set('two_factor_authentication_method_security_keys', enabled)
  end

  context 'when method does not exist' do
    let(:method_name) { 'nonsense' }

    it 'raises an error' do
      expect { service.execute }
        .to raise_error(Exceptions::UnprocessableEntity)
    end
  end

  context 'when method does not have credentials' do
    let(:user_preference) { create(:user_two_factor_preference, :authenticator_app, user:) }
    let(:method_name)     { 'authenticator_app' }

    it 'raises an error' do
      expect { service.execute }
        .to raise_error(Exceptions::UnprocessableEntity)
    end
  end

  context 'when method has credentials' do
    let(:user_preference) do
      create(:user_two_factor_preference, :security_keys, credential_public_key: credential_id, user:)
    end

    context 'when method is enabled' do
      context 'when multiple credentials exist' do
        let(:other_credential_id) { 'secondKey' }

        before do
          credential = attributes_for(:user_two_factor_preference,
                                      :security_keys,
                                      credential_public_key: other_credential_id,
                                      user:)
            .dig(:configuration, :credentials, 0)

          user_preference.configuration[:credentials] << credential
          user_preference.save!
        end

        it 'removes one of credentials' do
          expect { service.execute }
            .to change { credentials?(credential_id) }
            .to be_falsey
        end

        it 'keeps other credentials' do
          expect { service.execute }
            .not_to change { credentials?(other_credential_id) }
            .from be_truthy
        end
      end

      context 'when last credentails are removed' do
        it 'removes whole user preference' do
          expect { service.execute }
            .to change { User::TwoFactorPreference.exists?(user_preference.id) }
            .to be_falsey
        end
      end
    end

    context 'when method is not enabled' do
      let(:enabled) { false }

      it 'removes whole user preference' do
        expect { service.execute }
          .to change { User::TwoFactorPreference.exists?(user_preference.id) }
          .to be_falsey
      end
    end
  end

  context 'when method is not configured' do
    it 'raises an error' do
      expect { service.execute }
        .to raise_error(Exceptions::UnprocessableEntity)
    end
  end

  def credentials?(id)
    user_preference
      .reload
      .configuration[:credentials]
      .any? { |elem| elem[:public_key] == id }
  end
end
