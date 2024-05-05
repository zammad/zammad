# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor::AuthenticationMethod::SecurityKeys < Auth::TwoFactor::AuthenticationMethod
  ORDER = 1000

  def initiate_authentication
    return if user_two_factor_preference_configuration.blank?
    return if stored_credentials.blank?

    configure_webauthn

    WebAuthn::Credential.options_for_get(allow: stored_credentials.pluck(:external_id), user_verification: 'discouraged')
  end

  def verify(payload, configuration = user_two_factor_preference_configuration)
    return verify_result(false) if payload.blank? || configuration.blank?

    configure_webauthn

    return registration(payload, configuration) if configuration[:type] == 'registration'

    verification(payload, configuration)
  end

  def initiate_configuration
    configure_webauthn

    WebAuthn::Credential.options_for_create(
      user:                    {
        id:           WebAuthn.generate_user_id,
        display_name: user.login,
        name:         user.login,
      },
      exclude:                 stored_credentials.pluck(:external_id),
      authenticator_selection: { user_verification: 'discouraged' },
    )
  end

  private

  def registration(payload, configuration)
    webauthn_credential = WebAuthn::Credential.from_create(payload[:credential])

    begin
      webauthn_credential.verify(payload[:challenge])

      # The validation would raise WebAuthn::Error so if we are here, the credentials are valid, and we can save it
      verify_result(true, {}, registration_configuration(webauthn_credential, configuration))
    rescue WebAuthn::Error => e
      Rails.logger.debug { "Security key registration failed: #{e.message}" }
      verify_result(false)
    end
  end

  def registration_configuration(credential, configuration)
    new_configuration = user_two_factor_preference_configuration || {}

    new_configuration[:credentials] ||= []
    new_configuration[:credentials].push({
                                           external_id: credential.id,
                                           public_key:  credential.public_key,
                                           nickname:    configuration[:nickname],
                                           sign_count:  credential.sign_count.to_s, # for storage
                                           created_at:  Time.zone.now,
                                         })

    new_configuration
  end

  def webauthn_verify!(webauthn_credential, challenge, stored_credential)
    webauthn_credential.verify(
      challenge,
      public_key: stored_credential[:public_key],
      sign_count: stored_credential[:sign_count].to_i, # for verification
    )
  end

  def verification(payload, configuration)
    webauthn_credential = WebAuthn::Credential.from_get(payload[:credential])
    return verify_result(false) if webauthn_credential.nil?

    stored_credential = find_stored_credential(configuration, webauthn_credential)
    return verify_result(false) if stored_credential.nil?

    begin
      webauthn_verify!(webauthn_credential, payload[:challenge], stored_credential)

      # The validation would raise WebAuthn::Error so if we are here, the credentials are valid, and we can save it
      verify_result(true, {}, verification_configuration(webauthn_credential, stored_credential, configuration))
    rescue WebAuthn::Error, WebAuthn::SignCountVerificationError => e
      Rails.logger.debug { "Security key verification failed: #{e.message}" }
      verify_result(false)
    end
  end

  def verification_configuration(webauthn_credential, stored_credential, configuration)
    stored_credential[:sign_count] = webauthn_credential.sign_count.to_s # for storage

    if configuration[:credentials].any? { |c| c[:external_id] == stored_credential[:external_id] }
      return stored_credential
    end

    configuration
  end

  def configure_webauthn
    require 'webauthn' # Only load when it is actually used

    WebAuthn.configure do |config|
      config.origin = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}"
      config.rp_name = issuer
      config.credential_options_timeout = 120_000
    end
  end

  def issuer
    Setting.get('organization').presence || Setting.get('product_name').presence || 'Zammad'
  end

  def verify_result(verified, configuration = {}, new_configuration = {})
    return { verified: false } if !verified

    {
      **configuration,
      verified: true,
      **new_configuration,
    }
  end

  def stored_credentials
    return [] if user_two_factor_preference_configuration.blank?

    user_two_factor_preference_configuration[:credentials] || []
  end

  def find_stored_credential(configuration, webauthn_credential)
    configuration[:credentials]
      .find { |stored_credential| stored_credential[:external_id] == webauthn_credential.id }
  end
end
