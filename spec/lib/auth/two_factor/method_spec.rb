# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'rotp'

RSpec.describe Auth::TwoFactor::Method, current_user_id: 1 do
  let(:user)     { create(:user) }
  let(:instance) { described_class.new(user) }

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
  it_behaves_like 'responding to provided instance method', :configuration_options
  it_behaves_like 'responding to provided instance method', :create_user_config
  it_behaves_like 'responding to provided instance method', :destroy_user_config

  it_behaves_like "raising 'NotImplemented' error for base methods", :verify, [ nil, nil ]
  it_behaves_like "raising 'NotImplemented' error for base methods", :configuration_options

  it_behaves_like 'returning expected value', :available?, true
  it_behaves_like 'returning expected value', :enabled?, nil
  it_behaves_like 'returning expected value', :method_name, 'method', assertion: 'eq'
  it_behaves_like 'returning expected value', :related_setting_name, 'two_factor_authentication_method_method', assertion: 'eq'

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
  end

  describe '#destroy_user_config' do
    before { create(:'user/two_factor_preference', method: 'method', user: user) }

    it 'removes two factor configuration for the user' do
      instance.destroy_user_config

      expect(user.reload.two_factor_preferences).to be_empty
    end
  end
end
