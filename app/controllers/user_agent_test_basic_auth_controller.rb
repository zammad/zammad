# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class UserAgentTestBasicAuthController < UserAgentTestController
  http_basic_authenticate_with name: ENV['CI_BASIC_AUTH_USER'], password: ENV['CI_BASIC_AUTH_PASSWORD']
end
