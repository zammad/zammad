# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Logout < BaseMutation
    include Gql::Mutations::Concerns::Logout::HandlesOidcAuthorization

    description 'End the current session'

    field :success, Boolean, null: false, description: 'Was the logout successful?'
    field :external_logout_url, String, null: true, description: 'External logout URL (e.g. for SAML)?'

    # Don't require an authenticated user, because that is not present in maintenance_mode,
    #   when users still need to be correctly logged out.
    def self.authorize(...)
      true
    end

    def self.requires_csrf_verification?
      false
    end

    def resolve(...)
      # Handling of third-party logouts (we need to redirect to the IDP).
      return saml_destroy if saml_session?
      return oidc_destroy if oidc_session?

      context[:controller].reset_session
      context[:current_user] = nil
      context[:controller].request.env['rack.session.options'][:expire_after] = nil

      { success: true }
    end

    def saml_destroy
      { success: true, external_logout_url: saml_logout_url }
    rescue => e
      Rails.logger.error "SAML SLO failed: #{e.message}"
    end

    def saml_session?
      (session['saml_uid'] || session['saml_session_index']) && OmniAuth::Strategies::SamlDatabase.setup.fetch('idp_slo_service_url', nil)
    end

    def saml_logout_url
      options = OmniAuth::Strategies::SamlDatabase.setup
      settings = OneLogin::RubySaml::Settings.new(options)

      logout_request = OneLogin::RubySaml::Logoutrequest.new

      # Since we created a new SAML request, save the transaction_id
      # to compare it with the response we get back
      session['saml_transaction_id'] = logout_request.uuid

      settings.name_identifier_value = session['saml_uid']
      settings.sessionindex = session['saml_session_index']

      saml_remember_origin

      logout_request.create(settings)
    end

    def saml_remember_origin
      session['omniauth.origin'] = context[:controller].request.env['HTTP_REFERER']
    end

    def session
      @session ||= context[:controller].session
    end
  end
end
