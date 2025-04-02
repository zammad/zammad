# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rotp'
require 'webauthn'

FactoryBot.define do
  factory :'user/two_factor_preference', aliases: %i[user_two_factor_preference] do

    transient do
      user { association(:user, preferences: { two_factor_authentication: { default: method } }) }
    end

    user_id       { user.id }
    updated_by_id { user.id }
    created_by_id { user.id }

    trait :authenticator_app do
      add_attribute(:method) { 'authenticator_app' }

      transient do
        secret { ROTP::Base32.random_base32 }
        code   { ROTP::TOTP.new(secret).now }
      end

      configuration do
        {
          secret:           secret,
          code:             code, # Store a valid code for usage from the tests.
          provisioning_uri: ROTP::TOTP.new(secret, issuer: 'Zammad CI').provisioning_uri(user.login),
        }
      end
    end

    trait :security_keys do
      add_attribute(:method) { 'security_keys' }

      transient do
        credential_external_id { Faker::Alphanumeric.alpha(number: 70) }
        credential_public_key  { Faker::Alphanumeric.alpha(number: 128) }

        # A fake static key is enough for most of the tests.
        credential do
          {
            external_id: credential_external_id,
            public_key:  credential_public_key,
            nickname:    Faker::Lorem.unique.word,
            sign_count:  '0',
            created_at:  Time.zone.now,
          }
        end
      end

      configuration do
        {
          credentials: [credential],
        }
      end
    end

    trait :mocked_security_keys do
      add_attribute(:method) { 'security_keys' }

      transient do
        page      { raise NotImplementedError, 'You must provide current page object for mocking credentials' }
        wrong_key { false }

        # We can mock a WebAuthn credential only within a running browser session.
        #   The code below is a pretty heavy "hack" to get the credential information from the Selenium virtual
        #   authenticator, by simulating the complete registration process.
        #   First, the create options are generated via Ruby code.
        #   Then, a virtual authenticator instance is set up within the browser session with a mocked U2F key.
        #   Create options are passed to JS, which triggers the registration of the key.
        #   Finally, returned key information is processed back in Ruby, and the mocked credential can be "stored" in
        #   the emulated two factor preferences.
        credential do
          WebAuthn.configure do |config|
            config.origin  = "#{Setting.get('http_type')}://#{Capybara.app_host.gsub(%r{^https?://}, '')}:#{Capybara.current_session.server.port}"
            config.rp_name = Setting.get('organization').presence || Setting.get('product_name').presence || 'Zammad'
            config.credential_options_timeout = 120_000
          end

          initiate_configuration = WebAuthn::Credential.options_for_create(
            user: {
              id:           WebAuthn.generate_user_id,
              display_name: user.login,
              name:         user.login,
            },
          )

          options = Selenium::WebDriver::VirtualAuthenticatorOptions.new(protocol: :u2f, transport: :usb,
                                                                         resident_key: false, user_consenting: true,
                                                                         user_verification: true, user_verified: true)
          page.driver.browser.add_virtual_authenticator(options)

          public_key_json       = JSON.generate({ publicKey: initiate_configuration.as_json.to_h })
          public_key_credential = page.execute_script("return webauthnJSON.create(#{public_key_json}).then((publicKeyCredential) => publicKeyCredential);")
          webauthn_credential   = WebAuthn::Credential.from_create(public_key_credential)

          if wrong_key
            {
              external_id: Faker::Alphanumeric.alpha(number: 70),
              public_key:  Faker::Alphanumeric.alpha(number: 128),
              nickname:    Faker::Lorem.unique.word,
              sign_count:  '0',
              created_at:  Time.zone.now,
            }
          else
            {
              external_id: webauthn_credential.id,
              public_key:  webauthn_credential.public_key,
              nickname:    Faker::Lorem.unique.word,
              sign_count:  webauthn_credential.sign_count.to_s,
              created_at:  Time.zone.now,
            }
          end
        end
      end

      configuration do
        {
          credentials: [credential],
        }
      end
    end

    trait :recovery_codes do
      add_attribute(:method) { 'recovery_codes' }

      transient do
        user          { association :user }
        recovery_code { 'example' }
      end

      configuration do
        {
          codes: [PasswordHash.crypt(recovery_code)],
        }
      end
    end
  end
end
