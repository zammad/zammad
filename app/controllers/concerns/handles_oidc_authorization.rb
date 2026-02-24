# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HandlesOidcAuthorization
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    skip_before_action :verify_csrf_token, only: %i[oidc_destroy oidc_bc_logout] # rubocop:disable Rails/LexicallyScopedActionFilter

    def oidc_bc_logout
      raise Exceptions::UnprocessableEntity, __("The required parameter 'oidc_database strategy' is not available.") if !OmniAuth::ProviderAvailability.available?('openid_connect')
      raise Exceptions::UnprocessableEntity, __("The required parameter 'logout_token' is missing.") if params[:logout_token].blank?

      begin
        decoded = oidc_strategy.decode_logout_token(params[:logout_token])
      rescue => e
        Rails.logger.error "OpenID Connect OP-initiated logout failed: #{e.message}"
        raise Exceptions::UnprocessableEntity, __("The 'logout_token' is invalid.")
      end

      raise Exceptions::UnprocessableEntity, __("The 'logout_token' does not contain any session information.") if decoded.sid.blank?

      Session.all.detect { |s| s.data['oidc_sid'] == decoded.sid }&.destroy
    end

    private

    def oidc_session?
      return false if !OmniAuth::ProviderAvailability.available?('openid_connect')

      session[:oidc_id_token].present? && oidc_end_session_endpoint.present?
    end

    # Guard: only reachable after oidc_session? has verified provider availability.
    def oidc_destroy
      logout_url = Addressable::URI.parse(oidc_end_session_endpoint)
      logout_url.query_values = {
        id_token_hint:            session[:oidc_id_token],
        post_logout_redirect_uri: "#{Setting.get('http_type')}://#{Setting.get('fqdn')}"
      }

      OmniAuth::Strategies::OidcDatabase.destroy_session(request.env, session)

      render json: { url: logout_url.to_s }
    rescue => e
      Rails.logger.error "OpenID Connect RP-initiated logout failed: #{e.message}"
    end

    def oidc_end_session_endpoint
      # Try client_options first (for manual configuration), fall back to discovery config
      @oidc_end_session_endpoint ||= oidc_strategy.options.client_options.end_session_endpoint || oidc_strategy.config.end_session_endpoint
    end

    def oidc_strategy
      @oidc_strategy ||= OmniAuth::Strategies::OidcDatabase.new(OmniAuth::Strategies::OidcDatabase.setup)
    end
  end
end
