# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SamlDatabase < OmniAuth::Strategies::SAML
  option :name, 'saml'

  def self.setup
    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    # Use meta URL as entity id/issues as it is best practice.
    # See: https://community.zammad.org/t/saml-oidc-third-party-authentication/2533/13
    entity_id                      = "#{http_type}://#{fqdn}/auth/saml/metadata"
    assertion_consumer_service_url = "#{http_type}://#{fqdn}/auth/saml/callback"
    single_logout_service_url      = "#{http_type}://#{fqdn}/auth/saml/slo"

    config = Setting.get('auth_saml_credentials') || {}
    config.compact_blank
      .merge(
        assertion_consumer_service_url: assertion_consumer_service_url,
        sp_entity_id:                   entity_id,
        single_logout_service_url:      single_logout_service_url,
        idp_slo_session_destroy:        proc { |env, session| destroy_session(env, session) },
      )
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

  private

  def handle_logout_response(raw_response, settings)
    logout_response = OneLogin::RubySaml::Logoutresponse.new(raw_response, settings, matches_request_id: session['saml_transaction_id'])
    logout_response.soft = false
    logout_response.validate

    self.class.destroy_session(env, session)

    redirect "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/"
  end

end
