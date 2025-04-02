# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'omniauth/openid_connect'

# Monkey patch to support more different token endpoints. Can be removed when this PR is merged:
# https://github.com/omniauth/omniauth_openid_connect/pull/192
module OmniAuth
  module Strategies
    class OpenIDConnect
      def access_token
        return @access_token if @access_token

        token_request_params = {
          scope:              (options.scope if options.send_scope_to_token_endpoint),
          client_auth_method: options.client_auth_method,
        }

        token_request_params[:code_verifier] = params['code_verifier'] || session.delete('omniauth.pkce.verifier') if options.pkce

        if configured_response_type == 'code'
          token_request_params[:grant_type] = :authorization_code
          token_request_params[:code] = authorization_code
          token_request_params[:redirect_uri] = redirect_uri
          token_request_params[:client_id] = client_options.identifier
        end

        @access_token = client.access_token!(token_request_params)
        verify_id_token!(@access_token.id_token) if configured_response_type == 'code'

        @access_token
      end
    end
  end
end
