# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::VerifiesCsrfToken
  extend ActiveSupport::Concern

  def verify_csrf_token!
    return true if context[:is_graphql_introspection_generator]
    # Support :graphql type tests that don't use HTTP.
    return true if Rails.env.test? && !context[:controller]
    # Support developer workflows that need to turn off CSRF.
    return true if Rails.env.development? && context[:controller].request.headers['SkipAuthenticityTokenCheck'] == 'true'

    context[:controller].send(:verify_csrf_token) # verify_csrf_token is private :(
  end
end
