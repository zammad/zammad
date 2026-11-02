# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OmniAuth::Strategies::LinkedInDatabase < OmniAuth::Strategies::LinkedIn
  include OmniAuth::Strategies::DatabaseSettings

  option :name, 'linkedin'

  def self.setup
    config = Setting.get('auth_linkedin_credentials') || {}

    {
      client_id:     config['app_id'],
      client_secret: config['app_secret'],
    }
  end

  # Workaround from current omniauth-linkedin gem issue:
  # https://github.com/decioferreira/omniauth-linkedin-oauth2/issues/68
  def token_params
    super.tap do |params|
      params.client_secret = options.client_secret
    end
  end
end
