# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rotp'

FactoryBot.define do
  factory :'user/two_factor_preference', aliases: %i[user_two_factor_preference] do
    transient do
      method_name { nil }
    end

    add_attribute(:method) { method_name }

    user          { create(:user) }
    updated_by_id { user.id }
    created_by_id { user.id }

    trait :authenticator_app do
      transient do
        secret { ROTP::Base32.random_base32 }
        code   { ROTP::TOTP.new(secret).now }
      end

      before(:create) do
        Setting.set('two_factor_authentication_method_authenticator_app', true)
      end

      method_name { 'authenticator_app' }

      configuration do
        {
          secret:           secret,
          code:             code,   # Store a valid code for usage from the tests.
          provisioning_uri: ROTP::TOTP.new(secret, issuer: 'Zammad CI').provisioning_uri(user.login),
        }
      end
    end

    trait :recovery_codes do
      transient do
        token { 'example' }
      end

      method_name { 'recovery_codes' }

      configuration do
        {
          codes: [token]
        }
      end
    end
  end
end
