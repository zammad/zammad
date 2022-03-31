# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

#
# Throttle password reset requests
#
API_V1_USERS__PASSWORD_RESET_PATH = '/api/v1/users/password_reset'.freeze
Rack::Attack.throttle('limit password reset requests per username', limit: 3, period: 60) do |req|
  if req.path == API_V1_USERS__PASSWORD_RESET_PATH && req.post?
    # Normalize to protect against rate limit bypasses.
    req.params['username'].to_s.downcase.gsub(%r{\s+}, '')
  end
end
Rack::Attack.throttle('limit password reset requests per source IP address', limit: 3, period: 60) do |req|
  if req.path == API_V1_USERS__PASSWORD_RESET_PATH && req.post?
    req.ip
  end
end
