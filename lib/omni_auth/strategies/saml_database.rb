# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::SamlDatabase < OmniAuth::Strategies::SAML
  option :name, 'saml'

  def self.setup
    auth_saml_credentials = Setting.get('auth_saml_credentials') || {}

    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    # Use meta URL as entity id/issues as it is best practice.
    # See: https://community.zammad.org/t/saml-oidc-third-party-authentication/2533/13
    entity_id                      = "#{http_type}://#{fqdn}/auth/saml/metadata"
    assertion_consumer_service_url = "#{http_type}://#{fqdn}/auth/saml/callback"
    single_logout_service_url      = "#{http_type}://#{fqdn}/auth/saml/slo"

    config = auth_saml_credentials.compact_blank
      .merge(
        assertion_consumer_service_url: assertion_consumer_service_url,
        sp_entity_id:                   entity_id,
        single_logout_service_url:      single_logout_service_url,
        idp_slo_session_destroy:        proc { |env, session| destroy_session(env, session) },
      )

    apply_security_settings(config)

    config
  end

  def self.destroy_session(env, session)
    session.delete('saml_uid')
    session.delete('saml_transaction_id')
    session.delete('saml_session_index')

    @_current_user = nil
    env['rack.session.options'][:expire_after] = nil

    session.destroy
  end

  def initialize(app, *args, &)
    args[0] = self.class.setup

    super
  end

  def self.apply_security_settings(settings)
    security           = settings.delete(:security)           || {}
    private_key        = settings.delete(:private_key)        || ''
    private_key_secret = settings.delete(:private_key_secret) || ''
    certificate        = settings.delete(:certificate)        || ''

    return if !check_security_settings(settings, security, private_key, private_key_secret, certificate)

    apply_security_default_settings(settings)
    apply_sign_only_settings(settings, security)
    apply_encrypt_only_settings(settings, security)

    true
  end

  def self.check_security_settings(settings, security, private_key, private_key_secret, certificate)
    return false if security.blank?    || security.eql?('off')
    return false if private_key.blank? || certificate.blank?

    begin
      pkey = OpenSSL::PKey.read(private_key, private_key_secret)
    rescue
      return false
    end

    settings[:private_key] = pkey.to_pem
    settings[:certificate] = certificate

    true
  end

  def self.apply_security_default_settings(settings)
    settings[:security] = {
      digest_method:             XMLSecurity::Document::SHA256,
      signature_method:          XMLSecurity::Document::RSA_SHA256,
      authn_requests_signed:     true,
      logout_requests_signed:    true,
      want_assertions_signed:    true,
      want_assertions_encrypted: true,
    }

    true
  end

  def self.apply_encrypt_only_settings(settings, security)
    return if !security.eql?('encrypt')

    settings[:security][:authn_requests_signed]  = false
    settings[:security][:logout_requests_signed] = false
    settings[:security][:want_assertions_signed] = false

    true
  end

  def self.apply_sign_only_settings(settings, security)
    return if !security.eql?('sign')

    settings[:security][:want_assertions_encrypted] = false

    true
  end

  private_class_method %i[
    apply_security_settings
    check_security_settings
    apply_security_default_settings
    apply_encrypt_only_settings
    apply_sign_only_settings
  ].freeze

  private

  def handle_logout_response(raw_response, settings)
    logout_response = OneLogin::RubySaml::Logoutresponse.new(raw_response, settings, matches_request_id: session['saml_transaction_id'])
    logout_response.soft = false
    logout_response.validate

    redirect_path = if session['omniauth.origin']&.include?('/mobile')
                      '/mobile'
                    elsif session['omniauth.origin']&.include?('/desktop')
                      '/desktop'
                    else
                      '/'
                    end

    self.class.destroy_session(env, session)

    redirect "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{redirect_path}"
  end

end
