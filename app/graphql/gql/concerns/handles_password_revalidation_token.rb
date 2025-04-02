# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesPasswordRevalidationToken
  extend ActiveSupport::Concern

  included do

    argument :token, String, description: 'Password revalidation token issued by the password check mutation.'

    def verify_token!(token_string)
      Token.validate! action: 'PasswordCheck', token: token_string, user: context.current_user
    rescue Token::TokenInvalid
      raise InvalidTokenError, __('The supplied password revalidation token is invalid.')
    end

  end

  # rubocop:disable GraphQL/ObjectDescription
  class InvalidTokenError < StandardError; end
  # rubocop:enable GraphQL/ObjectDescription

end
