# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'rotp'

RSpec.describe Auth::TwoFactor::AuthenticationMethod, current_user_id: 1 do
  subject(:instance) { described_class.new(user) }

  let(:user) { create(:user) }

  shared_examples 'responding to provided instance method' do |method|
    it "responds to '.#{method}'" do
      expect(instance).to respond_to(method)
    end
  end

  shared_examples "raising 'NotImplemented' error for base methods" do |method, args = []|
    it "raises 'NotImplemented' error for '.#{method}'" do
      expect { instance.method(method).call(*args) }.to raise_error(NotImplementedError)
    end
  end

  shared_examples 'returning expected value' do |method, value, args = [], assertion: 'be'|
    it "returns expected value for '.#{method}'", if: assertion == 'eq' do
      expect(instance.method(method).call(*args)).to eq(value)
    end

    it "returns expected value for '.#{method}'", if: assertion == 'be' do
      expect(instance.method(method).call(*args)).to be(value)
    end
  end

  it_behaves_like 'responding to provided instance method', :verify
  it_behaves_like 'responding to provided instance method', :available?
  it_behaves_like 'responding to provided instance method', :enabled?
  it_behaves_like 'responding to provided instance method', :method_name
  it_behaves_like 'responding to provided instance method', :related_setting_name
  it_behaves_like 'responding to provided instance method', :initiate_configuration
  it_behaves_like 'responding to provided instance method', :create_user_config
  it_behaves_like 'responding to provided instance method', :destroy_user_config

  it_behaves_like "raising 'NotImplemented' error for base methods", :verify, [ nil, nil ]
  it_behaves_like "raising 'NotImplemented' error for base methods", :initiate_configuration

  it_behaves_like 'returning expected value', :available?, true
  it_behaves_like 'returning expected value', :enabled?, nil
  it_behaves_like 'returning expected value', :method_name, 'authentication_method', assertion: 'eq'
  it_behaves_like 'returning expected value', :related_setting_name, 'two_factor_authentication_method_authentication_method', assertion: 'eq'

  describe '#create_user_config' do
    let(:secret) { ROTP::Base32.random_base32 }
    let(:data) do
      {
        secret:           secret,
        provisioning_uri: ROTP::TOTP.new(secret, issuer: 'Zammad CI').provisioning_uri(user.login),
      }
    end

    it 'saves two factor configuration for the user' do
      instance.create_user_config(data)

      expect(user.two_factor_preferences).to include(User::TwoFactorPreference)
    end

    context 'with existing configuration' do
      let!(:two_factor_pref) { create(:user_two_factor_preference, :security_keys, method: 'authentication_method', user: user) }
      let(:data) do
        {
          'credentials' => [
            *two_factor_pref.configuration[:credentials],
            {
              'external_id' => Faker::Alphanumeric.alpha(number: 70),
              'public_key'  => Faker::Alphanumeric.alpha(number: 128),
              'nickname'    => Faker::Lorem.unique.word,
              'sign_count'  => '0',
              'created_at'  => Time.zone.now,
            },
          ]
        }
      end

      it 'updates two factor configuration for the user' do
        instance.create_user_config(data)

        expect(two_factor_pref.reload.configuration).to eq(data)
      end
    end
  end

  describe '#update_user_config' do
    let!(:two_factor_pref) { create(:user_two_factor_preference, :authenticator_app, method: 'authentication_method', user: user) }
    let(:secret)           { ROTP::Base32.random_base32 }
    let(:data) do
      {
        'code'             => two_factor_pref.configuration[:code],
        'secret'           => secret,
        'provisioning_uri' => ROTP::TOTP.new(secret, issuer: 'Zammad CI').provisioning_uri(user.login),
      }
    end

    it 'updates two factor configuration for the user' do
      instance.update_user_config(data)

      expect(two_factor_pref.reload.configuration).to eq(data)
    end
  end

  describe '#destroy_user_config' do
    before { create(:user_two_factor_preference, :authenticator_app, method: 'authentication_method', user: user) }

    it 'removes two factor configuration for the user' do
      instance.destroy_user_config

      expect(user.reload.two_factor_preferences).to be_empty
    end

    context 'with existing recovery codes' do
      it 'deletes recovery code', :aggregate_failures do
        instance.destroy_user_config

        expect(user.reload.two_factor_preferences.authentication_methods).to be_empty
        expect(user.reload.two_factor_preferences.recovery_codes).to be_nil
      end
    end
  end
end
