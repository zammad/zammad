# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rotp'

FactoryBot.define do
  factory :'user/two_factor_preference', aliases: %i[user_two_factor_preference] do
    add_attribute(:method) { 'authenticator_app' }

    transient do
      user   { create(:user) }
      secret { ROTP::Base32.random_base32 }
      code   { ROTP::TOTP.new(secret).now }
    end

    before(:create) do
      Setting.set('two_factor_authentication_method_authenticator_app', true)
    end

    configuration do
      {
        secret:           secret,
        code:             code,   # Store a valid code for usage from the tests.
        provisioning_uri: ROTP::TOTP.new(secret, issuer: 'Zammad CI').provisioning_uri(user.login),
      }
    end

    user_id       { user.id }
    updated_by_id { user.id }
    created_by_id { user.id }
  end
end
