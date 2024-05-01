# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'rotp'

RSpec.describe Auth::TwoFactor::AuthenticationMethod::SecurityKeys do
  subject(:instance) { described_class.new(user) }

  let(:user) { create(:user) }

  shared_examples 'responding to provided instance method' do |method|
    it "responds to '.#{method}'" do
      expect(instance).to respond_to(method)
    end
  end

  it_behaves_like 'responding to provided instance method', :verify
  it_behaves_like 'responding to provided instance method', :initiate_configuration

  describe '#initiate_configuration' do
    it 'does not require user verification (#5156)' do
      expect(instance.initiate_configuration.authenticator_selection).to include(user_verification: 'discouraged')
    end
  end

  describe '#initiate_authentication' do
    let(:two_factor_pref) { create(:user_two_factor_preference, :security_keys, user: user) }

    before do
      two_factor_pref
      allow(WebAuthn::Credential).to receive(:options_for_get).with(any_args)
      instance.initiate_authentication
    end

    it 'does not require user verification (#5156)' do
      expect(WebAuthn::Credential).to have_received(:options_for_get).with(include(user_verification: 'discouraged'))
    end
  end
end
