# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserAgentTestBearerAuthController < UserAgentTestController
  before_action :authenticate

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      token == ENV['CI_BEARER_TOKEN']
    end
  end
end
